#!/usr/bin/env bash

# ---------------------------------------------------------------------------- #
# Functions
# ---------------------------------------------------------------------------- #
Usage() {
   cat <<EOT
Usage:
    -n NFS Server
    -N NFS Path
    -v Vault Url
    -r /path/to/helm/charts
    -k keyvaultType
    -h Help
EOT
   exit 2
}

installChart() {
    local OPTIND # absolutely required

    local NAMESPACE=""
    local CHART_NAME=""
    local CHART_DIR=""
    local SET_ARGS=""
    local LABEL=""
    local PROFILE=""
    local UPGRADE=""
    local STATE='Ready'

    while getopts c:d:l:n:s:u:S: opt
    do
        case $opt in
            c) CHART_NAME="${OPTARG}";;
            d) CHART_DIR="${OPTARG}";;
            l) LABEL="${OPTARG}";;
            n) NAMESPACE="${OPTARG}";;
            s) SET_ARGS="${SET_ARGS} --set ${OPTARG}";;
            S) STATE="${OPTARG}";;
            u) UPGRADE=1;;
            *) echo "HUH $OPT";;
        esac
    done

    [ ! -f "${CHART_DIR}/values-${EVT}.yaml" ] && \
        echo "missing ${CHART_DIR}/values-${EVT}.yaml" && exit

    helm dependency update $CHART_DIR | grep -v "Successfully got an update" 
    helm install --create-namespace=true \
        -n $NAMESPACE $CHART_NAME \
        $CHART_DIR $SET_ARGS \
        -f ${CHART_DIR}/values-${EVT}.yaml \
        --wait

    if [ ! -z $LABEL ]; then
        sleep 5
        echo "Waiting for pods in $NAMESPACE to startup"
        kubectl wait -n $NAMESPACE pods \
            -l $LABEL \
            --for condition=${STATE} \
            --timeout=180s

        kubectl -n $NAMESPACE get pods
    fi

    if [ ! -z $UPGRADE ]; then
        sleep 5
        UP_ARGS=$(echo $SET_ARGS \
            | sed  's/schema.bootstrap=true/schema.bootstrap=false/')
        helm upgrade -n $NAMESPACE $CHART_NAME \
            $CHART_DIR $UP_ARGS \
            -f ${CHART_DIR}/values-${EVT}.yaml \
            --wait
    fi 
}

function createVaultTLS() {
    local WORKDIR=$(mktemp -d)
    mkdir -p "${WORKDIR}" || exit
    cd "${WORKDIR}" || exit

    local VAULT_LB_IP=$(dig +short "vault.${EVT}.${DOMAIN}" | \
        grep -v ${DOMAIN})
    local VAULT_UI_IP=$(dig +short "vault-ui.${EVT}.${DOMAIN}" | \
        grep -v ${DOMAIN})

    local SANS=""
    for domain in vault-system vault-system.svc vault-system.svc.cluster \
        vault-system.svc.cluster.local vault-internal
    do
        SANS="${SANS} --san *.${domain}"
    done

    SANS="${SANS} --san 127.0.0.1"

    [ ! -z "${VAULT_LB_IP}" ] && \
        SANS="${SANS} --san vault.${EVT}.${DOMAIN}" && \
        SANS="${SANS} --san ${VAULT_LB_IP}"

    [ ! -z "${VAULT_UI_IP}" ] && \
        SANS="${SANS} --san vault-ui.${EVT}.${DOMAIN}" && \
        SANS="${SANS} --san ${VAULT_UI_IP}"

    step ca certificate \
        --offline \
        ${SANS} \
        "--provisioner=${PROVISIONER}" \
        "--provisioner-password-file=${STEPDIR}/provisioner.password.txt" \
        "--password-file=${STEPDIR}/ca.password.txt" \
        "*.vault-system.svc.cluster.local" \
        vault.crt \
        vault.key

    cat ${INT_CRT} ${ROOT_CRT} > ca.chain.crt

    json_value=$(cat <<EOT
{
  "tls.crt": "$(cat vault.crt | awk '{printf "%s\\n", $0}')",
  "tls.key": "$(cat vault.key | awk '{printf "%s\\n", $0}')",
  "ca.chain.crt": "$(cat ca.chain.crt | awk '{printf "%s\\n", $0}')",
  "rootCA.crt": "$(cat $ROOT_CRT | awk '{printf "%s\\n", $0}')",
  "issuing_ca.crt": "$(cat $INT_CRT | awk '{printf "%s\\n", $0}')"
}
EOT
)

    if [ $KEYVAULT_TYPE == "azure" ]; then
        az keyvault secret set --vault-name "${KEY_VAULT_NAME}" \
            --name k8s-vault-system-vault-ha-tls --value "${json_value}"
    fi

    if [ $KEYVAULT_TYPE == "vault" ]; then
        vault kv put -address $EXTERNAL_VAULT_ADDR \
            kv/${EVT}/vault/tls \
            tls.crt=@vault.crt \
            tls.key=@vault.key \
            ca.chain.crt=@ca.chain.crt \
            rootCA.crt=@${ROOT_CRT} \
            issuing_ca.crt=@${INT_CRT}
    fi

    kubectl -n vault-system delete secret vault-tls
    kubectl -n vault-system create secret generic vault-tls \
        --from-file=tls.crt=vault.crt \
        --from-file=tls.key=vault.key \
        --from-file=ca.crt=ca.chain.crt

    cd -
    rm -rf "${WORKDIR}"
}

