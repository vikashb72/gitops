#!/usr/bin/env bash

# ---------------------------------------------------------------------------- #
# Functions
# ---------------------------------------------------------------------------- #
Usage() {
   cat <<EOT
Usage:
    -e Environment (dev|uat|prod|minikube|k3s|k8s)
    -n NFS Server
    -N NFS Path
    -v Vault Url
    -c cpus (default 2)
    -m memory (default 2200MB)
    -w Node (default 1)
    -h Help
EOT
   exit 2
}

installChart() {
    local OPTIND # absolutely required

    NAMESPACE=""
    CHART_NAME=""
    CHART_DIR=""
    SET_ARGS=""
    LABEL=""
    PROFILE=""
    UPGRADE=""
    STATE='Ready'

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

    helm dependency update $CHART_DIR | grep -v "Successfully got an update" 
    helm install --create-namespace=true \
        -n $NAMESPACE $CHART_NAME \
        $CHART_DIR $SET_ARGS \
        -f ${CHART_DIR}/values-${EVT}.yaml \
        --wait

    if [ ! -z $LABEL ]; then
        echo "Waiting for pods in $NAMESPACE to startup"
        kubectl wait -n $NAMESPACE pods \
            -l $LABEL \
            --for condition=${STATE} \
            --timeout=180s

        kubectl -n $NAMESPACE get pods
    fi

    if [ ! -z $UPGRADE ]; then
        UP_ARGS=$(echo $SET_ARGS \
            | sed  's/schema.bootstrap=true/schema.bootstrap=false/')
        helm upgrade -n $NAMESPACE $CHART_NAME \
        $CHART_DIR $UP_ARGS \
        -f ${CHART_DIR}/values-${EVT}.yaml \
        --wait
    fi 
}

[ -f ~/.external_hvault ] && source ~/.external_hvault

# ---------------------------------------------------------------------------- #
# Defaults
# ---------------------------------------------------------------------------- #
NFS_SERVER="192.168.0.3"
NFS_PATH="/data/nfs"
VAULT_URL="https://192.168.0.4:8443"
CPU=2
MEM="2200MB"
NODES=1
EVT=""
REPO_DIR="/tmp/gitops"
CHARTS_REPO_BASE=${REPO_DIR}/helm/charts

# ---------------------------------------------------------------------------- #
# Process Args
# ---------------------------------------------------------------------------- #
while getopts c:e:m:n:N:v:w:h opt
do
    case $opt in
        c) CPU="${OPTARG}";;
        e) EVT="${OPTARG}";;
        m) MEM="${OPTARG}";;
        n) NFS_SERVER="${OPTARG}";;
        N) NFS_PATH="${OPTARG}";;
        v) VAULT_URL="${OPTARG}";;
        w) NODES="${OPTARG}";;
        h) Usage;;
        *) Usage;;
    esac
done

[ -z $EVT ] && Usage

export NFS_SERVER
export NFS_PATH
export EXTERNAL_VAULT
export EVT

# ---------------------------------------------------------------------------- #
# Set up minikube
# ---------------------------------------------------------------------------- #
minikube stop --profile="${EVT}"
minikube delete --profile="${EVT}"
minikube start \
    --profile="${EVT}" \
    --memory="${MEM}" \
    --cpus="${CPU}" \
    --cni=flannel \
    --driver=docker \
    --container-runtime=containerd \
    --insecure-registry "192.168.0.0/24" \
    --nodes=${NODES} \
    --addons=metrics-server \
    --addons=metallb \
    --wait=all

export MINIKUBE_IP=$(minikube --profile $EVT ip)

# ---------------------------------------------------------------------------- #
# Metallb
# PROVIDES: loadbalancer
# ---------------------------------------------------------------------------- #
cat <<EOT
Start IP: ${MINIKUBE_IP}24
End IP: ${MINIKUBE_IP}54
EOT
minikube addons configure metallb

# ---------------------------------------------------------------------------- #
# Clone Charts repo
# ---------------------------------------------------------------------------- #
rm -rf $REPO_DIR
git clone git@github.com:vikashb72/gitops.git $REPO_DIR

# ---------------------------------------------------------------------------- #
# nfs-subdir-external-provisioner
# PROVIDES: storage
# ---------------------------------------------------------------------------- #

installChart -d "${CHARTS_REPO_BASE}/nfs-subdir-external-provisioner" \
    -c nfs-subdir-external-provisioner \
    -n nfs-provisioning \
    -l "app=nfs-subdir-external-provisioner"

