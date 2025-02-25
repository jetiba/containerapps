# Login to Azure and select the default subscription
az login

# Set the default subscription id variable
export AZURE_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
echo "Resources will be deployes in the Subscription with id=$AZURE_SUBSCRIPTION_ID"

# Create a random, 6-digit, Azure safe string
export RANDOM_STRING=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)
export RESOURCE_GROUP="rg-tasks-tracker-$RANDOM_STRING"
export LOCATION="westus2"
export ENVIRONMENT="cae-tasks-tracker"
export WORKSPACE_NAME="log-tasks-tracker-$RANDOM_STRING"
export APPINSIGHTS_NAME="appi-tasks-tracker-$RANDOM_STRING"
export BACKEND_API_NAME="tasksmanager-backend-api"
export AZURE_CONTAINER_REGISTRY_NAME="crtaskstracker$RANDOM_STRING"
export VNET_NAME="vnet-tasks-tracker"
export TARGET_PORT=8080

# Create a resource group
az group create \
--name "$RESOURCE_GROUP" \
--location "$LOCATION"

# Create a Vnet
az network vnet create \
--name "$VNET_NAME" \
--resource-group "$RESOURCE_GROUP" \
--address-prefix 10.0.0.0/16 \
--subnet-name ContainerAppSubnet \
--subnet-prefix 10.0.0.0/27

# Delegate subnet control to Azure Container Apps Environment
az network vnet subnet update \
--name ContainerAppSubnet \
--resource-group "$RESOURCE_GROUP" \
--vnet-name "$VNET_NAME" \
--delegations Microsoft.App/environments

export ACA_ENVIRONMENT_SUBNET_ID=$(az network vnet subnet show \
--name ContainerAppSubnet \
--resource-group "$RESOURCE_GROUP" \
--vnet-name "$VNET_NAME" \
--query id \
--output tsv)

# Create the Log Analytics workspace
az monitor log-analytics workspace create \
--resource-group "$RESOURCE_GROUP" \
--workspace-name "$WORKSPACE_NAME"

# Retrieve the Log Analytics workspace ID
export WORKSPACE_ID=$(az monitor log-analytics workspace show \
--resource-group "$RESOURCE_GROUP" \
--workspace-name "$WORKSPACE_NAME" \
--query customerId \
--output tsv)

# Retrieve the Log Analytics workspace secret
export WORKSPACE_SECRET=$(az monitor log-analytics workspace get-shared-keys \
--resource-group "$RESOURCE_GROUP" \
--workspace-name "$WORKSPACE_NAME" \
--query primarySharedKey \
--output tsv)

# Create Application Insights instance
az monitor app-insights component create \
--resource-group "$RESOURCE_GROUP" \
--location "$LOCATION" \
--app "$APPINSIGHTS_NAME" \
--workspace "$WORKSPACE_NAME"

# Get Application Insights Instrumentation Key
export APPINSIGHTS_INSTRUMENTATIONKEY=$(az monitor app-insights component show \
--resource-group "$RESOURCE_GROUP" \
--app "$APPINSIGHTS_NAME" \
--output tsv --query instrumentationKey)

echo $APPINSIGHTS_INSTRUMENTATIONKEY

# Create a Azure Container Registry
az acr create \
--name "$AZURE_CONTAINER_REGISTRY_NAME" \
--resource-group "$RESOURCE_GROUP" \
--sku Basic \
--admin-enabled true

# Create the ACA environment
az containerapp env create \
--name "$ENVIRONMENT" \
--resource-group "$RESOURCE_GROUP" \
--location "$LOCATION" \
--logs-workspace-id "$WORKSPACE_ID" \
--logs-workspace-key "$WORKSPACE_SECRET" \
--dapr-instrumentation-key "$APPINSIGHTS_INSTRUMENTATIONKEY" \
--enable-workload-profiles \
--infrastructure-subnet-resource-id "$ACA_ENVIRONMENT_SUBNET_ID"