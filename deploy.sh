#!/bin/bash
# deploy.sh
# Usage: ./deploy.sh <git-repo-url> [branch]
# Example: ./deploy.sh https://github.com/user/project.git main

set -e

# --- Input arguments ---
GIT_REPO=$1
BRANCH=${2:-main}  # Default branch is 'main'

if [ -z "$GIT_REPO" ]; then
  echo "Error: Git repository URL is required."
  exit 1
fi

# --- Extract project name ---
PROJECT_NAME=$(basename "$GIT_REPO" .git)

# --- Clone or update repo ---
if [ -d "$PROJECT_NAME" ]; then
  echo "Repository $PROJECT_NAME exists. Pulling latest changes..."
  cd "$PROJECT_NAME" || exit
  git fetch
  git checkout "$BRANCH"
  git pull origin "$BRANCH"
else
  echo "Cloning repository $GIT_REPO ..."
  git clone -b "$BRANCH" "$GIT_REPO"
  cd "$PROJECT_NAME" || exit
fi

# --- Build project ---
echo "Building project with Maven..."
if [ -f "./mvnw" ]; then
  chmod +x ./mvnw
  ./mvnw clean package -DskipTests
else
  mvn clean package -DskipTests
fi

# --- Stop existing application safely ---
JAR_FILE=$(ls target/*.jar | head -n 1)
if [ -z "$JAR_FILE" ]; then
  echo "Error: No JAR file found in target/"
  exit 1
fi

APP_PID=$(pgrep -f "$JAR_FILE" || true)
if [ -n "$APP_PID" ]; then
  echo "Stopping existing application (PID $APP_PID)..."
  kill -9 $APP_PID
  sleep 2  # allow port to free
fi

# --- Run application ---
echo "Starting application..."
nohup java -jar "$JAR_FILE" > app.log 2>&1 &

echo "Deployment completed successfully!"
echo "Logs are in $(pwd)/app.log"
