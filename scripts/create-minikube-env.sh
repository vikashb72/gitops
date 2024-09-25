#!/usr/bin/env bash

source ~/.external_hvault

#
# Functions
#
Usage() {
   cat <<EOT
Usage:
    -e Environment (dev|uat|prod|minikube|k3s|k8s)
    -n NFS Server
    -N NFS Path
    -v Vault Url
    -h Help
EOT
   exit 2
}

#
# Defaults
#
NFS_SERVER="192.168.0.5"
NFS_PATH="/data/nfs"
VAULT_URL="https://192.168.0.22:8200"
EVT=""

while getopts e:n:N:v:h opt
do
    case $opt in
        e) EVT="${OPTARG}";;
        n) NFS_SERVER="${OPTARG}";;
        N) NFS_PATH="${OPTARG}";;
        v) VAULT_URL="${OPTARG}";;
        h) Usage;;
        *) Usage;;
    esac
done

[ -z $EVT ] && Usage

export NFS_SERVER
export NFS_PATH
export EXTERNAL_VAULT
export EVT

# Add Helm repos
helm repo add argo-cd https://argoproj.github.io/argo-helm
helm repo add external-secrets https://charts.external-secrets.io
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo add jetstack https://charts.jetstack.io
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
helm repo add vault-raft-snapshot-agent https://argelbargel.github.io/vault-raft-snapshot-agent-helm/

# set up env
minikube stop
minikube delete
minikube start \
    --cni=flannel \
    --driver=docker \
    --container-runtime=containerd \
    --insecure-registry "192.168.0.0/24" \
    --wait=all

export MINIKUBE_IP=$(minikube ip)

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

kubectl create namespace external-secrets
kubectl -n external-secrets create secret generic external-hashicorp-vault-token \
   --from-literal=addr=${EXTERNAL_VAULT_ADDR} \
   --from-literal=token=${ESO_TOKEN} \
   --from-file=root.ca=/usr/local/share/ca-certificates/Where_Ever_Root_CA_Root_CA_212425365443306115571426638685908456843.crt

rm -rf gitops
git clone git@github.com:vikashb72/gitops.git
helm dep update gitops/charts/argo-cd
helm install -n argocd argo-cd  gitops/charts/argo-cd \
    --create-namespace=true \
    -f gitops/charts/argo-cd/values-${EVT}.yaml \
    --wait 

kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" | base64 -d > argocd.adm.pw
echo ""
echo "$(cat argocd.adm.pw)"
echo ""
argocd login 192.168.49.2:30080 --insecure
argocd cluster list

cat > ${EVT}.yaml <<EOF
metadata:
  name: ${EVT}
  namespace: argocd
spec:
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'
  destinations:
    - namespace: '*'
      server: '*'
  sourceRepos:
    - '*'
EOF

argocd proj create $EVT -f ${EVT}.yaml
    
helm template gitops/umbrella-chart/${EVT} | kubectl -n argocd apply -f -
argocd cluster list
argocd app list
