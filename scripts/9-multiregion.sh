# Create a new instance of Azure Front Door (made from the portal)

# Create a Vnet in the secondary region
az network vnet create \
--name vnet-tasks-tracker-region3 \
--resource-group fd-aca \
--location centralus \
--address-prefix 10.0.0.0/16 \
--subnet-name ContainerAppSubnet \
--subnet-prefix 10.0.0.0/27

# Delegate subnet control to Azure Container Apps Environment
az network vnet subnet update \
--name ContainerAppSubnet \
--resource-group "$RESOURCE_GROUP_REG2" \
--vnet-name "$VNET_REG2_NAME" \
--delegations Microsoft.App/environments

export ACA_ENVIRONMENT_REG2_SUBNET_ID=$(az network vnet subnet show \
--name ContainerAppSubnet \
--resource-group "$RESOURCE_GROUP_REG2" \
--vnet-name "$VNET_REG2_NAME" \
--query id \
--output tsv)

# Create a new Azure Container Apps Environment in the secondary region
az containerapp env create \
--name aca-env-region-3 \
--resource-group $RESOURCE_GROUP_REG2 \
--location westeurope \
--enable-workload-profiles \
--infrastructure-subnet-resource-id "$ACA_ENVIRONMENT_REG2_SUBNET_ID"

# Deploy the Frontend UI on Azure Container Apps
az containerapp create \
  --name "$FRONTEND_WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP_REG2" \
  --environment aca-env-region-3 \
  --image "$AZURE_CONTAINER_REGISTRY_NAME.azurecr.io/tasksmanager/$FRONTEND_WEBAPP_NAME:europe-v1" \
  --registry-server "$AZURE_CONTAINER_REGISTRY_NAME.azurecr.io" \
  --target-port "$TARGET_PORT" \
  --ingress external \
  --min-replicas 0 \
  --max-replicas 1 \
  --cpu 0.25 \
  --memory 0.5Gi \
  --query properties.configuration.ingress.fqdn