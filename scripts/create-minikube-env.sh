#!/usr/bin/env bash

# ---------------------------------------------------------------------------- #
#                             Functions
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
    -p Profile
    -h Help
EOT
   exit 2
}

[ -f ~/.external_hvault ] && source ~/.external_hvault

# ---------------------------------------------------------------------------- #
#                             Defaults
# ---------------------------------------------------------------------------- #
NFS_SERVER="192.168.0.3"
NFS_PATH="/data/nfs"
VAULT_URL="https://192.168.0.4:8443"
PROFILE="minikube"
CPU=2
MEM="2200MB"
NODES=1
EVT=""

while getopts c:e:m:n:N:p:v:w:h opt
do
    case $opt in
        c) CPU="${OPTARG}";;
        e) EVT="${OPTARG}";;
        m) MEM="${OPTARG}";;
        n) NFS_SERVER="${OPTARG}";;
        N) NFS_PATH="${OPTARG}";;
        p) PROFILE="${OPTARG}";;
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

# set up env
minikube stop --profile="${PROFILE}"
minikube delete --profile="${PROFILE}"
minikube start \
    --profile="${PROFILE}" \
    --memory="${MEM}" \
    --cpus="${CPU}" \
    --cni=flannel \
    --driver=docker \
    --container-runtime=containerd \
    --insecure-registry "192.168.0.0/24" \
    --nodes=${NODES} \
    --wait=all

export MINIKUBE_IP=$(minikube ip)

#minikube addons enable volumesnapshots
minikube addons enable dashboard 
minikube addons enable metrics-server 
minikube addons enable metallb

echo "
-- Enter Load Balancer Start IP: ${MINIKUBE_IP}24
-- Enter Load Balancer End IP: ${MINIKUBE_IP}54
"
minikube addons configure metallb

helm repo add nfs-subdir-external-provisioner \
    https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner

# Install nfs-provisioning
helm install -n nfs-provisioning nfs-subdir-external-provisioner \
    nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --create-namespace=true \
    --set "nfs.server=${NFS_SERVER}" \
    --set "nfs.path=${NFS_PATH}" \
    --set "storageClass.defaultClass=true" \
    --wait

# Wait for pods
echo "Waiting for nfs-provisioning pods to startup"
kubectl wait -n nfs-provisioning pods \
    -l app=nfs-subdir-external-provisioner \
    --for condition=Ready \
    --timeout=30s

kubectl patch storageclass standard \
    -p '{"metadata": 
    {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

# log in to external vault and renew token
vault login -address $EXTERNAL_VAULT_ADDR $ESO_TOKEN  
vault token renew -address $EXTERNAL_VAULT_ADDR $ESO_TOKEN 

# get azure cred
vault kv get -address $EXTERNAL_VAULT_ADDR -format json \
    kv/azure/akv-credentials > /tmp/az.creds.json

AZURE_CLIENT_ID=$(jq -r '.data.data.AZURE_CLIENT_ID' /tmp/az.creds.json)
AZURE_CLIENT_SECRET=$(jq -r '.data.data.AZURE_CLIENT_SECRET' /tmp/az.creds.json)
AZURE_TENANT_ID=$(jq -r '.data.data.AZURE_TENANT_ID' /tmp/az.creds.json)
SUBSCRIPTION_ID=$(jq -r '.data.data.SUBSCRIPTION_ID' /tmp/az.creds.json)
VAULT_AZUREKEYVAULT_KEY_NAME=$(jq -r '.data.data.VAULT_AZUREKEYVAULT_KEY_NAME' /tmp/az.creds.json)
VAULT_AZUREKEYVAULT_VAULT_NAME=$(jq -r '.data.data.VAULT_AZUREKEYVAULT_VAULT_NAME' /tmp/az.creds.json)
rm /tmp/az.creds.json

rm -rf /tmp/gitops
git clone git@github.com:vikashb72/gitops.git /tmp/gitops

kubectl create ns external-secrets
kubectl -n external-secrets delete secret azure-eso-config
kubectl -n external-secrets create secret generic \
    azure-eso-config \
    --from-literal=clientId="${AZURE_CLIENT_ID}" \
    --from-literal=clientSecret="${AZURE_CLIENT_SECRET}" \
    --from-literal=tenantId="${AZURE_TENANT_ID}" \
    --from-literal=vaultUrl="${VAULT_AZUREKEYVAULT_VAULT_NAME}"

helm install -n external-secrets external-secrets \
    /tmp/gitops/helm/charts/external-secrets

kubectl -n external-secrets wait pods \
    -l app.kubernetes.io/instance=external-secrets \
    --for condition=Ready \
    --timeout=90s

helm upgrade -n external-secrets external-secrets \
    /tmp/gitops/helm/charts/external-secrets \
    -f /tmp/gitops/helm/charts/external-secrets/values-${EVT}.yaml
exit


# get argocd admin password
ARGOPASS=$(vault kv get -address $EXTERNAL_VAULT_ADDR -format json \
    kv/minikube/argocd/admin-password \
    | jq -r '.data.data.bcrypt')


exit
helm repo add argocd https://argoproj.github.io/argo-helm
helm repo update
VERSION=$(helm search repo argocd/argo-cd -o json | jq -r '.[].version')

helm install -n argocd argocd argocd/argo-cd \
    --version ${VERSION} \
    --set configs.secret.argocdServerAdminPassword=${ARGOPASS} \
    --set server.service.type=LoadBalancer \
    --create-namespace=true

#helm dep update /tmp/gitops/k8s/helm/charts/core/argocd
#helm install -n argocd argocd  \
#    /tmp/gitops/k8s/helm/charts/core/argocd \
#    --create-namespace=true \
#    -f /tmp/gitops/k8s/helm/charts/core/argocd/values-bootstrap.yaml \
#    --wait

exit
#helm repo add external-secrets https://charts.external-secrets.io
# vix #
# vix #kubectl create namespace external-secrets
# vix #kubectl -n external-secrets create secret generic external-hashicorp-vault-token \
# vix #   --from-literal=addr=${EXTERNAL_VAULT_ADDR} \
# vix #   --from-literal=token=${ESO_TOKEN} \
# vix #   --from-file=root.ca=/usr/local/share/ca-certificates/Where_Ever_Root_CA_Root_CA_2025.crt
# vix #
# vix #    --wait 
# vix #
# vix #kubectl -n argocd get secret argocd-initial-admin-secret \
# vix #    -o jsonpath="{.data.password}" | base64 -d > argocd.adm.pw
# vix #echo ""
# vix #echo "$(cat argocd.adm.pw)"
# vix #echo ""
# vix #argocd login 192.168.49.2:30080 --insecure
# vix #argocd cluster list
# vix #
# vix #cat > ${EVT}.yaml <<EOF
# vix #metadata:
# vix #  name: ${EVT}
# vix #  namespace: argocd
# vix #spec:
# vix #  clusterResourceWhitelist:
# vix #    - group: '*'
# vix #      kind: '*'
# vix #  destinations:
# vix #    - namespace: '*'
# vix #      server: '*'
# vix #  sourceRepos:
# vix #    - '*'
# vix #EOF
# vix #
# vix #argocd proj create $EVT -f ${EVT}.yaml
# vix #    
# vix #helm template gitops/umbrella-chart/${EVT} | kubectl -n argocd apply -f -
# vix #argocd cluster list
# vix #argocd app list
