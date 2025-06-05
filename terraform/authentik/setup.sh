export ORGANISATION="wherever"
export DEPARTMENT="home"
export PROJECT="lab"
export ENVIRONMENT="hub"
export SUBSCRIPTION_ID=$(az account show | jq -r '.id')
export CLIENT_ID=$(az ad sp list --display-name sp-terraform-cli \
     | jq -r '.[].servicePrincipalNames[0]')
export CLIENT_SECRET=$(az keyvault secret show --vault-name kv-home-where-ever \
     --query value -o tsv --name Provisioning-Client-Secret)
export TENANT_ID=$(az account show | jq -r '.tenantId')
export TF_STORAGE_ACCOUNT_NAME="st${ENVIRONMENT}{$PROJECT}${DEPARTMENT}${ORGANISATION}01"
export TF_STORAGE_ACCOUNT_RGRP="rg-${ENVIRONMENT}-${PROJECT}-${DEPARTMENT}-${ORGANISATION}-za"
export CONTAINER_NAME="tfstate-${ENVIRONMENT}-${PROJECT}-${DEPARTMENT}-${ORGANISATION}"
export CONTAINER_KEY_NAME="authentik.tfstate"

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


echo <<EOT
get pk from https://authentik.tld/api/v3/outposts/instances/?ordering=name&page=1&page_size=20&search=
terraform import authentik_outpost.embedded_outpost \$VALUE \
  -var-file="tfvars/minikube.tfvars" -var="tenant_id=${TENANT_ID}" \
  -var="subscription_id=${SUBSCRIPTION_ID}" -var="storage_account=$TF_STORAGE_ACCOUNT_NAME"
EOT
