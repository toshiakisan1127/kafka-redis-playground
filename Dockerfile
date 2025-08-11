# Use Gradle image with JDK 21 (more stable than JDK 23)
FROM gradle:8.10.2-jdk21 AS build

# Set working directory
WORKDIR /app

# Copy Gradle files
COPY build.gradle settings.gradle gradle.properties ./
COPY gradle ./gradle

# Copy source code
COPY src ./src

# Build the application
RUN gradle bootJar --no-daemon

# Use JDK 21 for runtime (more stable than JDK 23)
FROM openjdk:21-jdk-slim

# Set working directory
WORKDIR /app

# Copy built JAR
COPY --from=build /app/build/libs/*.jar app.jar

# Expose port
EXPOSE 8888

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