function initVault() {
    local WORKDIR=$(mktemp -d)
    mkdir -p "${WORKDIR}" || exit
    cd "${WORKDIR}" || exit

    sleep 5
    kubectl -n vault-system exec -it vault-0 \
        -- vault operator init -format=json > init.json

    ROOT_TOKEN=$(jq -r ".root_token" ${WORKDIR}/init.json)
    RECOVERY_KEYS=$(jq -r ".recovery_keys_b64" ${WORKDIR}/init.json)

    if [ $KEYVAULT_TYPE == "azure" ]; then
        az keyvault secret set --vault-name "${KEY_VAULT_NAME}" \
            --name k8s-vault-system-vault-root-token --value "${ROOT_TOKEN}"

        az keyvault secret set --vault-name "${KEY_VAULT_NAME}" \
            --name k8s-vault-system-vault-init-tokens \
            --value "$(cat ${WORKDIR}/init.json)"
    fi
    if [ $KEYVAULT_TYPE == "vault" ]; then
        vault kv put -address $EXTERNAL_VAULT_ADDR \
            kv/${EVT}/vault/init-tokens @${WORKDIR}/init.json
    fi

    kubectl -n vault-system exec -it vault-0 -- vault login $ROOT_TOKEN

    VAULT_PODS=$(kubectl -n vault-system get pods \
        -l app.kubernetes.io/name=vault \
        --no-headers -o custom-columns=":metadata.name" |
        grep -v vault-0 | grep -v vault-server-test)

    for POD in $VAULT_PODS
    do
        cat >${WORKDIR}/join-raft.sh <<EOF
vault operator raft join -address=https://${POD}.vault-internal:8200 \
        -leader-ca-cert="\$(cat /vault/userconfig/vault-tls/ca.crt)" \
        -leader-client-cert="\$(cat /vault/userconfig/vault-tls/tls.crt)" \
        -leader-client-key="\$(cat /vault/userconfig/vault-tls/tls.key)"\
        https://vault-0.vault-internal:8200
EOF
        echo "Copying configuration script to $POD..."
        kubectl -n vault-system cp ${WORKDIR}/join-raft.sh \
            ${POD}:/tmp/join-raft.sh

        # execute script
        echo "Executing configuration script on $POD..."
        kubectl exec -n vault-system -it ${POD} -- \
            /bin/sh /tmp/join-raft.sh

        # Clean up
        echo "Cleaning up configuration script on $POD..."
        kubectl -n vault-system exec ${POD} -- \
            rm -f /tmp/join-raft.sh
    done

    kubectl exec -n vault-system -it vault-0 -- \
        vault secrets enable -path=kv kv-v2

    kubectl exec -n vault-system -it vault-0 -- \
        vault auth enable kubernetes

    kubectl exec -ti vault-0 -n vault-system -c vault \
        -- vault write auth/kubernetes/config \
           kubernetes_host="https://kubernetes.default"

    cat > policy-snapshot.hc1 <<EOT
path "kv/*" {
  capabilities = ["create","update","read"]
}

path "auth/kubernetes/login" {
  capabilities = ["create","update","read"]
}
EOT

    kubectl -n vault-system cp policy-snapshot.hc1 vault-0:/tmp/policy-snapshot.hc1
    kubectl exec -ti vault-0 -n vault-system -c vault -- \
        vault policy write eso-role /tmp/policy-snapshot.hc1
    kubectl exec -ti vault-0 -n vault-system -c vault --rm /tmp/policy-snapshot.hc1 

    kubectl -n vault-system exec -it vault-0 -- \
        vault write auth/kubernetes/role/eso-role \
        bound_service_account_names=external-secrets \
        bound_service_account_namespaces="external-secrets,vault-system,argocd,cert-manager,kafka-system,istio-system,keda,keycloak,kube-system,vpa-system,grafana,prometheus,reloader" \
        ttl=86400 \
        policies=eso-role

    cd -
    rm -rf "${WORKDIR}"
}

