# Build the backend API image
az acr build \
--registry "$AZURE_CONTAINER_REGISTRY_NAME" \
--image "tasksmanager/$BACKEND_API_NAME" \
--file "TasksTracker.TasksManager.Backend.Api/Dockerfile" .

# Deploy the backend API on Azure Container Apps
fqdn=$(az containerapp create \
--name "$BACKEND_API_NAME" \
--resource-group "$RESOURCE_GROUP" \
--environment "$ENVIRONMENT" \
--image "$AZURE_CONTAINER_REGISTRY_NAME.azurecr.io/tasksmanager/$BACKEND_API_NAME" \
--registry-server "$AZURE_CONTAINER_REGISTRY_NAME.azurecr.io" \
--target-port "$TARGET_PORT" \
--ingress external \
--min-replicas 1 \
--max-replicas 1 \
--cpu 0.25 \
--memory 0.5Gi \
--query properties.configuration.ingress.fqdn \
--output tsv)

export BACKEND_API_EXTERNAL_BASE_URL="https://$fqdn"

echo "See a listing of tasks created by the author at this URL:"
echo "https://$fqdn/api/tasks/?createdby=tjoudeh@bitoftech.net"

# Build the Frontend UI image
az acr build \
--registry "$AZURE_CONTAINER_REGISTRY_NAME" \
--image "tasksmanager/$FRONTEND_WEBAPP_NAME" \
--file "TasksTracker.WebPortal.Frontend.Ui/Dockerfile" .

# Deploy the Frontend UI on Azure Container Apps
fqdn=$(az containerapp create \
  --name "$FRONTEND_WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --environment "$ENVIRONMENT" \
  --image "$AZURE_CONTAINER_REGISTRY_NAME.azurecr.io/tasksmanager/$FRONTEND_WEBAPP_NAME" \
  --registry-server "$AZURE_CONTAINER_REGISTRY_NAME.azurecr.io" \
  --env-vars "BackendApiConfig__BaseUrlExternalHttp=$BACKEND_API_EXTERNAL_BASE_URL/" \
  --target-port "$TARGET_PORT" \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 1 \
  --cpu 0.25 \
  --memory 0.5Gi \
  --query properties.configuration.ingress.fqdn \
  --output tsv)

export FRONTEND_UI_BASE_URL="https://$fqdn"

echo "See the frontend web app at this URL:"
echo "$FRONTEND_UI_BASE_URL"

