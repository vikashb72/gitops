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
CPU=2
MEM="2200MB"
NODES=1
EVT=""

# ---------------------------------------------------------------------------- #
#                             Process Args
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
#                             Set up minikube
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
    --wait=all

export MINIKUBE_IP=$(minikube ip)

# ---------------------------------------------------------------------------- #
#                             Minikube Addons
# ---------------------------------------------------------------------------- #
#minikube addons enable volumesnapshots
minikube addons enable dashboard 
minikube addons enable metrics-server 
minikube addons enable metallb

echo "
-- Enter Load Balancer Start IP: ${MINIKUBE_IP}24
-- Enter Load Balancer End IP: ${MINIKUBE_IP}54
"
#minikube addons configure metallb

cat > /tmp/metallb.cm.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: config
  namespace: metallb-system
data:
  config: |
    address-pools:
      - name: default
        protocol: layer2
        addresses:
          - ${MINIKUBE_IP}24-${MINIKUBE_IP}54
EOF

kubectl -n metallb-system apply -f /tmp/metallb.cm.yaml

rm /tmp/metallb.cm.yaml
# ---------------------------------------------------------------------------- #
#                             Storage
# ---------------------------------------------------------------------------- #
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
    --timeout=180s

# ---------------------------------------------------------------------------- #
#                             Disable host path storage
# ---------------------------------------------------------------------------- #
kubectl patch storageclass standard \
    -p '{"metadata": 
    {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

# ---------------------------------------------------------------------------- #
#                             Login to External Vault
# ---------------------------------------------------------------------------- #
# log in to external vault and renew token
vault login -address $EXTERNAL_VAULT_ADDR $ESO_TOKEN  
vault token renew -address $EXTERNAL_VAULT_ADDR $ESO_TOKEN 

# ---------------------------------------------------------------------------- #
#                             Get Azure Credentials
# ---------------------------------------------------------------------------- #
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

# ---------------------------------------------------------------------------- #
#                             Pull repo
# ---------------------------------------------------------------------------- #
rm -rf /tmp/gitops
git clone git@github.com:vikashb72/gitops.git /tmp/gitops

# ---------------------------------------------------------------------------- #
#                             External Secrets
# ---------------------------------------------------------------------------- #
kubectl create ns external-secrets
kubectl -n external-secrets delete secret azure-eso-config
kubectl -n external-secrets create secret generic \
    azure-eso-config \
    --from-literal=clientId="${AZURE_CLIENT_ID}" \
    --from-literal=clientSecret="${AZURE_CLIENT_SECRET}" \
    --from-literal=tenantId="${AZURE_TENANT_ID}" \
    --from-literal=vaultUrl="${VAULT_AZUREKEYVAULT_VAULT_NAME}"

# bootstrap installation
# the point of this is really to install the CRDs
helm dependency build /tmp/gitops/helm/charts/external-secrets
helm install -n external-secrets external-secrets \
    /tmp/gitops/helm/charts/external-secrets \
    --set schema.bootstrap=true \
    -f /tmp/gitops/helm/charts/external-secrets/values-${EVT}.yaml \
    --wait

# wait for pods 
# we are really waiting for the CRD installation
kubectl -n external-secrets wait pods \
    -l app.kubernetes.io/instance=external-secrets \
    --for condition=Ready \
    --timeout=180s

# upgrade so that we install the secretstores
helm upgrade -n external-secrets external-secrets \
    /tmp/gitops/helm/charts/external-secrets \
    -f /tmp/gitops/helm/charts/external-secrets/values-${EVT}.yaml \
    --timeout=180s

# ---------------------------------------------------------------------------- #
#                             argocd
# ---------------------------------------------------------------------------- #
# get argocd admin password
ARGOPASS=$(vault kv get -address $EXTERNAL_VAULT_ADDR -format json \
    kv/minikube/argocd/admin-password \
    | jq -r '.data.data.bcrypt')

helm repo add argocd https://argoproj.github.io/argo-helm
helm repo update
helm dep update /tmp/gitops/helm/charts/argocd

# bootstrap installation
# the point of this is really to install the CRDs
helm install -n argocd argocd \
    /tmp/gitops/helm/charts/argocd \
    --set argo-cd.configs.secret.argocdServerAdminPassword=${ARGOPASS} \
    --set schema.bootstrap=true  \
    --set schema.serviceMonitor.enabled='&enable-serviceMonitor "false"'  \
    --create-namespace=true \
    -f /tmp/gitops/helm/charts/argocd/values-${EVT}.yaml \
    --wait

# wait
kubectl -n argocd wait pods -l app.kubernetes.io/instance=argocd \
   --for condition=Ready --timeout=240s

# upgrade so that we install the Projects
helm upgrade -n argocd argocd \
    /tmp/gitops/helm/charts/argocd \
    --set argo-cd.configs.secret.argocdServerAdminPassword=${ARGOPASS} \
    --create-namespace=true \
    -f /tmp/gitops/helm/charts/argocd/values-${EVT}.yaml \
    --wait

helm template /tmp/gitops/helm/charts/umbrella/minikube \
    -f /tmp/gitops/helm/charts/umbrella/minikube/values-infrastructure.yaml \
    | kubectl -n argocd apply -f -

for app in in-cluster-storage monitoring apps
do
helm template /tmp/gitops/helm/charts/umbrella/minikube \
    -f /tmp/gitops/helm/charts/umbrella/minikube/values-${app}.yaml \
    | kubectl -n argocd apply -f -
done