function initVaultPKI() {
    local WORKDIR=$(mktemp -d)
    mkdir -p "${WORKDIR}" || exit
    cd "${WORKDIR}" || exit

    local UPPER_EVT=$(echo $EVT | tr '[:lower:]' '[:upper:]')
    kubectl -n vault-system exec -it vault-0 -- \
        vault secrets enable \
            -description="${UPPER_EVT} Intermediate CA (2025)" \
            -max-lease-ttl=87600h  \
            -default-lease-ttl=87600h pki

    kubectl -n vault-system exec -it vault-0 -- \
        vault write -format=json \
            pki/intermediate/generate/internal \
            common_name="${UPPER_EVT} Intermediate Authority" \
            ttl=43800h \
            | jq -r '.data.csr' > ${WORKDIR}/${EVT}_intermediate_CA.csr

    step certificate sign \
        --not-after 43800h \
        --profile intermediate-ca \
        --path-len 1 \
        --password-file=${STEPDIR}/ca.password.txt \
        ${EVT}_intermediate_CA.csr \
        ${STEPPATH}/certs/root_ca.crt \
        ${STEPPATH}/secrets/root_ca_key \
        > signed.${EVT}.intermediate.CA.crt

    cat ${STEPPATH}/certs/root_ca.crt >> signed.${EVT}.intermediate.CA.crt

    ISSURER="https://vault-active.vault-system.svc.cluster.local:8200"

    kubectl -n vault-system exec -it vault-0 -- \
        vault write pki/config/urls \
            issuing_certificates="${ISSURER}/v1/pki/ca" \
            crl_distribution_points="${ISSURER}/v1/pki/crl"

    kubectl -n vault-system cp signed.${EVT}.intermediate.CA.crt \
        vault-0:/tmp/signed_inter.crt

    kubectl -n vault-system exec -it vault-0 -- \
        vault write pki/intermediate/set-signed \
            certificate=@/tmp/signed_inter.crt

    kubectl -n vault-system exec -it vault-0 -- rm /tmp/signed_inter.crt

    kubectl -n vault-system exec -it vault-0 -- \
        vault write pki/roles/generate-cert-role \
            allow_wildcard_certificates=true \
            allow_localhost=true \
            allow_any_name=true \
            allow_subdomains=true \
            max_ttl=21600h \
            key_usage="DigitalSignature,KeyEncipherment" \
            ext_key_usage="" \
            client_flag=false \
            ext_key_usage_oids=1.3.6.1.5.5.7.3.1 \
            server_flag=true
            #key_type=any \

    # policy
    cat > policy.hc1 <<EOF
path "pki*"                         { capabilities = ["read", "list"] }
path "pki/sign/generate-cert-role"  { capabilities = ["create", "update"] }
path "pki/issue/generate-cert-role" { capabilities = ["create"] }
EOF

    kubectl -n vault-system exec -it vault-0 -- \
        vault secrets enable pki

    kubectl -n vault-system cp policy.hc1 vault-0:/tmp/pki.policy.hc1

    kubectl -n vault-system exec -it vault-0 \
        -- vault policy write pki /tmp/pki.policy.hc1

    kubectl -n vault-system exec -it vault-0 -- rm /tmp/pki.policy.hc1

    local CA_NS="cert-manager,minio-operator,minio-tenant"
    kubectl -n vault-system exec -it vault-0 -- \
        vault write auth/kubernetes/role/vault-cert-issuer \
        policies=pki \
        key_type=any \
        ttl=30m \
        bound_service_account_names=vault-cert-issuer \
        bound_service_account_namespaces=${CA_NS}

    # metrics policy
    cat > ${WORKDIR}/prometheus-metrics.hc1 <<EOF
path "/sys/metrics" {
  capabilities = ["read"]
}
EOF

    kubectl -n vault-system cp  ${WORKDIR}/prometheus-metrics.hc1 \
        vault-0:/tmp/metrics.policy.hc1

    kubectl -n vault-system exec -it vault-0 -- \
        vault policy write prometheus-metrics /tmp/metrics.policy.hc1

    cd -
    rm -rf "${WORKDIR}"
}

function createVaultCertFromPki() {
    local WORKDIR=$(mktemp -d)
    mkdir -p "${WORKDIR}" || exit
    cd "${WORKDIR}" || exit

    local VAULT_LB_IP=$(dig +short "vault.${EVT}.${DOMAIN}")

    local SANS="vault.${EVT}.${DOMAIN}"
    for domain in vault-system vault-system.svc vault-system.svc.cluster \
        vault-system.svc.cluster.local vault-internal
    do
        SANS="${SANS},*.${domain}"
    done

    IP_SANS="127.0.0.1"

    [ ! -z ${VAULT_LB_IP} ] && IP_SANS="${IP_SANS},${VAULT_LB_IP}"

    kubectl -n vault-system exec -it vault-0 -- \
        vault write -format=json \
            pki/issue/generate-cert-role \
            common_name="*.vault-system.svc.cluster.local" \
            alt_names=${SANS} \
            ip_sans=${IP_SANS} \
            ttl=730d \
            | jq .data -r > new.vault.tls

    jq -r '.private_key' new.vault.tls > tls.key
    jq -r '.certificate' new.vault.tls > tls.crt
    jq -r '.ca_chain[]' new.vault.tls > ca.chain.crt
    jq -r '.issuing_ca' new.vault.tls > vault.ca.crt

    # make tls.crt full chain
    cat ca.chain.crt >> tls.crt

    json_value=$(cat <<EOT
{
  "tls.crt": "$(cat tls.crt | awk '{printf "%s\\n", $0}')",
  "tls.key": "$(cat tls.key | awk '{printf "%s\\n", $0}')",
  "ca.chain.crt": "$(cat ca.chain.crt | awk '{printf "%s\\n", $0}')",
  "rootCA.crt": "$(cat $ROOT_CRT | awk '{printf "%s\\n", $0}')",
  "issuing_ca.crt": "$(cat vault.ca.crt | awk '{printf "%s\\n", $0}')"
}
EOT
)
    if [ $KEYVAULT_TYPE == "azure" ]; then
        az keyvault secret set --vault-name "${KEY_VAULT_NAME}" \
            --name k8s-vault-system-vault-ha-tls --value "${json_value}"
    fi
    if [ $KEYVAULT_TYPE == "vault" ]; then
        vault kv put -address $EXTERNAL_VAULT_ADDR \
            kv/${EVT}/vault/tls \
            tls.crt=@tls.crt \
            tls.key=@tls.key \
            ca.chain.crt=@ca.chain.crt \
            rootCA.crt=@${ROOT_CRT}
    fi

    kubectl -n vault-system annotate es \
        vault-ha-tls force-sync=$(date +%s) --overwrite

    kubectl -n vault-system delete po vault-{0,1,2}

    cd -
    rm -rf "${WORKDIR}"
}

