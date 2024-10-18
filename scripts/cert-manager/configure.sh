#!/usr/bin/env bash

usage() {
   echo "Usage: $0 -e dev|prod|uat"
   exit 3
}

VAULT_K8S_NAMESPACE="vault-system"
WORKDIR=$(pwd)/work
mkdir -p $WORKDIR

unset $EVT

while getopts "e:" o; do
    case "${o}" in
        e)
            EVT=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

# This is needed
[ -z $EVT ] && echo "MISSING ENV: EVT" && usage && exit 2

[ -z $VAULT_TOKEN ] && echo "MISSING ENV: VAULT_TOKEN" && exit 2

# Check vault status (sealed etc)
STATUS=$(kubectl -n $VAULT_K8S_NAMESPACE exec vault-0 -- vault status | \
     grep -E '^Initialized *true$|^Sealed *false' | wc -l)

[ ${STATUS} -ne 2 ] && echo "REQUIRES WORKING VAULT" && exit 2

# policy
# the paths are from the offline.root.ca.ica.sh script
cat > policy.hc1 <<EOF
path "pki*"                           { capabilities = ["read", "list"] }
path "pki/sign/generate-cert-role"    { capabilities = ["create", "update"] }
path "pki/issue/generate-cert-role"   { capabilities = ["create"] }
EOF

kubectl -n vault-system exec -it vault-0 -- vault login $VAULT_TOKEN
kubectl -n vault-system cp policy.hc1 vault-0:/tmp/pki.policy.hc1
kubectl -n vault-system exec -it vault-0 -- vault policy write pki /tmp/pki.policy.hc1
rm policy.hc1

kubectl -n vault-system exec -it vault-0 -- \
    vault write auth/kubernetes/role/vault-cert-issuer \
    bound_service_account_names=vault-cert-issuer \
    bound_service_account_namespaces=cert-manager \
    policies=pki \
    ttl=20m

kubectl -n vault-system exec -it vault-0 -- \
    vault write auth/kubernetes/config \
    kubernetes_host="https://kubernetes.default"

