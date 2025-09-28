# Dockerfile
FROM openjdk:17-jdk-slim
WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y bash git maven && rm -rf /var/lib/apt/lists/*

# Copy Spring jar and deploy script
COPY target/my-spring-app.jar .
COPY deploy.sh .
RUN chmod +x deploy.sh

# Spring Boot stays alive; deploy.sh is called by Spring
CMD ["java", "-jar", "my-spring-app.jar"]
