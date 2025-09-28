#!/bin/bash

# -----------------------------
# Usage: ./deploy_spring.sh <git-repo-url> [port]
# -----------------------------
if [ -z "$1" ]; then
  echo "Usage: ./deploy_spring.sh <git-repo-url> [port]"
  exit 1
fi

GIT_REPO=$1
PORT=${2:-9090}           # Optional port, default 8080
APP_NAME=$(basename "$GIT_REPO" .git)
DEPLOY_DIR="/opt/spring_apps/$APP_NAME"

echo "=== Starting deployment of $APP_NAME ==="

# Ensure deploy directory exists
mkdir -p /opt/spring_apps

# Remove old folder if exists
echo "Cleaning previous deployment..."
rm -rf "$DEPLOY_DIR"

# Clone repo
echo "Cloning repository from $GIT_REPO..."
git clone "$GIT_REPO" "$DEPLOY_DIR" || { echo "Git clone failed"; exit 1; }

cd "$DEPLOY_DIR" || exit 1


# Check application.properties
if [ -f "src/main/resources/application.properties" ]; then
  PROP_PORT=$(grep -E "^server.port" src/main/resources/application.properties | cut -d'=' -f2 | tr -d ' ')
  if [ ! -z "$PROP_PORT" ]; then
    PORT=$PROP_PORT
    echo "Detected server.port in application.properties: $PORT"
  fi
fi

# Check application.yml
if [ -f "src/main/resources/application.yml" ]; then
  YML_PORT=$(grep -E "^\s*port:" src/main/resources/application.yml | head -n1 | awk '{print $2}')
  if [ ! -z "$YML_PORT" ]; then
    PORT=$YML_PORT
    echo "Detected server.port in application.yml: $PORT"
  fi
fi


# Build project
echo "Building project with Maven..."
mvn clean package -DskipTests || { echo "Maven build failed"; exit 1; }

# Find jar
JAR_FILE=$(find target -name "*.jar" | head -n 1)
if [ -z "$JAR_FILE" ]; then
  echo "No jar file found"
  exit 1
fi
echo "Jar file found: $JAR_FILE"

# Stop old process
echo "Stopping old application if running..."
PID=$(pgrep -f "$JAR_FILE")
if [ ! -z "$PID" ]; then
  kill -9 $PID
  echo "Stopped old process $PID"
fi

# Start new app
echo "Starting new application on port $PORT..."
nohup java -jar "$JAR_FILE" --server.port=$PORT > "$DEPLOY_DIR/app.log" 2>&1 &

sleep 5   # wait a few seconds to let app start

# Test if app is running
if curl -s "http://localhost:$PORT/swagger-ui/index.html" | grep -q "UP"; then
  echo "Deployment successful! App is running on port $PORT"
else
  echo "Deployment may have failed. Check logs at $DEPLOY_DIR/app.log"
fi
