#!/bin/bash

# clone.sh
# Usage: ./clone.sh <git-repo-url> [branch]
# Example: ./clone.sh https://github.com/user/project.git main

# --- Ensure PATH includes common bin directories ---
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
echo "Script PATH=$PATH"
which git || echo "git not found"
# --- Locate Git ---
GIT_CMD=$(which git)
if [ -z "$GIT_CMD" ]; then
    echo "Error: git not found! Please install git."
    exit 1
fi
echo "Using Git at $GIT_CMD"

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
    echo "Repository '$PROJECT_NAME' already exists. Pulling latest changes..."
    cd "$PROJECT_NAME" || exit
    $GIT_CMD fetch
    $GIT_CMD checkout "$BRANCH"
    $GIT_CMD pull origin "$BRANCH"
else
    echo "Cloning repository '$GIT_REPO' (branch: $BRANCH)..."
    $GIT_CMD clone -b "$BRANCH" "$GIT_REPO"
fi

echo "Repository is ready at $(pwd)/$PROJECT_NAME"
