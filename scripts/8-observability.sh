
# Add Application Insights key to the secrets of the container apps
az containerapp secret set \
  --name $BACKEND_API_NAME \
  --resource-group $RESOURCE_GROUP \
  --secrets "appinsights-key=$APPINSIGHTS_INSTRUMENTATIONKEY"

az containerapp secret set \
  --name $FRONTEND_WEBAPP_NAME \
  --resource-group $RESOURCE_GROUP \
  --secrets "appinsights-key=$APPINSIGHTS_INSTRUMENTATIONKEY"

az containerapp secret set \
  --name $BACKEND_SERVICE_NAME \
  --resource-group $RESOURCE_GROUP \
  --secrets "appinsights-key=$APPINSIGHTS_INSTRUMENTATIONKEY"
