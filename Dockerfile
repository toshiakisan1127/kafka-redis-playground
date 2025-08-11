# Use Eclipse Temurin JDK 23 for Gradle build
FROM eclipse-temurin:23-jdk AS build

# Install Gradle manually
RUN apt-get update && apt-get install -y wget unzip && \
    wget https://services.gradle.org/distributions/gradle-8.10.2-bin.zip && \
    unzip gradle-8.10.2-bin.zip && \
    mv gradle-8.10.2 /opt/gradle && \
    ln -s /opt/gradle/bin/gradle /usr/local/bin/gradle && \
    rm gradle-8.10.2-bin.zip && \
    apt-get clean

# Set working directory
WORKDIR /app

# Copy Gradle files
COPY build.gradle settings.gradle gradle.properties ./
COPY gradle ./gradle

# Copy source code
COPY src ./src

# Build the application
RUN gradle bootJar --no-daemon

# Use JDK 23 for runtime
FROM eclipse-temurin:23-jdk-slim

# Set working directory
WORKDIR /app

# Copy built JAR
COPY --from=build /app/build/libs/*.jar app.jar

# Expose port
EXPOSE 8888

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
