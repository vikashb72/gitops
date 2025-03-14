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
#[ -z $VAULT_TOKEN ] && echo "MISSING ENV: VAULT_TOKEN" && exit 2

WORKDIR=$(pwd)/work

#ISSURER="https://vault.${DOMAIN}:8200"
ISSURER="https://vault-active.vault-system.svc.cluster.local:8200"

kubectl -n vault-system exec -it vault-0 -- \
    vault write pki/config/urls \
        issuing_certificates="${ISSURER}/v1/pki/ca" \
        crl_distribution_points="${ISSURER}/v1/pki/crl"

kubectl -n vault-system cp ${WORKDIR}/signed_${EVT}_intermediate_CA.crt \
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


# test

cd work
kubectl -n vault-system exec -it vault-0 -- \
vault write -format=json \
    pki/issue/generate-cert-role \
    common_name="test.${EVT}.example.com" \
    ttl=30m \
    | jq .data -r > test.${EVT}.json

jq -r '.private_key' test.${EVT}.json > test.${EVT}.key
jq -r '.certificate' test.${EVT}.json > test.${EVT}.crt
jq -r '.ca_chain[]'  test.${EVT}.json > ${EVT}.ca.crt