function createKafkaCA() {
    local WORKDIR=$(mktemp -d)
    mkdir -p "${WORKDIR}" || exit
    cd "${WORKDIR}" || exit

    CLUSTER_PASS=$(openssl rand -base64 16)
    CLIENT_PASS=$(openssl rand -base64 16)

    step certificate create \
        "Kafka ${EVT} Cluster Intermediate CA (2025)" \
        --csr \
        --no-password \
        --insecure \
        --kty RSA \
        kafka-cluster-ca.csr \
        kafka-cluster-ca.key

    step certificate sign \
        --profile intermediate-ca \
        --password-file ${STEPDIR}/ca.password.txt \
        --not-after 87660h \
        kafka-cluster-ca.csr  \
        ${STEPPATH}/certs/root_ca.crt  \
        ${STEPPATH}/secrets/root_ca_key \
        > kafka-cluster-ca.crt

    step certificate create \
       "Kafka ${EVT} Client Intermediate CA (2025)" \
        --csr \
        --no-password \
        --insecure \
        --kty RSA \
        kafka-client-ca.csr \
        kafka-client-ca.key

    step certificate sign \
        --profile intermediate-ca \
        --password-file ${STEPDIR}/ca.password.txt \
        --not-after 87660h kafka-client-ca.csr  \
        ${STEPPATH}/certs/root_ca.crt  \
        ${STEPPATH}/secrets/root_ca_key \
        > kafka-client-ca.crt

    openssl pkcs12 -export -in kafka-client-ca.crt \
        -nokeys -out kafka-client-ca.p12 \
        -password pass:${CLIENT_PASS} \
        -caname "Kafka ${EVT} Client Intermediate CA (2025)"

    openssl pkcs12 -export -in kafka-cluster-ca.crt \
        -nokeys -out kafka-cluster-ca.p12 \
        -password pass:${CLUSTER_PASS} \
        -caname "Kafka ${EVT} Cluster Intermediate CA (2025)"                       
    cat ${STEPPATH}/certs/root_ca.crt >> kafka-cluster-ca.crt
    json_value=$(cat <<EOF
{
  "ca.crt": "$(awk '{printf "%s\\n", $0}' kafka-cluster-ca.crt)",
  "ca.key": "$(awk '{printf "%s\\n", $0}' kafka-cluster-ca.key)",
  "ca.password": "${CLUSTER_PASS}",
  "ca.p12": "$(base64 -w 0 kafka-cluster-ca.p12)"
}
EOF
)
    if [ $KEYVAULT_TYPE == "azure" ]; then
        az keyvault secret set --vault-name "${KEY_VAULT_NAME}" \
            --name k8s-kafka-system-cluster-ca --value "${json_value}"
    fi
    if [ $KEYVAULT_TYPE == "vault" ]; then
        vault kv put -address $EXTERNAL_VAULT_ADDR \
            kv/${EVT}/kafka/cluster/ca \
            ca.crt=@kafka-cluster-ca.crt \
            ca.key=@kafka-cluster-ca.key \
            ca.password=${CLUSTER_PASS} \
            ca.p12="$(base64 -w 0 kafka-cluster-ca.p12)"
    fi

    cat ${STEPPATH}/certs/root_ca.crt >> kafka-client-ca.crt

    json_value=$(cat <<EOF
{
  "ca.crt": "$(awk '{printf "%s\\n", $0}' kafka-client-ca.crt)",
  "ca.key": "$(awk '{printf "%s\\n", $0}' kafka-client-ca.key)",
  "ca.password": "${CLIENT_PASS}",
  "ca.p12": "$(base64 -w 0 kafka-client-ca.p12)"
}
EOF
)
    if [ $KEYVAULT_TYPE == "azure" ]; then
        az keyvault secret set --vault-name "${KEY_VAULT_NAME}" \
            --name k8s-kafka-system-client-ca --value "${json_value}"
    fi
    if [ $KEYVAULT_TYPE == "vault" ]; then
        vault kv put -address $EXTERNAL_VAULT_ADDR \
            kv/${EVT}/kafka/client/ca \
            ca.crt=@kafka-client-ca.crt \
            ca.key=@kafka-client-ca.key \
            ca.password="${CLIENT_PASS}" \
            ca.p12="$(base64 -w 0 kafka-client-ca.p12)"
    fi

    cd -
    rm -rf "${WORKDIR}"
}
[ -f ~/.external_hvault ] && source ~/.external_hvault

