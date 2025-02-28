# https://azure.github.io/aca-dotnet-workshop/aca/10-aca-iac-bicep/02-ci-cd-git-action/

export BACKEND_API_PRINCIPAL_ID=$(az containerapp identity show \
 --name "$BACKEND_API_NAME" \
 --resource-group "$RESOURCE_GROUP" \
 --query principalId \
 --output tsv)

export FRONTEND_WEBAPP_PRINCIPAL_ID=$(az containerapp identity show \
 --name "$FRONTEND_WEBAPP_NAME" \
 --resource-group "$RESOURCE_GROUP" \
 --query principalId \
 --output tsv)

export BACKEND_SERVICE_PRINCIPAL_ID=$(az containerapp identity show \
 --name "$BACKEND_SERVICE_NAME" \
 --resource-group "$RESOURCE_GROUP" \
 --query principalId \
 --output tsv)

export ACR_RESOURCE_ID=$(az acr show --name $AZURE_CONTAINER_REGISTRY_NAME --query id --output tsv)

az role assignment create \
  --assignee $BACKEND_API_PRINCIPAL_ID \
  --role AcrPull \
  --scope $ACR_RESOURCE_ID

az role assignment create \
  --assignee $FRONTEND_WEBAPP_PRINCIPAL_ID \
  --role AcrPull \
  --scope $ACR_RESOURCE_ID

az role assignment create \
  --assignee $BACKEND_SERVICE_PRINCIPAL_ID \
  --role AcrPull \
  --scope $ACR_RESOURCE_ID

az containerapp registry set --name $BACKEND_API_NAME \
 --resource-group $RESOURCE_GROUP \
  --server $AZURE_CONTAINER_REGISTRY_NAME.azurecr.io \
  --identity system

az containerapp registry set --name $FRONTEND_WEBAPP_NAME \
 --resource-group $RESOURCE_GROUP \
  --server $AZURE_CONTAINER_REGISTRY_NAME.azurecr.io \
  --identity system

az containerapp registry set --name $BACKEND_SERVICE_NAME \
 --resource-group $RESOURCE_GROUP \
  --server $AZURE_CONTAINER_REGISTRY_NAME.azurecr.io \
  --identity system

# Configure Azure Service Principal and secrets for GitHub Repo
export SP_NAME="aca-ghactions-sp"
az ad sp create-for-rbac --display-name $SP_NAME \
    --role contributor \
    --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP

export SP_ID=$(az ad app list --display-name $SP_NAME --query [].appId -o tsv)

az ad app federated-credential create --id $SP_ID --parameters credential.json