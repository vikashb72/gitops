#!/usr/bin/env bash

    cat > policy-snapshot.hc1 <<EOT
path "kv/*" {
  capabilities = ["create","update","read"]
}

path "auth/kubernetes/login" {
  capabilities = ["create","update","read"]
}
EOT

kubectl -n vault-system cp policy-snapshot.hc1 \
    vault-0:/tmp/policy-snapshot.hc1
kubectl exec -ti vault-0 -n vault-system -c vault -- \
    vault policy write eso-role /tmp/policy-snapshot.hc1
kubectl exec -ti vault-0 -n vault-system -c vault -- rm /tmp/policy-snapshot.hc1

kubectl -n vault-system exec -it vault-0 -- \
    vault write auth/kubernetes/role/eso-role \
    bound_service_account_names=external-secrets \
    bound_service_account_namespaces="external-secrets,vault-system,argocd,cert-manager,kafka-system,istio-system,keda,keycloak,kube-system,vpa-system,grafana,prometheus,reloader" \
    ttl=86400 \
    policies=eso-role
