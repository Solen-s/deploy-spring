#!/bin/bash

# Usage: ./deploy.sh <git-repo-url> [branch] [port]
# Example: ./deploy.sh https://github.com/user/my-spring-app.git main 9090

echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"

if [ -z "$1" ]; then
  echo "Usage: $0 <git-repo-url> [branch] [port]"
  exit 1
fi

GIT_REPO=$1
BRANCH=${2:-main}
PORT=${3:-8080}
APP_NAME=$(basename "$GIT_REPO" .git)
DEPLOY_DIR="/home/$USER/spring_apps/$APP_NAME"

APP_NAME_LOWER=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_.-]/-/g')
if [[ ! "$APP_NAME_LOWER" =~ ^[a-z] ]]; then
  APP_NAME_LOWER="app-$APP_NAME_LOWER"
fi

echo "=== Deploying $APP_NAME on branch '$BRANCH' to port $PORT ==="

# -----------------------------
# 1️⃣ Prepare Postgres container
# -----------------------------
POSTGRES_CONTAINER="spring-postgres"
POSTGRES_IMAGE="postgres:15"
POSTGRES_DB="spring_security_db"
POSTGRES_USER="postgres"
POSTGRES_PASSWORD="Solen@123"
POSTGRES_PORT=5432

# Check if Postgres container exists
if ! docker ps -a --format '{{.Names}}' | grep -q "^${POSTGRES_CONTAINER}$"; then
    echo "⚡ Creating Postgres container..."
    docker run -d \
      --name "$POSTGRES_CONTAINER" \
      -e POSTGRES_DB="$POSTGRES_DB" \
      -e POSTGRES_USER="$POSTGRES_USER" \
      -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
      -p "$POSTGRES_PORT:$POSTGRES_PORT" \
      "$POSTGRES_IMAGE" || { echo "❌ Failed to start Postgres"; exit 1; }
else
    echo "⚡ Postgres container already exists. Starting it..."
    docker start "$POSTGRES_CONTAINER"
fi

# Wait a few seconds for Postgres to be ready
echo "⏳ Waiting for Postgres to initialize..."
sleep 10

# -----------------------------
# 2️⃣ Clean previous deployment
# -----------------------------
echo "[1/4] Cleaning previous deployment..."
if [ -d "$DEPLOY_DIR" ]; then
    echo "⚠️ Removing old app directory: $DEPLOY_DIR"
    rm -rf "$DEPLOY_DIR"
fi
mkdir -p "$DEPLOY_DIR"

# -----------------------------
# 3️⃣ Clone repo
# -----------------------------
echo "[2/4] Cloning repository..."
git clone -b "$BRANCH" "$GIT_REPO" "$DEPLOY_DIR" || { echo "❌ Git clone failed"; exit 1; }
cd "$DEPLOY_DIR" || { echo "❌ Failed to enter $DEPLOY_DIR"; exit 1; }
echo "✅ Repository cloned successfully."

# -----------------------------
# 4️⃣ Build Docker image
# -----------------------------
echo "[3/4] Building Docker image..."
IMAGE_NAME="${APP_NAME_LOWER}:latest"
docker build -t "$IMAGE_NAME" . || { echo "❌ Docker build failed"; exit 1; }
echo "✅ Docker image built: $IMAGE_NAME"

# -----------------------------
# 5️⃣ Run Spring Boot container
# -----------------------------
CONTAINER_NAME="${APP_NAME_LOWER}-con"
echo "[4/4] Starting container..."
docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true

docker run -d \
  -e SERVER_PORT="$PORT" \
  -e SPRING_DATASOURCE_URL="jdbc:postgresql://$POSTGRES_CONTAINER:$POSTGRES_PORT/$POSTGRES_DB" \
  -e SPRING_DATASOURCE_USERNAME="$POSTGRES_USER" \
  -e SPRING_DATASOURCE_PASSWORD="$POSTGRES_PASSWORD" \
  -p "$PORT:$PORT" \
  --link "$POSTGRES_CONTAINER" \
  --name "$CONTAINER_NAME" \
  "$IMAGE_NAME" || { echo "❌ Failed to run container"; exit 1; }

docker ps

echo "✅ Deployment successful!"
echo "👉 App running at: http://$(hostname -I | awk '{print $1}'):$PORT"
echo "💻 Swagger UI (if available): http://$(hostname -I | awk '{print $1}'):$PORT/swagger-ui/index.html"

# -----------------------------
# 6️⃣ Test endpoint
# -----------------------------
echo "🌐 Testing endpoint..."
curl -I "http://localhost:$PORT" || echo "❌ Failed to reach app"
