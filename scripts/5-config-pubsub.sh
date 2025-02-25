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