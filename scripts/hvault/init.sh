#!/usr/bin/env bash

print_usage() {
   echo "usage: $0 -e dev|uat|prod"
   exit 2
}

EVT=""

while getopts "e:" opt
do
   case "${opt}" in
     e) EVT=${OPTARG};;
     *) usage;;
   esac
done

[ -z $EVT ] && echo "MISSING ENV: EVT" && usage && exit 2

WORKDIR=$(pwd)/workdir/
mkdir -p $WORKDIR
kubectl -n vault-system exec -it vault-0 -- vault operator init -format=json \
    > $WORKDIR/init.json

ROOT_TOKEN=$(jq -r ".root_token" $WORKDIR/init.json)
RECOVERY_KEYS=$(jq -r ".recovery_keys_b64[]" $WORKDIR/init.json)

c=0
CMD="vault kv put kv/${EVT}/vault/init "
for KEY in $RECOVERY_KEYS
do
   c=$((c+1))
   CMD="${CMD} key${c}=\"$KEY\""
done
CMD="${CMD} root_token=\"${ROOT_TOKEN}\""

kubectl -n vault-system exec -it vault-0 -- vault login $ROOT_TOKEN

VAULT_PODS=$(kubectl -n vault-system get pods \
    -l app.kubernetes.io/name=vault \
    --no-headers -o custom-columns=":metadata.name" |
    grep -v vault-0 | grep -v vault-server-test)

for POD in $VAULT_PODS; do
    cat >${WORKDIR}/join-raft.sh <<EOF
vault operator raft join -address=https://${POD}.vault-internal:8200 \
    -leader-ca-cert="\$(cat /vault/userconfig/hvault-config/ca.crt)" \
    -leader-client-cert="\$(cat /vault/userconfig/hvault-config/tls.crt)" \
    -leader-client-key="\$(cat /vault/userconfig/hvault-config/tls.key)"\
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

kubectl exec -ti vault-0 -n vault-system -c vault -- sh -c 'vault write auth/kubernetes/config kubernetes_host="https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT" kubernetes_ca_cert="$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt)" token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" disable_iss_validation=true disable_local_ca_jwt=true'


echo "saving init keys..... "
echo $CMD > $WORKDIR/vault.cmd.sh
scp $WORKDIR/vault.cmd.sh 192.168.0.4:/tmp/vault.cmd.sh
ssh 192.168.0.4 bash -x /tmp/vault.cmd.sh
ssh 192.168.0.4 rm /tmp/vault.cmd.sh

echo $CMD
