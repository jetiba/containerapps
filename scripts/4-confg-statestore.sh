# On Windows, in the folder \\wsl$\Ubuntu\home\[user]\.dapr\components are stored the properties for access the local Redis instance

# Provision CosmosDB on Azure
az provider register --namespace 'Microsoft.DocumentDB'

export COSMOS_DB_ACCOUNT="cosmos-tasks-tracker-state-store-$RANDOM_STRING"
export COSMOS_DB_DBNAME="tasksmanagerdb"
export COSMOS_DB_CONTAINER="taskscollection"

# Check if Cosmos account name already exists globally
result=$(az cosmosdb check-name-exists --name "$COSMOS_DB_ACCOUNT")

# Continue if the Cosmos DB account does not yet exist
if [ "$result" = "false" ]; then
    echo "Creating Cosmos DB account. This may take a few minutes..."

    # Create a Cosmos account for SQL API
    az cosmosdb create \
     --name "$COSMOS_DB_ACCOUNT" \
     --resource-group "$RESOURCE_GROUP"

    # Enable local authentication to avoid a 401 when running locally.
    az resource update \
     --name "$COSMOS_DB_ACCOUNT" \
     --resource-group "$RESOURCE_GROUP" \
     --resource-type "Microsoft.DocumentDB/databaseAccounts" \
     --set properties.disableLocalAuth=false

    # Create a SQL API database
    az cosmosdb sql database create \
     --name "$COSMOS_DB_DBNAME" \
     --resource-group "$RESOURCE_GROUP" \
     --account-name "$COSMOS_DB_ACCOUNT"

    # Create a SQL API container
    az cosmosdb sql container create \
     --name "$COSMOS_DB_CONTAINER" \
     --resource-group "$RESOURCE_GROUP" \
     --account-name "$COSMOS_DB_ACCOUNT" \
     --database-name "$COSMOS_DB_DBNAME" \
     --partition-key-path "/id" \
     --throughput 400

    export COSMOS_DB_ENDPOINT=$(az cosmosdb show \
     --name "$COSMOS_DB_ACCOUNT" \
     --resource-group "$RESOURCE_GROUP" \
     --query documentEndpoint \
     --output tsv)

    echo "Cosmos DB Endpoint: "
    echo "$COSMOS_DB_ENDPOINT"
fi

# Local test
cd $PROJECT_ROOT/TasksTracker.TasksManager.Backend.Api

dapr run \
--app-id tasksmanager-backend-api \
--app-port $API_APP_PORT \
--dapr-http-port 3500 \
--app-ssl \
--scheduler-host-address "" \
--resources-path "../components" \
-- dotnet run --launch-profile https

cd $PROJECT_ROOT/TasksTracker.WebPortal.Frontend.Ui

dapr run \
--app-id tasksmanager-frontend-webapp \
--app-port $UI_APP_PORT \
--dapr-http-port 3501 \
--scheduler-host-address "" \
--app-ssl \
-- dotnet run --launch-profile https

# configure system managed identity for the backend API to access CosmosDB
az containerapp identity assign \
 --name "$BACKEND_API_NAME" \
 --resource-group "$RESOURCE_GROUP" \
 --system-assigned

export BACKEND_API_PRINCIPAL_ID=$(az containerapp identity show \
 --name "$BACKEND_API_NAME" \
 --resource-group "$RESOURCE_GROUP" \
 --query principalId \
 --output tsv)

# Assign role to the managed identity to access CosmosDB
export ROLE_ID="00000000-0000-0000-0000-000000000002" # "Cosmos DB Built-in Data Contributor"

az cosmosdb sql role assignment create \
 --resource-group "$RESOURCE_GROUP" \
 --account-name "$COSMOS_DB_ACCOUNT" \
 --scope "/" \
 --principal-id "$BACKEND_API_PRINCIPAL_ID" \
 --role-definition-id "$ROLE_ID"

# Update the configuration of ACA Environment
az containerapp env dapr-component set \
 --name "$ENVIRONMENT" \
 --resource-group "$RESOURCE_GROUP" \
 --dapr-component-name statestore \
 --yaml './aca-components/containerapps-statestore-cosmos.yaml'

# Enable Dapr for the backend and frontend Container Apps
az containerapp dapr enable \
 --name "$BACKEND_API_NAME" \
 --resource-group "$RESOURCE_GROUP" \
 --dapr-app-id "$BACKEND_API_NAME" \
 --dapr-app-port "$TARGET_PORT"

az containerapp dapr enable \
 --name "$FRONTEND_WEBAPP_NAME" \
 --resource-group "$RESOURCE_GROUP" \
 --dapr-app-id "$FRONTEND_WEBAPP_NAME" \
 --dapr-app-port "$TARGET_PORT"

# Update Frontend web app container app and create a new revision
az containerapp update \
 --name "$FRONTEND_WEBAPP_NAME" \
 --resource-group "$RESOURCE_GROUP" \
 --revision-suffix v$TODAY

# Update Backend API App container app and create a new revision
az containerapp update \
 --name "$BACKEND_API_NAME" \
 --resource-group "$RESOURCE_GROUP" \
 --revision-suffix v$TODAY-1

echo "Azure Frontend UI URL:"
echo "$FRONTEND_UI_BASE_URL"
