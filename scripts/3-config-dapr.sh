# Install Dapr 
wget -q https://raw.githubusercontent.com/dapr/cli/master/install/install.sh -O - | /bin/bash

# Initialize Dapr
# Docker must be running on the machine where you run this command
dapr init

# Test Dapr integration locally

export API_APP_PORT=<web api https port in Properties->launchSettings.json (e.g. 7112)>
export UI_APP_PORT=<web ui https port in Properties->launchSettings.json (e.g. 7000)>

export FRONTEND_UI_BASE_URL_LOCAL="https://localhost:$UI_APP_PORT"

cd $PROJECT_ROOT/TasksTracker.TasksManager.Backend.Api

dapr run \
--app-id tasksmanager-backend-api \
--app-port $API_APP_PORT \
--dapr-http-port 3500 \
--scheduler-host-address "" \
--app-ssl \
-- dotnet run --launch-profile https

cd $PROJECT_ROOT/TasksTracker.WebPortal.Frontend.Ui

dapr run \
--app-id tasksmanager-frontend-webapp \
--app-port $UI_APP_PORT \
--dapr-http-port 3501 \
--scheduler-host-address "" \
--app-ssl \
-- dotnet run --launch-profile https