#!/usr/bin/env bash

usage() {
   echo "Usage: $0 -e dev|prod|uat"
   exit 3
}

# incase its set to the incorrect param
unset $EVT
while getopts "e:" o; do
    case "${o}" in
        e) EVT=${OPTARG};;
        *) usage;;
    esac
done

# This is needed
[ -z $EVT ] && echo "MISSING ENV: EVT" && usage && exit 2
[ -z $VAULT_TOKEN ] && echo "MISSING ENV: VAULT_TOKEN" && exit 2

VAULT_K8S_NAMESPACE="vault-system"
WORKDIR=$(pwd)/work
mkdir -p ${WORKDIR}
UPPER_EVT=$(echo $EVT | tr '[:lower:]' '[:upper:]')

kubectl -n vault-system exec -it vault-0 -- \
    vault secrets enable \
        -description="${UPPER_EVT} Intermediate CA" \
        -max-lease-ttl=87600h  \
        -default-lease-ttl=87600h pki

kubectl -n vault-system exec -it vault-0 -- \
    vault write -format=json \
        pki/intermediate/generate/internal \
        common_name="${UPPER_EVT} Intermediate Authority" \
        ttl=43800h \
        | jq -r '.data.csr' > ${WORKDIR}/${EVT}_intermediate_CA.csr

echo "
# from CA
step certificate sign \
    --not-after 43800h \
    --profile intermediate-ca \
    --path-len 0 \
    /path/to/${EVT}_intermediate_CA.csr \
    /usr/local/etc/step/ca/certs/root_ca.crt \
    /usr/local/etc/step/ca/secrets/root_ca_key \
    > signed_${EVT}_intermediate_CA.crt
"

exit
