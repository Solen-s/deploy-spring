FROM eclipse-temurin:17-jdk-jammy
WORKDIR /app

# Install git + Maven for build
RUN apt-get update && apt-get install -y git maven && rm -rf /var/lib/apt/lists/*

# Copy everything from build context (the cloned repo)
COPY . .

# Make Maven wrapper executable if present
RUN [ -f mvnw ] && chmod +x mvnw || true

# Build Spring Boot app
RUN if [ -f mvnw ]; then ./mvnw clean package -DskipTests; else mvn clean package -DskipTests; fi

# Expose default port
EXPOSE 8082

# Run jar
CMD JAR_FILE=$(ls target/*.jar | head -n1) && java -jar "$JAR_FILE"
