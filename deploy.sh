#!/bin/bash

# deploy.sh
# Usage: ./deploy.sh <git-repo-url> [branch]
# Example: ./deploy.sh https://github.com/user/project.git main

# --- Input arguments ---
GIT_REPO=$1
BRANCH=${2:-main}  # Default branch is 'main' if not provided

if [ -z "$GIT_REPO" ]; then
  echo "Error: Git repository URL is required."
  exit 1
fi

# --- Extract project name ---
PROJECT_NAME=$(basename "$GIT_REPO" .git)

# --- Clone or update repo ---
if [ -d "$PROJECT_NAME" ]; then
  echo "Repository $PROJECT_NAME already exists. Pulling latest changes..."
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
  ./mvnw clean package -DskipTests
else
  mvn clean package -DskipTests
fi

# --- Stop existing application ---
APP_PID=$(pgrep -f "$PROJECT_NAME")
if [ -n "$APP_PID" ]; then
  echo "Stopping existing application (PID $APP_PID)..."
  kill -9 "$APP_PID"
fi

# --- Run application ---
echo "Starting application..."
nohup java -jar target/*.jar > app.log 2>&1 &

echo "Deployment completed successfully!"
echo "Logs are in $PROJECT_NAME/app.log"