# ---------------------------------------------------------------------------- #
# Defaults
# ---------------------------------------------------------------------------- #
NFS_SERVER="192.168.0.3"
NFS_PATH="/data/nfs"
VAULT_URL="https://192.168.0.4:8443"
EVT="k3s"
REPO_DIR="/tmp/gitops"
CHARTS_REPO_BASE=${REPO_DIR}/helm/charts
KEYVAULT_TYPE="azure"
DOMAIN="where-ever.net"

# ---------------------------------------------------------------------------- #
# Process Args
# ---------------------------------------------------------------------------- #
while getopts n:N:v:r:k:h opt
do
    case $opt in
        n) NFS_SERVER="${OPTARG}";;
        N) NFS_PATH="${OPTARG}";;
        v) VAULT_URL="${OPTARG}";;
        r) REPO_DIR="${OPTARG}";;
        k) KEYVAULT_TYPE="${OPTARG}";;
        h) Usage;;
        *) Usage;;
    esac
done

export STEPDIR=/usr/local/etc/step-ca
export STEPPATH=${STEPDIR}/ca

PROVISIONER="vikashb@where-ever.za.net"
INT_CRT=/usr/local/etc/step-ca/ca/certs/intermediate_ca.crt
ROOT_CRT=/usr/local/etc/step-ca/ca/certs/root_ca.crt


[ -z $EVT ] && Usage
[ -z "${REPO_DIR}" ] && echo "Missing path to charts repo" \
    && usage && exit 2

[ -z "${STEPPATH}" ] && echo "Missing step-ca, cannot proceed" && exit 2

cd "${REPO_DIR}" || (echo "Chould not switch to ${REPO_DIR}" && exit 2)

export NFS_SERVER
export NFS_PATH
export EXTERNAL_VAULT
export EVT

CHARTS_REPO_BASE=$REPO_DIR

# ----------------------------------------------------------------------- #
# gateway api crds
# ----------------------------------------------------------------------- #
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml

# ---------------------------------------------------------------------------- #
# Login to External Vault
# PROVIDES: Secrets for Azure Service Principle
# ---------------------------------------------------------------------------- #
# log in to external vault and renew token
vault login -address $EXTERNAL_VAULT_ADDR $ROOT_TOKEN  
#vault token renew -address $EXTERNAL_VAULT_ADDR $ESO_TOKEN 

# ---------------------------------------------------------------------------- #
# Get Azure Credentials
# PROVIDES: vault unseal token
# ---------------------------------------------------------------------------- #
# get azure cred
vault kv get -address $EXTERNAL_VAULT_ADDR -format json \
    kv/azure/akv-credentials > /tmp/az.creds.json

AZURE_CLIENT_ID=$(jq -r '.data.data.AZURE_CLIENT_ID' /tmp/az.creds.json)
AZURE_CLIENT_SECRET=$(jq -r '.data.data.AZURE_CLIENT_SECRET' /tmp/az.creds.json)
AZURE_TENANT_ID=$(jq -r '.data.data.AZURE_TENANT_ID' /tmp/az.creds.json)
SUBSCRIPTION_ID=$(jq -r '.data.data.SUBSCRIPTION_ID' /tmp/az.creds.json)
VAULT_AZUREKEYVAULT_KEY_NAME=$(jq -r \
    '.data.data.VAULT_AZUREKEYVAULT_KEY_NAME' /tmp/az.creds.json)
VAULT_AZUREKEYVAULT_VAULT_NAME=$(jq -r \
    '.data.data.VAULT_AZUREKEYVAULT_VAULT_NAME' /tmp/az.creds.json)

rm /tmp/az.creds.json

# ---------------------------------------------------------------------------- #
# Hashicorp Vault
# ---------------------------------------------------------------------------- #
kubectl get ns vault-system
if [ $? -ne 0 ]; then
    kubectl create ns vault-system
fi

kubectl -n vault-system get secret hvault-config
if [ $? -ne 0 ]; then
    KEYNAME=$(vault kv get -address $EXTERNAL_VAULT_ADDR \
        -format json kv/${EVT}/vault/akv-unseal-key | \
        jq -r .data.data.VAULT_AZUREKEYVAULT_KEY_NAME)
    kubectl -n vault-system create secret generic hvault-config \
        --from-literal=AZURE_CLIENT_ID="${AZURE_CLIENT_ID}" \
        --from-literal=AZURE_CLIENT_SECRET="${AZURE_CLIENT_SECRET}" \
        --from-literal=AZURE_TENANT_ID="${AZURE_TENANT_ID}" \
        --from-literal=SUBSCRIPTION_ID="${SUBSCRIPTION_ID}" \
        --from-literal=VAULT_AZUREKEYVAULT_VAULT_NAME="${VAULT_AZUREKEYVAULT_VAULT_NAME}" \
        --from-literal=VAULT_AZUREKEYVAULT_KEY_NAME="${KEYNAME}"
