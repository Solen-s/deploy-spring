#!/bin/bash

# ===========================
# Spring Boot Deployment Script
# Usage: ./deploy.sh <git-repo-url> [branch] [port]
# Example: ./deploy.sh https://github.com/user/my-spring-app.git main 9090
# ===========================

echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"

# -----------------------------
# Arguments
# -----------------------------
if [ -z "$1" ]; then
  echo "Usage: $0 <git-repo-url> [branch] [port]"
  exit 1
fi

GIT_REPO=$1
BRANCH=${2:-main}       # default: main
PORT=${3:-8080}         # default: 8080

# -----------------------------
# App and Deployment Directories
# -----------------------------
APP_NAME=$(basename "$GIT_REPO" .git)
DEPLOY_DIR="/home/$USER/spring_apps/$APP_NAME"

# Docker image name: lowercase, remove invalid characters
APP_NAME_LOWER=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_.-]/-/g')

# Ensure image name starts with a letter
if [[ ! "$APP_NAME_LOWER" =~ ^[a-z] ]]; then
  APP_NAME_LOWER="app-$APP_NAME_LOWER"
fi

IMAGE_NAME="${APP_NAME_LOWER}:latest"
CONTAINER_NAME="${APP_NAME_LOWER}-con"

echo "=== Deploying $APP_NAME on branch '$BRANCH' to port $PORT ==="

# -----------------------------
# Step 1: Clean previous deployment
# -----------------------------
echo "[1/4] Cleaning previous deployment..."
if [ -d "$DEPLOY_DIR" ]; then
  echo "⚠️ Removing old app directory: $DEPLOY_DIR"
  rm -rf "$DEPLOY_DIR"
fi
mkdir -p "$DEPLOY_DIR"

# -----------------------------
# Step 2: Clone repository
# -----------------------------
echo "[2/4] Cloning repository..."
git clone -b "$BRANCH" "$GIT_REPO" "$DEPLOY_DIR" || { echo "❌ Git clone failed"; exit 1; }
cd "$DEPLOY_DIR" || { echo "❌ Failed to enter $DEPLOY_DIR"; exit 1; }
echo "✅ Repository cloned successfully."

# -----------------------------
# Step 3: Build Docker image
# -----------------------------
echo "[3/4] Building Docker image..."
docker build -t "$IMAGE_NAME" . || { echo "❌ Docker build failed"; exit 1; }
echo "✅ Docker image built: $IMAGE_NAME"

# -----------------------------
# Step 4: Stop old container and run new one
# -----------------------------
echo "[4/4] Starting container..."
docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true

docker run -d \
  -p "$PORT:$PORT" \
  -e SERVER_PORT="$PORT" \
  --name "$CONTAINER_NAME" \
  "$IMAGE_NAME"

if [ $? -eq 0 ]; then
  echo "✅ Deployment successful!"
  echo "👉 App running at: http://$(hostname -I | awk '{print $1}'):$PORT"
  echo "💻 You can test Swagger UI at: http://$(hostname -I | awk '{print $1}'):$PORT/swagger-ui/index.html"
else
  echo "❌ Deployment failed."
  exit 1
fi
