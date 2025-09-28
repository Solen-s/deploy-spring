#!/bin/bash

# Check if git URL is provided
if [ -z "$1" ]; then
  echo "Usage: ./deploy_spring.sh <git-repo-url>"
  exit 1
fi

GIT_REPO=$1
APP_NAME=$(basename "$GIT_REPO" .git)
DEPLOY_DIR="/opt/spring_apps/$APP_NAME"

echo "Cloning repository..."
# Remove old folder if exists
rm -rf "$DEPLOY_DIR"
git clone "$GIT_REPO" "$DEPLOY_DIR" || { echo "Git clone failed"; exit 1; }

cd "$DEPLOY_DIR" || exit 1

echo "Building project with Maven..."
# Make sure Maven is installed
mvn clean package -DskipTests || { echo "Maven build failed"; exit 1; }

# Find the generated jar
JAR_FILE=$(find target -name "*.jar" | head -n 1)
if [ -z "$JAR_FILE" ]; then
  echo "No jar file found"
  exit 1
fi

echo "Stopping old application (if running)..."
# Kill old process if exists
PID=$(pgrep -f "$JAR_FILE")
if [ ! -z "$PID" ]; then
  kill -9 $PID
fi

echo "Starting new application..."
nohup java -jar "$JAR_FILE" > "$DEPLOY_DIR/app.log" 2>&1 &

echo "Deployment complete. Logs at $DEPLOY_DIR/app.log"