fi

kubectl -n vault-system get secret vault-tls
if [ $? -ne 0 ]; then
    createVaultTLS
fi

INSTALLED=$(kubectl -n vault-system get pods \
    -l "app.kubernetes.io/instance=vault" -o name | wc -l)
if [ "${INSTALLED}" -eq "0" ]; then
    installChart -d "${CHARTS_REPO_BASE}/hashicorp-vault" \
        -c vault \
        -n vault-system \
        -l "app.kubernetes.io/instance=vault" \
        -s schema.bootstrap=true \
        -s schema.skipCM=true \
        -s vault.global.serverTelemetry.prometheusOperator=false \
        -s vault.injector.metrics.enabled=false \
        -s vault.serverTelemetry.serviceMonitor.enabled=false \
        -s vault.serverTelemetry.prometheusRules.enabled=false \
        -S PodReadyToStartContainers
fi

VAULT_STATUS=$(kubectl -n vault-system exec -it vault-0 -- vault status \
    | tr -s ' ' \
    | grep -E '^Initialized true|^Sealed false' \
    | wc -l)

if [ "${VAULT_STATUS}" -ne 2 ]; then
    # Init
    initVault
    kubectl -n vault-system cp ${ROOT_CRT} \
        vault-0:/tmp/root_ca.crt
    kubectl -n vault-system exec -it vault-0 -- \
        vault kv put kv/infrastructure/offline-root-ca \
           rootCA.crt=@/tmp/root_ca.crt
fi

kubectl -n vault-system exec -it vault-0 -- \
    vault pki list-intermediates /pki/issuer/default
if [ $? -ne 0 ]; then
    # Init PKI
    initVaultPKI
fi

# ---------------------------------------------------------------------------- #
# cert-manager
# REQUIRES: ServiceMonitor
# PROVIDES: tls cert management
# ---------------------------------------------------------------------------- #
kubectl get ns cert-manager
if [ $? -ne 0 ]; then
    kubectl create ns cert-manager
fi

kubectl -n cert-manager get secret offline-root-ca
if [ $? -ne 0 ]; then
    # Will be managed by ES, this is to get the cluster up
    kubectl -n cert-manager create secret generic offline-root-ca \
        --from-file=rootCA.crt=${ROOT_CRT}
fi

INSTALLED=$(kubectl -n cert-manager get pods \
    -l "app.kubernetes.io/instance=cert-manager" -o name | wc -l)

if [ "${INSTALLED}" -eq "0" ]; then
    installChart -d "${CHARTS_REPO_BASE}/cert-manager" \
        -c cert-manager \
        -n cert-manager \
        -s schema.bootstrap=true \
        -s schema.caBundle=false \
        -s schema.skipES=true \
        -s cert-manager.prometheus.servicemonitor.enabled=false \
        -s trust-manager.enabled=false \
        -l "app.kubernetes.io/instance=cert-manager" \
        -u true

    # Install trust-manager
    helm upgrade -i -n cert-manager cert-manager \
        "${CHARTS_REPO_BASE}/cert-manager" \
        --set schema.bootstrap=false \
        --set schema.caBundle=false \
        --set schema.skipES=true \
        --set cert-manager.prometheus.servicemonitor.enabled=false \
        -f "${CHARTS_REPO_BASE}/cert-manager/values-${EVT}.yaml" --wait

    # Install own-ca-bundle
    helm upgrade -i -n cert-manager cert-manager \
        "${CHARTS_REPO_BASE}/cert-manager" \
        --set cert-manager.prometheus.servicemonitor.enabled=false \
        --set schema.skipES=true \
        -f "${REPO_DIR}/cert-manager/values-${EVT}.yaml" --wait

fi

# check clusterissuer status
kubectl get clusterissuers.cert-manager.io 

# ---------------------------------------------------------------------------- #
# Hashicorp vault with cert from cert-manager
# ---------------------------------------------------------------------------- #
kubectl -n vault-system get secret  vault-tls | grep 'kubernetes.io/tls'
if [ $? -ne 0 ]; then
    # Delete old secret
    kubectl -n vault-system delete secret vault-tls
    # Use cert-manager to generate vault cert
    helm upgrade -i -n vault-system vault \
    "${CHARTS_REPO_BASE}/hashicorp-vault" \
    --set vault.global.serverTelemetry.prometheusOperator=false \
    --set vault.injector.metrics.enabled=false \
    --set vault.serverTelemetry.serviceMonitor.enabled=false \
    --set vault.serverTelemetry.prometheusRules.enabled=false \
    --set schema.bootstrap=true \
    -f "${REPO_DIR}/hashicorp-vault/values-${EVT}.yaml" --wait

    kubectl -n vault-system delete po vault-{0,1,2}

    sleep 10
fi

# ---------------------------------------------------------------------------- #
# External Secrets
# PROVIDES: Secret Stores (azure key vault, external hashicorp-vault)
# ---------------------------------------------------------------------------- #
[ ! -d "${REPO_DIR}/external-secrets" ] && \
    ( echo "missing external-secrets chart" && exit 2 )

