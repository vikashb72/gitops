# Enviroments

## Variables
az login

ORGANISATION="wherever"
DEPARTMENT="home"
PROJECT="lab"
ENVIRONMENT="hub"
SUBSCRIPTION_ID=$(az account show | jq -r '.id')
CLIENT_ID=$(az ad sp list --display-name sp-terraform-cli \
    | jq -r '.[].servicePrincipalNames[0]')
CLIENT_SECRET=$(az keyvault secret show --vault-name kv-home-where-ever \
    --query value -o tsv --name Provisioning-Client-Secret)
TENANT_ID=$(az account show | jq -r '.tenantId')
TF_STORAGE_ACCOUNT_NAME="st${ENVIRONMENT}{$PROJECT}${DEPARTMENT}${ORGANISATION}01"
TF_STORAGE_ACCOUNT_RGRP="rg-${ENVIRONMENT}-${PROJECT}-${DEPARTMENT}-${ORGANISATION}-za"
CONTAINER_NAME="tfstate-${ENVIRONMENT}-${PROJECT}-${DEPARTMENT}-${ORGANISATION}"
CONTAINER_KEY_NAME="authentik.tfstate"

./setup.sh

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

# get pk from https://authentik.tld/api/v3/outposts/instances/?ordering=name&page=1&page_size=20&search=

terraform plan \
  -var-file="tfvars/${ENVIRONMENT}.tfvars" \
  -var="tenant_id=${TENANT_ID}" \
  -var="subscription_id=${SUBSCRIPTION_ID}" \
  -var="storage_account=$TF_STORAGE_ACCOUNT_NAME" \
  -out ${ENVIRONMENT}.tfplan

