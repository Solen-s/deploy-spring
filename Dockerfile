# Stage 1: Build
FROM maven:3.9.2-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml mvnw ./
COPY .mvn .mvn
COPY src ./src
RUN chmod +x mvnw && ./mvnw clean package -DskipTests

# Stage 2: Run
FROM openjdk:17-jdk-slim
WORKDIR /app
RUN apt-get update && apt-get install -y bash git && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/target/*.jar app.jar
COPY deploy.sh .
RUN chmod +x deploy.sh
CMD ["java", "-jar", "app.jar"]