# Disable host path storage
kubectl patch storageclass standard \
    -p '{"metadata": 
    {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

# ---------------------------------------------------------------------------- #
# Promethues
# REQUIRES: nfs storage
# PROVIDES: PodMonitor, ServiceMonitor
# ---------------------------------------------------------------------------- #
installChart -d "${CHARTS_REPO_BASE}/kube-prometheus-stack" \
    -c kube-prometheus-stack \
    -n monitoring \
    -l "app.kubernetes.io/instance=kube-prometheus-stack" \
    -s schema.bootstrap=true \
    -s kube-prometheus-stack.crds.enabled=true \
    -s kube-prometheus-stack.defaultRules.create=false \
    -s kube-prometheus-stack.alertmanager.enabled=false \
    -s kube-prometheus-stack.grafana.enabled=false \
    -s kube-prometheus-stack.prometheus.enabled=false \
    -s kube-prometheus-stack.kubernetesServiceMonitors.enabled=false 

# ---------------------------------------------------------------------------- #
# Login to External Vault
# PROVIDES: Secrets for Azure Service Principle
# ---------------------------------------------------------------------------- #
# log in to external vault and renew token
vault login -address $EXTERNAL_VAULT_ADDR $ESO_TOKEN  
vault token renew -address $EXTERNAL_VAULT_ADDR $ESO_TOKEN 

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
# External Secrets
# Requires: ServiceMonitor
# PROVIDES: Secret Stores (azure key vault, external hashicorp-vault)
# ---------------------------------------------------------------------------- #
kubectl create ns external-secrets
kubectl -n external-secrets delete secret azure-eso-config
kubectl -n external-secrets create secret generic \
    azure-eso-config \
    --from-literal=clientId="${AZURE_CLIENT_ID}" \
    --from-literal=clientSecret="${AZURE_CLIENT_SECRET}" \
    --from-literal=tenantId="${AZURE_TENANT_ID}" \
    --from-literal=vaultUrl="${VAULT_AZUREKEYVAULT_VAULT_NAME}"

installChart -d "${CHARTS_REPO_BASE}/external-secrets" \
    -c external-secrets \
    -n external-secrets \
    -s schema.bootstrap=true \
    -l "app.kubernetes.io/instance=external-secrets" \
    -u true

# ---------------------------------------------------------------------------- #
# Hashicorp Vault
# REQUIRES: ServiceMonitor
# PROVIDES: pki, secrets
# ---------------------------------------------------------------------------- #
installChart -d "${CHARTS_REPO_BASE}/hashicorp-vault" \
    -c vault \
    -n vault-system \
    -l "app.kubernetes.io/instance=vault" \
    -S PodReadyToStartContainers

kubectl -n vault-system wait --for=condition=Initialized pod/vault-0 \
    --timeout=300s

# init vault
cd ${REPO_DIR}/scripts/hvault && ./init.sh -e $EVT

# init pki
cd ${REPO_DIR}/scripts/hvault/intermediate-ca && \
    ./create-intermediate.sh -e $EVT && \
    scp work/${EVT}_intermediate_CA.csr 192.168.0.4:/tmp/ && \
    ssh 192.168.0.4 /usr/local/etc/step-ca/bin/sign-ica.sh -c /tmp/${EVT}_intermediate_CA.csr && \
    scp 192.168.0.4:/tmp/${EVT}_intermediate_CA.csr.signed.crt work/signed.${EVT}_intermediate_CA.csr.crt && \
    ./save-signed-intermediate.sh -e $EVT && \
    cd ${REPO_DIR}/scripts/cert-manager && \
    ./configure.sh -e $EVT

# ---------------------------------------------------------------------------- #
# cert-manager
# REQUIRES: ServiceMonitor
# PROVIDES: tls cert management
# ---------------------------------------------------------------------------- #
installChart -d "${CHARTS_REPO_BASE}/cert-manager" \
    -c cert-manager \
    -n cert-manager \
    -s schema.bootstrap=true \
    -l "app.kubernetes.io/instance=cert-manager" \
    -u true

# check clusterissuer status
kubectl get clusterissuers.cert-manager.io 

exit
# ---------------------------------------------------------------------------- #
# argocd
# ---------------------------------------------------------------------------- #
# get argocd admin password
ARGOPASS=$(vault kv get -address $EXTERNAL_VAULT_ADDR -format json \
    kv/minikube/argocd/admin-password \
    | jq -r '.data.data.bcrypt')

installChart -d "${CHARTS_REPO_BASE}/argocd" \
    -c argocd \
    -n argocd \
    -s schema.bootstrap=true \
    -s argo-cd.configs.secret.argocdServerAdminPassword=${ARGOPASS} \
    -l "app.kubernetes.io/instance=argocd" \
    -u true

exit

#kubectl -n monitoring exec -it  $(kubectl -n monitoring get pods | grep grafana | awk '{ print $1 }') -- grafana cli  admin reset-admin-password prom-operator

#helm template /tmp/gitops/helm/charts/umbrella/minikube \
#    -f /tmp/gitops/helm/charts/umbrella/minikube/values-infrastructure.yaml \
#    | kubectl -n argocd apply -f -
#
#for app in in-cluster-storage monitoring apps networking
#do
#helm template /tmp/gitops/helm/charts/umbrella/minikube \
#    -f /tmp/gitops/helm/charts/umbrella/minikube/values-${app}.yaml \
#    | kubectl -n argocd apply -f -
#done
