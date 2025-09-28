# Use OpenJDK 17 as base image
FROM eclipse-temurin:17-jdk-jammy

# Set working directory inside the container
WORKDIR /app

# Copy Maven wrapper and pom.xml first for caching
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Download dependencies (cached if pom.xml unchanged)
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B

# Copy source code
COPY src ./src

# Install git + maven
RUN apt-get update && apt-get install -y git maven && rm -rf /var/lib/apt/lists/*

# Build the Spring Boot app
RUN ./mvnw clean package -DskipTests

# Copy deploy.sh and make it executable
COPY deploy.sh .
RUN chmod +x deploy.sh

# Expose port your Spring Boot app uses
EXPOSE 8082

# Default command to run the Spring Boot app
CMD ["java", "-jar", "target/testing-deploy-0.0.1-SNAPSHOT.jar"]
