# https://azure.github.io/aca-dotnet-workshop/aca/09-aca-autoscale-keda/

# List Service Bus Access Policy RootManageSharedAccessKey
export SERVICE_BUS_CONNECTION_STRING=$(az servicebus namespace authorization-rule keys list \
  --name RootManageSharedAccessKey \
  --resource-group $RESOURCE_GROUP \
  --namespace-name $SERVICE_BUS_NAMESPACE_NAME \
  --query primaryConnectionString \
  --output tsv)

# Create a new secret named 'svcbus-connstring' in backend processor container app
az containerapp secret set \
  --name $BACKEND_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP \
  --secrets "svcbus-connstring=$SERVICE_BUS_CONNECTION_STRING"

# TODO: This could be also done using Managed Identity or AKV?

# Adding scaling rule to the backend processor container app
az containerapp update \
  --name $BACKEND_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP \
  --min-replicas 0 \
  --max-replicas 5 \
  --revision-suffix v$TODAY-6 \
  --scale-rule-name "topic-msgs-length" \
  --scale-rule-type "azure-servicebus" \
  --scale-rule-auth "connection=svcbus-connstring" \
  --scale-rule-metadata "topicName=$SERVICE_BUS_TOPIC_NAME" \
                    "subscriptionName=$SERVICE_BUS_TOPIC_SUBSCRIPTION" \
                    "namespace=$SERVICE_BUS_NAMESPACE_NAME" \
                    "messageCount=10" \
                    "connectionFromEnv=svcbus-connstring"