#!/bin/bash

echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"

# -----------------------------
# Usage: ./deploy.sh <git-repo-url> [branch] [port]
# Example: ./deploy.sh https://github.com/user/my-spring-app.git main 9090
# -----------------------------

if [ -z "$1" ]; then
  echo "Usage: $0 <git-repo-url> [branch] [port]"
  exit 1
fi

GIT_REPO=$1
BRANCH=${2:-main}     # Default branch = main
PORT=${3:-8080}       # Default port = 8080
APP_NAME=$(basename "$GIT_REPO" .git)

# Directory for deployment
DEPLOY_DIR="/home/$USER/spring_apps/$APP_NAME"

# Docker image name: lowercase, remove invalid characters
APP_NAME_LOWER=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_.-]/-/g')

# Ensure image name starts with a letter
if [[ ! "$APP_NAME_LOWER" =~ ^[a-z] ]]; then
  APP_NAME_LOWER="app-$APP_NAME_LOWER"
fi

echo "=== Starting deployment of $APP_NAME on branch '$BRANCH' on port $PORT ==="

# ----------------------------- Clean old project -----------------------------
echo "[1/4] Cleaning previous deployment..."
if [ -d "$DEPLOY_DIR" ]; then
    echo "⚠️ Removing old app directory: $DEPLOY_DIR"
    rm -rf "$DEPLOY_DIR"
fi
mkdir -p "$DEPLOY_DIR"

# ----------------------------- Clone repo -----------------------------
echo "[2/4] Cloning repository..."
git clone -b "$BRANCH" "$GIT_REPO" "$DEPLOY_DIR" || { echo "❌ Git clone failed"; exit 1; }
cd "$DEPLOY_DIR" || { echo "❌ Failed to enter $DEPLOY_DIR"; exit 1; }

# ----------------------------- Build Docker image -----------------------------
echo "[3/4] Building Docker image..."
IMAGE_NAME="${APP_NAME_LOWER}:latest"
docker build -t "$IMAGE_NAME" . || { echo "❌ Docker build failed"; exit 1; }

# ----------------------------- Stop & run container -----------------------------
echo "[4/4] Starting container..."
docker stop "$APP_NAME_LOWER" >/dev/null 2>&1 || true
docker rm "$APP_NAME_LOWER" >/dev/null 2>&1 || true

docker run -d -p "$PORT:$PORT" --name "$APP_NAME_LOWER" "$IMAGE_NAME"

if [ $? -eq 0 ]; then
  echo "✅ Deployment successful!"
  echo "👉 App running at: http://$(hostname -I | awk '{print $1}'):$PORT"
else
  echo "❌ Deployment failed."
  exit 1
fi
