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

#[ -z $VAULT_TOKEN ] && echo "MISSING ENV: VAULT_TOKEN" && exit 2

# Check vault status (sealed etc)
STATUS=$(kubectl -n $VAULT_K8S_NAMESPACE exec vault-0 -- vault status | \
     grep -E '^Initialized *true$|^Sealed *false' | wc -l)

[ ${STATUS} -ne 2 ] && echo "REQUIRES WORKING VAULT" && exit 2

# policy
# the paths are from the offline.root.ca.ica.sh script
cat > ${WORKDIR}/prometheus-metrics.hc1 <<EOF
path "/sys/metrics" {
  capabilities = ["read"]
}
EOF

#kubectl -n vault-system exec -it vault-0 -- vault login $VAULT_TOKEN
kubectl -n vault-system cp  ${WORKDIR}/prometheus-metrics.hc1 \
    vault-0:/tmp/metrics.policy.hc1
kubectl -n vault-system exec -it vault-0 -- \
    vault policy write prometheus-metrics /tmp/metrics.policy.hc1
rm ${WORKDIR}/prometheus-metrics.hc1

