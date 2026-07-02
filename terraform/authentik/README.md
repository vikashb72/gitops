# Prerequisite
Login into Azure, secrets are in azure keyvault.
```
az login
```

# Enviroment
```
ORGANISATION="wherever"
DEPARTMENT="home"
PROJECT="lab"
ENVIRONMENT="hub"
SUBSCRIPTION_ID=$(az account show | jq -r '.id')
CLIENT_ID=$(az ad sp list \
    --display-name sp-terraform-cli \
    | jq -r '.[].servicePrincipalNames[0]')
CLIENT_SECRET=$(az keyvault secret show \
    --vault-name kv-home-where-ever \
    --query value 
    --name Provisioning-Client-Secret \
    -o tsv )
TENANT_ID=$(az account show | jq -r '.tenantId')
TF_STORAGE_ACCOUNT_NAME="st${ENVIRONMENT}{$PROJECT}${DEPARTMENT}${ORGANISATION}01"
TF_STORAGE_ACCOUNT_RGRP="rg-${ENVIRONMENT}-${PROJECT}-${DEPARTMENT}-${ORGANISATION}-za"
CONTAINER_NAME="tfstate-${ENVIRONMENT}-${PROJECT}-${DEPARTMENT}-${ORGANISATION}"
CONTAINER_KEY_NAME="authentik.tfstate"
```

# Terraform Variables
```
export TF_VAR_authentik_token=$(vault kv get -format json \
    kv/minikube/authentik/secrets \
    | jq -r .data.data.AUTHENTIK_BOOTSTRAP_TOKEN)

export TF_VAR_grafana_client_id=$(vault kv get -format json \
    kv/minikube/grafana/authentik-client | jq -r .data.data.id)
export TF_VAR_grafana_client_secret=$(vault kv get -format json \
    kv/minikube/grafana/authentik-client | jq -r .data.data.secret)

export TF_VAR_argocd_client_id=$(vault kv get -format json \
    kv/minikube/argocd/authentik-client | jq -r .data.data.id)
export TF_VAR_argocd_client_secret=$(vault kv get -format json \
    kv/minikube/argocd/authentik-client | jq -r .data.data.secret)
```

# Authentik outputs id
```
echo <<EOT
get pk from https://authentik.tld/api/v3/outposts/instances/?ordering=name&page=1&page_size=20&search=
terraform import authentik_outpost.embedded_outpost \$VALUE \
  -var-file="tfvars/minikube.tfvars" -var="tenant_id=${TENANT_ID}" \
  -var="subscription_id=${SUBSCRIPTION_ID}" -var="storage_account=$TF_STORAGE_ACCOUNT_NAME"
EOT
```

# Terraform init
```
terraform init -backend-config=storage_account_name=$TF_STORAGE_ACCOUNT_NAME \
    -backend-config=container_name=$CONTAINER_NAME \
    -backend-config=key=$CONTAINER_KEY_NAME \
    -backend-config=resource_group_name=$TF_STORAGE_ACCOUNT_RGRP \
    -backend-config=subscription_id=$SUBSCRIPTION_ID \
    -backend-config=tenant_id=$TENANT_ID \
    -backend-config=client_id=$CLIENT_ID \
    -backend-config=client_secret=$CLIENT_SECRET \
    -reconfigure \
    -upgrade
```

# get pk from https://authentik.tld/api/v3/outposts/instances/?ordering=name&page=1&page_size=20&search=
## get the pk for the outpost
---
      "pk": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "name": "authentik Embedded Outpost",
---
```
OUTPOST_ID=value of pk 
```

## get the service connection id
---
      "service_connection": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx",
      "service_connection_obj": {
        "pk": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx",
        "name": "Local Kubernetes Cluster",
---
update service_connection in tfvars/${EVT}.prd

# Terraform import
```
terraform import -var-file="tfvars/minikube.tfvars" \
    -var="tenant_id=${TENANT_ID}" \
    -var="subscription_id=${SUBSCRIPTION_ID}" \
    -var="storage_account=$TF_STORAGE_ACCOUNT_NAME" \
    -var="vault_address=${EXTERNAL_VAULT_ADDR}" \
    -var="vault_token=$ROOT_TOKEN" \
    -var="akv_name=kv-home-where-ever" \
    -var="akv_rg=rg-home-where-ever" \
    authentik_outpost.embedded_outpost $OUTPOST_ID
```

# Terraform import
```
terraform plan \
  -var-file="tfvars/${ENVIRONMENT}.tfvars" \
  -var="tenant_id=${TENANT_ID}" \
  -var="subscription_id=${SUBSCRIPTION_ID}" \
  -var="storage_account=$TF_STORAGE_ACCOUNT_NAME" \
  -out ${ENVIRONMENT}.tfplan
```

# Terraform apply
```
terraform apply ${ENVIRONMENT}.tfplan
```
