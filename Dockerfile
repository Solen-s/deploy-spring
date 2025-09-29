# -----------------------------
# Stage 1: Build the project
# -----------------------------
FROM maven:3.9.2-eclipse-temurin-17 AS build

WORKDIR /app

# Copy Maven wrapper and project files
COPY pom.xml mvnw ./
COPY .mvn .mvn
COPY src ./src

# Build the project
RUN chmod +x mvnw && ./mvnw clean package -DskipTests

# -----------------------------
# Stage 2: Runtime
# -----------------------------
FROM eclipse-temurin:17-jdk-jammy

WORKDIR /app

# Copy the JAR from the build stage
COPY --from=build /app/target/*.jar app.jar

# Expose the port your Spring Boot app will run on
EXPOSE 8080

# Run the Spring Boot application
CMD ["java", "-jar", "app.jar"]
