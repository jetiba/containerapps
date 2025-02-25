# Update backend API ACA ingress to be accessible only from other applications deployed in the same ACA environment
fqdn=$(az containerapp ingress enable \
  --name "$BACKEND_API_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --target-port "$TARGET_PORT" \
  --type internal \
  --query fqdn \
  --output tsv)

export BACKEND_API_INTERNAL_BASE_URL="https://$fqdn"

echo "The internal backend API URL:"
echo "$BACKEND_API_INTERNAL_BASE_URL"