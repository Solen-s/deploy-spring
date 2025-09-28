# Use OpenJDK 17 slim as base
FROM openjdk:17-jdk-slim

# Set working directory inside container
WORKDIR /app

# Install bash, git, and maven
RUN apt-get update && \
    apt-get install -y bash git maven && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy deploy script and make it executable
COPY deploy.sh .
RUN chmod +x deploy.sh

# Optionally copy Maven wrapper and project files for caching dependencies
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Pre-download Maven dependencies (optional, speeds up builds)
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B

# Default command to run deploy script (pass git repo and branch as args)
CMD ["./deploy.sh"]
