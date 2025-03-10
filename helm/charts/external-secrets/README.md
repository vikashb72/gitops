# External Secrets Operator Chart
Packaging for External Secrets Operator, specific for my needs

## Variables
The schema variable is used to specify the environment specific envariables 

```
schema:
  env: <ENVIRONMENT_NAME>
  bootstrap: false
  namespace: &schema-namespace "external-secrets"
  SecretStores:
    azure-backend:
      disable: false
      namespace: *schema-namespace
      provider: azurekv
      tenantId: <AZURE_TENANT_ID>
      authType: ServicePrincipal
      vaultUrl: <AZURE_KEY_VAULT_URL>
      authSecretRef:
        clientId:
          name: <SECRET_NAME>
          key: clientId
        clientSecret:
          name: <SECRET_NAME>
          key: clientSecret
    external-vault-backend:
      disable: false
      provider: vault
      server: <EXTERNAL_VAULT_URL>
      path: kv
      version: v2
      auth:
        tokenSecretRef:
          name: <SECRET_NAME>
          namespace: *schema-namespace
          key: token
      caProvider:
        type: Secret
        name: <SECRET_NAME>
        key: ca.crt
        namespace: *schema-namespace
  Secrets:
    external-hashicorp-vault-token:
      namespace: *schema-namespace
      refresh: 8h
      store: azure-backend
      properties:
        - localkey: token
          remotekey: <SECRET_NAME>
          remoteproperty: token
        - localkey: ext-vault-addr
          remotekey: <SECRET_NAME>
          remoteproperty: ext-vault-addr
        - localkey: ca.crt
          remotekey: <SECRET_NAME>
          remoteproperty: ca.crt
    vault-tls:
      #namespace: *schema-namespace
      refresh: 1h
      store: external-vault-backend
      properties:
        - localkey: ca.crt
          remotekey: <SECRET_PATH>
          remoteproperty: ca.crt
        - localkey: tls.crt
          remotekey: <SECRET_PATH>
          remoteproperty: tls.crt
        - localkey: tls.key
          remotekey: <SECRET_PATH>
          remoteproperty: tls.key
```

## Bootstrapping installation

### Create namespace
```
kubectl create ns external-secrets
```

### Secrets

#### Azure Access Credentials
```
kubectl -n external-secrets create secret generic \
    azure-eso-config \
    --from-literal=clientId="${AZURE_CLIENT_ID}" \
    --from-literal=clientSecret="${AZURE_CLIENT_SECRET}" \
    --from-literal=tenantId="${AZURE_TENANT_ID}" \
    --from-literal=vaultUrl="${VAULT_AZUREKEYVAULT_VAULT_NAME}"
```

#### External Hashicorp Vault Access Credentials
```
kubectl -n external-secrets create secret generic \
    external-hashicorp-vault-token \
    --from-literal=addr=${EXTERNAL_VAULT_ADDR} \
    --from-literal=token=${ESO_TOKEN} \
    --from-file=ca.crt=/path/to/ca/cert
```

### Installation

#### Boostrap Installation
#### Install CRD
```
helm install -n external-secrets external-secrets \
    /path/to/helm/charts/external-secrets \
    --set schema.bootstrap=true \
    --set external-secrets.webhook.certManager.enabled=false \
    -f /path/to/helm/charts/external-secrets-${EVT}.yaml
```

#### Wait for installation
```
kubectl -n external-secrets wait pods \
    -l app.kubernetes.io/instance=external-secrets \
    --for condition=Ready \
    --timeout=90s
```

# upgrade to install ourt secretstores
```
helm install -n external-secrets external-secrets \
    /path/to/helm/charts/external-secrets \
    --set external-secrets.webhook.certManager.enabled=false \
    -f /path/to/helm/charts/external-secrets-${EVT}.yaml
```
