#!/bin/bash

# deploy.sh
# Usage: ./deploy.sh <git-repo-url> [branch]

# --- Ensure basic PATH ---
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# --- Input arguments ---
GIT_REPO=$1
BRANCH=${2:-main}

if [ -z "$GIT_REPO" ]; then
  echo "Error: Git repository URL is required."
  exit 1
fi

# --- Commands with full path ---
GIT_CMD=/usr/bin/git
MVN_CMD=mvn
JAVA_CMD=java

# --- Extract project name ---
PROJECT_NAME=$(basename "$GIT_REPO" .git)

# --- Clone or update repo ---
if [ -d "$PROJECT_NAME" ]; then
  echo "Repository $PROJECT_NAME already exists. Pulling latest changes..."
  cd "$PROJECT_NAME" || exit
  $GIT_CMD fetch
  $GIT_CMD checkout "$BRANCH"
  $GIT_CMD pull origin "$BRANCH"
else
  echo "Cloning repository $GIT_REPO ..."
  $GIT_CMD clone -b "$BRANCH" "$GIT_REPO"
  cd "$PROJECT_NAME" || exit
fi

# --- Build project ---
echo "Building project with Maven..."
if [ -f "./mvnw" ]; then
  ./mvnw clean package -DskipTests
else
  $MVN_CMD clean package -DskipTests
fi

# --- Stop existing application ---
APP_PID=$(pgrep -f "$PROJECT_NAME")
if [ -n "$APP_PID" ]; then
  echo "Stopping existing application (PID $APP_PID)..."
  kill -9 "$APP_PID"
fi

# --- Run application ---
echo "Starting application..."
nohup $JAVA_CMD -jar target/*.jar > app.log 2>&1 &

echo "Deployment completed successfully!"
echo "Logs are in $PROJECT_NAME/app.log"