INSTALLED=$(kubectl -n external-secrets get pods \
    -l "app.kubernetes.io/instance=external-secrets" -o name | wc -l)

if [ "${INSTALLED}" -eq "0" ]; then
    kubectl create ns external-secrets
    kubectl -n external-secrets create secret generic \
        azure-eso-config \
        --from-literal=clientId="${AZURE_CLIENT_ID}" \
        --from-literal=clientSecret="${AZURE_CLIENT_SECRET}" \
        --from-literal=tenantId="${AZURE_TENANT_ID}" \
        --from-literal=vaultUrl="${VAULT_AZUREKEYVAULT_VAULT_NAME}"
    
    kubectl -n external-secrets get secret offline-root-ca
    if [ $? -ne 0 ]; then
        kubectl -n external-secrets create secret generic offline-root-ca \
            --from-file=rootCA.crt=${ROOT_CRT}
    fi

    installChart -d "${CHARTS_REPO_BASE}/external-secrets" \
        -c external-secrets \
        -n external-secrets \
        -s schema.bootstrap=true \
        -s external-secrets.serviceMonitor.enabled=false \
        -s external-secrets.webhook.certManager.enabled=false \
        -l "app.kubernetes.io/instance=external-secrets" \
        -u true
fi
# ---------------------------------------------------------------------------- #
# argocd
# ---------------------------------------------------------------------------- #
# get argocd admin password
vault kv get -address $EXTERNAL_VAULT_ADDR -format json \
    kv/${EVT}/argocd/admin-password
if [ $? -ne 0 ]; then
   PASS=$(openssl rand 16 | sha512sum | base64 -w 0 | head -c 24)
   BCRYPT=$(argocd account bcrypt --password $PASS)
   vault kv put -address $EXTERNAL_VAULT_ADDR \
      kv/${EVT}/argocd/admin-password bcrypt=${BCRYPT} password=${PASS}
fi

vault kv get -address $EXTERNAL_VAULT_ADDR -format json \
    kv/${EVT}/argocd/redis

if [ $? -ne 0 ]; then
    vault kv put -address $EXTERNAL_VAULT_ADDR \
        kv/${EVT}/argocd/redis auth="$(openssl rand -base64 16)"
fi

vault kv get -address $EXTERNAL_VAULT_ADDR -format json \
    kv/${EVT}/argocd/authentik-client

if [ $? -ne 0 ]; then
    vault kv put -address $EXTERNAL_VAULT_ADDR \
        kv/${EVT}/argocd/authentik-client \
        id="$(openssl rand 256 | sha512sum | base64 -w 0 | head -c 40)" \
        secret="$(openssl rand 256 | sha512sum | base64 -w 0 | head -c 128)"
fi

ARGOPASS=$(vault kv get -address $EXTERNAL_VAULT_ADDR -format json \
    kv/${EVT}/argocd/admin-password \
    | jq -r '.data.data.bcrypt')

installChart -d "${CHARTS_REPO_BASE}/argocd" \
    -c argocd \
    -n argocd \
    -s schema.bootstrap=true \
    -s argo-cd.configs.secret.argocdServerAdminPassword=${ARGOPASS} \
    -l "app.kubernetes.io/instance=argocd" \
    -u true
 
# ---------------------------------------------------------------------------- #
# Set passwords
# ---------------------------------------------------------------------------- #
vault kv get -address $EXTERNAL_VAULT_ADDR -format json \
    kv/${EVT}/authentik/secrets

if [ $? -ne 0 ]; then
    vault kv put -address $EXTERNAL_VAULT_ADDR kv/${EVT}/authentik/secrets \
      AUTHENTIK_BOOTSTRAP_PASSWORD="$(openssl rand 64 | sha512sum | base64 -w 0 | head -c 32)" \
      AUTHENTIK_BOOTSTRAP_TOKEN="$(openssl rand 64 | sha512sum | base64 -w 0 | head -c 32)" \
      AUTHENTIK_EMAIL__FROM="authentik@${EVT}.where-ever.net" \
      AUTHENTIK_EMAIL__HOST="mailhog.dev-tools.svc.cluster.local" \
      AUTHENTIK_EMAIL__PASSWORD="" \
      AUTHENTIK_EMAIL__PORT="1025" \
      AUTHENTIK_EMAIL__USERNAME="vikashb@${EVT}.where-ever.net" \
      AUTHENTIK_EMAIL__USE_SSL="false" \
      AUTHENTIK_EMAIL__USE_TLS="false" \
      AUTHENTIK_POSTGRESQL__ADMIN_PASSWORD="$(openssl rand -base64 16)" \
      AUTHENTIK_POSTGRESQL__PASSWORD="$(openssl rand -base64 16)" \
      AUTHENTIK_REDIS__PASSWORD="$(openssl rand -base64 16)" \
      AUTHENTIK_SECRET_KEY="$(openssl rand -base64 32)"
fi

vault kv get -address $EXTERNAL_VAULT_ADDR -format json \
    kv/${EVT}/grafana/admin

