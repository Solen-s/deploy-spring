#!/bin/bash

# --- Absolute path to git ---
GIT_CMD=/usr/bin/git

# --- Input arguments ---
GIT_REPO=$1
BRANCH=${2:-main}

if [ -z "$GIT_REPO" ]; then
    echo "Error: Git repository URL is required."
    exit 1
fi

GIT_CMD=$(which git || true)
if [ -z "$GIT_CMD" ]; then
    echo "Error: git not found! Install git in this environment."
    exit 1
fi

# --- Extract project name ---
PROJECT_NAME=$(basename "$GIT_REPO" .git)

# --- Clone or update repo ---
if [ -d "$PROJECT_NAME" ]; then
    echo "Repository '$PROJECT_NAME' exists. Pulling latest changes..."
    cd "$PROJECT_NAME" || exit
    $GIT_CMD fetch
    $GIT_CMD checkout "$BRANCH"
    $GIT_CMD pull origin "$BRANCH"
else
    echo "Cloning repository '$GIT_REPO' (branch: $BRANCH)..."
    $GIT_CMD clone -b "$BRANCH" "$GIT_REPO"
fi

echo "Repository ready at $(pwd)/$PROJECT_NAME"
