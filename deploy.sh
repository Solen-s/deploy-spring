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
BRANCH=${2:-main}   # default branch
PORT=${3:-8080}     # default port
APP_NAME=$(basename "$GIT_REPO" .git)

# Directory for deployment
DEPLOY_DIR="/home/$USER/spring_apps/$APP_NAME"

# Docker image name: lowercase, sanitize
APP_NAME_LOWER=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_.-]/-/g')
if [[ ! "$APP_NAME_LOWER" =~ ^[a-z] ]]; then
  APP_NAME_LOWER="app-$APP_NAME_LOWER"
fi

echo "=== Deploying $APP_NAME on branch '$BRANCH' to port $PORT ==="

# ----------------------------- Clean old app -----------------------------
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
echo "✅ Repository cloned successfully."

# ----------------------------- Update server.port dynamically -----------------------------
PROPERTIES_FILE="$DEPLOY_DIR/src/main/resources/application.properties"
if [ -f "$PROPERTIES_FILE" ]; then
    sed -i '/^server\.port=/d' "$PROPERTIES_FILE"
fi
echo "server.port=\${SERVER_PORT:8080}" >> "$PROPERTIES_FILE"
echo "✅ Updated server.port to use dynamic port from environment variable"

# ----------------------------- Build Docker image -----------------------------
echo "[3/4] Building Docker image..."
IMAGE_NAME="${APP_NAME_LOWER}:latest"
docker build -t "$IMAGE_NAME" . || { echo "❌ Docker build failed"; exit 1; }
echo "✅ Docker image built: $IMAGE_NAME"

# ----------------------------- Run container -----------------------------
CONTAINER_NAME="${APP_NAME_LOWER}-con"
echo "[4/4] Starting container..."
docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true

docker run -d \
  -e SERVER_PORT="$PORT" \
  -p "$PORT:$PORT" \
  --name "$CONTAINER_NAME" \
  "$IMAGE_NAME" || { echo "❌ Failed to run container"; exit 1; }

echo "✅ Deployment successful!"
echo "👉 App running at: http://$(hostname -I | awk '{print $1}'):$PORT"
echo "💻 Swagger UI (if available): http://$(hostname -I | awk '{print $1}'):$PORT/swagger-ui/index.html"

# ----------------------------- Test curl -----------------------------
echo "🌐 Testing endpoint..."
curl -I "http://localhost:$PORT" || echo "❌ Failed to reach app"