if [ $? -ne 0 ]; then
    vault kv put -address $EXTERNAL_VAULT_ADDR kv/${EVT}/grafana/admin \
    GF_SECURITY_ADMIN_PASSWORD="$(openssl rand 64 | sha512sum | base64 -w 0 | head -c 24)" \
    GF_SECURITY_ADMIN_USER="admin"
fi

vault kv get -address $EXTERNAL_VAULT_ADDR -format json \
    kv/${EVT}/grafana/authentik-client

if [ $? -ne 0 ]; then
    vault kv put -address $EXTERNAL_VAULT_ADDR  \
        kv/${EVT}/grafana/authentik-client \
        id="$(openssl rand 256 | sha512sum | base64 -w 0 | head -c 40)" \
        secret="$(openssl rand 256 | sha512sum | base64 -w 0 | head -c 128)"
fi

vault kv get -address $EXTERNAL_VAULT_ADDR -format json \
    kv/${EVT}/grafana/smtp

if [ $? -ne 0 ]; then
    vault kv put -address $EXTERNAL_VAULT_ADDR kv/${EVT}/grafana/smtp \
      GF_SMTP_ENABLED="true" \
      GF_SMTP_FROM_ADDRESS="monitor@${EVT}.where-ever.net" \
      GF_SMTP_HOST="desktop.home.where-ever.za.net:587" \
      GF_SMTP_PASSWORD="$(openssl rand -base64 32)" \
      GF_SMTP_STARTTLS_POLICY="MandatoryStartTLS" \
      GF_SMTP_USER="vmail"
fi

vault kv get -address $EXTERNAL_VAULT_ADDR -format json \
    kv/${EVT}/kafka-ui/authentik-client

if [ $? -ne 0 ]; then
    vault kv put -address $EXTERNAL_VAULT_ADDR \
        kv/${EVT}/kafka-ui/authentik-client \
        id="$(openssl rand 256 | sha512sum | base64 -w 0 | head -c 40)" \
        secret="$(openssl rand 256 | sha512sum | base64 -w 0 | head -c 128)"
fi

vault kv get -address $EXTERNAL_VAULT_ADDR -format json \
    kv/${EVT}/minio/admin-credentials

if [ $? -ne 0 ]; then
    vault kv put -address $EXTERNAL_VAULT_ADDR \
        kv/${EVT}/minio/admin-credentials \
        rootPassword="$(openssl rand -base64 24)" \
        rootUser="minio-admin"
fi

vault kv get -address $EXTERNAL_VAULT_ADDR -format json \
    kv/${EVT}/loki/minio-credentials-incluster

if [ $? -ne 0 ]; then
    vault kv put -address $EXTERNAL_VAULT_ADDR \
    kv/${EVT}/loki/minio-credentials-incluster \
    accessKey="loki" \
    endpoint="https://${EVT}-hl.minio-tenant:9000/" \
    secretKey="$(openssl rand -base64 24)"
fi

vault kv get -address $EXTERNAL_VAULT_ADDR -format json \
    kv/${EVT}/tempo/minio-credentials-incluster

if [ $? -ne 0 ]; then
    vault kv put -address $EXTERNAL_VAULT_ADDR \
    kv/${EVT}/tempo/minio-credentials-incluster \
    accessKey="tempo" \
    endpoint="${EVT}-hl.minio-tenant:9000" \
    secretKey="$(openssl rand -base64 24)"
fi

vault kv get -address $EXTERNAL_VAULT_ADDR -format json \
    kv/${EVT}/kafka/cluster/ca

if [ $? -ne 0 ]; then
    createKafkaCA
fi

vault kv get -address $EXTERNAL_VAULT_ADDR -format json \
    kv/${EVT}/redis/password

if [ $? -ne 0 ]; then
    vault kv put -address $EXTERNAL_VAULT_ADDR kv/${EVT}/redis/password \
      password="$(openssl rand -base64 16)"
fi

vault kv get -address $EXTERNAL_VAULT_ADDR -format json \
    kv/${EVT}/valkey/password

if [ $? -ne 0 ]; then
    vault kv put -address $EXTERNAL_VAULT_ADDR kv/${EVT}/valkey/password \
      password="$(openssl rand -base64 16)"
fi
 
# ----------------------------------------------------------------------- #
# Install umbrella charts
# ----------------------------------------------------------------------- #
for app in in-cluster-storage monitoring apps networking dev-tools \
           infrastructure
do
    helm template ${CHARTS_REPO_BASE}/umbrella/${EVT} \
        -f ${CHARTS_REPO_BASE}/umbrella/${EVT}/values-${app}.yaml \
        | kubectl -n argocd apply -f -
        sleep 10
done

#vix kubectl -n monitoring exec -it  $(kubectl -n monitoring get pods \
#vix     | grep grafana | awk '{ print $1 }') -- \
#vix     grafana cli  admin reset-admin-password $GRAFANAPASS
#vix 
#vix 
#vix kubectl -n minio-tenant get secrets ${EVT}-minio-tenant-tls \
#vix     -o=jsonpath='{.data.ca\.crt}' \
