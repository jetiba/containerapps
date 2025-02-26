export SERVICE_BUS_NAMESPACE_NAME="sbns-taskstracker-$RANDOM_STRING"
export SERVICE_BUS_TOPIC_NAME="tasksavedtopic"
export SERVICE_BUS_TOPIC_SUBSCRIPTION="sbts-tasks-processor"

# Create servicebus namespace
az servicebus namespace create --resource-group $RESOURCE_GROUP --name $SERVICE_BUS_NAMESPACE_NAME --location $LOCATION --sku Standard

# Create a topic under the namespace
az servicebus topic create --resource-group $RESOURCE_GROUP --namespace-name $SERVICE_BUS_NAMESPACE_NAME --name $SERVICE_BUS_TOPIC_NAME

# Create a topic subscription
az servicebus topic subscription create \
  --resource-group $RESOURCE_GROUP \
  --namespace-name $SERVICE_BUS_NAMESPACE_NAME \
  --topic-name $SERVICE_BUS_TOPIC_NAME \
  --name $SERVICE_BUS_TOPIC_SUBSCRIPTION

# List connection string
az servicebus namespace authorization-rule keys list \
  --resource-group $RESOURCE_GROUP \
  --namespace-name $SERVICE_BUS_NAMESPACE_NAME \
  --name RootManageSharedAccessKey \
  --query primaryConnectionString \
  --output tsv

export BACKEND_SERVICE_NAME="tasksmanager-backend-processor"

az acr build \
  --registry $AZURE_CONTAINER_REGISTRY_NAME \
  --image "tasksmanager/$BACKEND_API_NAME" \
  --file "TasksTracker.TasksManager.Backend.Api/Dockerfile" .

az acr build \
  --registry $AZURE_CONTAINER_REGISTRY_NAME \
  --image "tasksmanager/$BACKEND_SERVICE_NAME" \
  --file "TasksTracker.Processor.Backend.Svc/Dockerfile" .

# create Container Apps for the backend service
az containerapp create \
  --name "$BACKEND_SERVICE_NAME"  \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT \
  --image "$AZURE_CONTAINER_REGISTRY_NAME.azurecr.io/tasksmanager/$BACKEND_SERVICE_NAME" \
  --registry-server "$AZURE_CONTAINER_REGISTRY_NAME.azurecr.io" \
  --min-replicas 1 \
  --max-replicas 1 \
  --cpu 0.25 \
  --memory 0.5Gi \
  --enable-dapr \
  --dapr-app-id $BACKEND_SERVICE_NAME \
  --dapr-app-port $TARGET_PORT

# Update Backend API App container app and create a new revision
az containerapp update \
  --name $BACKEND_API_NAME \
  --resource-group $RESOURCE_GROUP \
  --revision-suffix v$TODAY-2

# Configure ACA environment to use the service bus
az containerapp env dapr-component set \
  --name $ENVIRONMENT \
  --resource-group $RESOURCE_GROUP \
  --dapr-component-name dapr-pubsub-servicebus \
  --yaml './aca-components/containerapps-pubsub-svcbus.yaml'

# Configure Managed Identity for the backend service container app
az containerapp identity assign \
  --resource-group $RESOURCE_GROUP \
  --name $BACKEND_SERVICE_NAME \
  --system-assigned

export BACKEND_SVC_PRINCIPAL_ID=$(az containerapp identity show \
  --name $BACKEND_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP \
  --query principalId \
  --output tsv)

# Assign role to the managed identity to access the service bus
export SVC_BUS_DATA_RECEIVER_ROLE="Azure Service Bus Data Receiver" # Built in role name

az role assignment create \
  --assignee $BACKEND_SVC_PRINCIPAL_ID \
  --role "$SVC_BUS_DATA_RECEIVER_ROLE" \
  --scope /subscriptions/$AZURE_SUBSCRIPTION_ID/resourcegroups/$RESOURCE_GROUP/providers/Microsoft.ServiceBus/namespaces/$SERVICE_BUS_NAMESPACE_NAME/topics/$SERVICE_BUS_TOPIC_NAME

# Grant backend API the data sender role
export SVC_BUS_DATA_SENDER_ROLE="Azure Service Bus Data Sender" # Built in role name

az role assignment create \
  --assignee $BACKEND_API_PRINCIPAL_ID \
  --role "$SVC_BUS_DATA_SENDER_ROLE" \
  --scope /subscriptions/$AZURE_SUBSCRIPTION_ID/resourcegroups/$RESOURCE_GROUP/providers/Microsoft.ServiceBus/namespaces/$SERVICE_BUS_NAMESPACE_NAME/topics/$SERVICE_BUS_TOPIC_NAME

# Get revision name and assign it to a variable
export BACKEND_SERVICE_REVISION_NAME=$(az containerapp revision list \
  --name $BACKEND_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "[0].name" \
  --output tsv)

# Restart revision by name
az containerapp revision restart \
  --resource-group $RESOURCE_GROUP \
  --name $BACKEND_SERVICE_NAME  \
  --revision $BACKEND_SERVICE_REVISION_NAME

export BACKEND_API_REVISION_NAME=$(az containerapp revision list \
  --name $BACKEND_API_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "[0].name" \
  --output tsv)

# Restart revision by name
az containerapp revision restart \
  --resource-group $RESOURCE_GROUP \
  --name $BACKEND_API_NAME  \
  --revision $BACKEND_API_REVISION_NAME