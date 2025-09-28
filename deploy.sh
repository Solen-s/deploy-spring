#!/bin/bash

# deploy.sh
# Usage: ./deploy.sh <git-repo-url> [branch]
# Example: ./deploy.sh https://github.com/user/project.git main

# --- Ensure Git, Maven, and Java are in PATH ---
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# --- Check required commands ---
for cmd in git java mvn; do
  if ! command -v $cmd &> /dev/null; then
    echo "Error: $cmd is not installed or not in PATH."
    exit 1
  fi
done

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

# --- Check if Maven is installed ---
if ! command -v mvn &> /dev/null; then
  echo "Maven not found. Installing Maven..."

  # Detect package manager
  if command -v apt-get &> /dev/null; then
    sudo apt-get update -y
    sudo apt-get install -y maven
  elif command -v yum &> /dev/null; then
    sudo yum install -y maven
  elif command -v dnf &> /dev/null; then
    sudo dnf install -y maven
  elif command -v brew &> /dev/null; then
    brew install maven
  else
    echo "Error: Package manager not found. Please install Maven manually."
    exit 1
  fi
else
  echo "Maven found: $(mvn -v)"
fi

# --- Build project ---
echo "Building project with Maven..."
if [ -f "./mvnw" ]; then
    chmod +x ./mvnw
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