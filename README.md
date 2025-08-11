# Kafka & Redis Playground

A hands-on learning playground for exploring Apache Kafka and Redis integration with Spring Boot, featuring a modern **Onion Architecture** implementation.

## 🚀 Tech Stack

- **Apache Kafka** - Distributed event streaming platform
- **Redis** - In-memory data structure store
- **Spring Boot 3.5.4** - Latest stable Java application framework
- **Java 23** - Latest stable JDK (using stable features only)
- **Gradle 8.10.2** - Modern build tool with optimization
- **Docker Compose** - Container orchestration for local development

## 📋 Prerequisites

- **Java 23** (exactly version 23, not 24)
- **Docker** and **Docker Compose**
- **Git**

### Java 23 Installation

```bash
# Install with SDKMAN (recommended)
curl -s "https://get.sdkman.io" | bash
sdk install java 23.0.1-oracle

# Verify installation
java --version
# Expected: java 23.0.1 or similar

# If you have Java 24, switch to Java 23
sdk use java 23.0.1-oracle
```

⚠️ **Important**: This project requires **Java 23** specifically. Java 24 is not compatible with Gradle 8.10.2.

## 🏃‍♂️ Quick Start

### 1. Clone and Setup

```bash
git clone https://github.com/toshiakisan1127/kafka-redis-playground.git
cd kafka-redis-playground
```

### 2. Verify Java Version

```bash
# Check Java version
java --version
# Should show: java 23.x.x

# If wrong version, set Java 23
export JAVA_HOME=$HOME/.sdkman/candidates/java/23.0.1-oracle
```

### 3. Start Infrastructure Services

```bash
# Start Kafka, Redis, and management UIs
docker-compose up -d

# Verify all services are running
docker-compose ps
```

### 4. Run Spring Boot Application

```bash
# Option 1: Standard startup
./gradlew bootRun

# Option 2: Development mode (with optimized JVM settings)
./gradlew runApp

# Option 3: Build and run JAR
./gradlew bootJar
java -jar build/libs/kafka-redis-playground-1.0.0.jar
```

### 5. Verify Application is Running

```bash
# Health check
curl http://localhost:8080/actuator/health

# Expected response:
# {"status":"UP"}
```

## 🔗 Service Access

| Service | URL | Description |
|---------|-----|-------------|
| **Spring Boot App** | http://localhost:8080 | Main application with REST API |
| **Kafka UI** | http://localhost:8081 | Web interface for Kafka management |
| **Redis Insight** | http://localhost:8001 | Web interface for Redis management |
| **Actuator** | http://localhost:8080/actuator | Application monitoring endpoints |

## 🧪 Testing the Application

### Create Messages

```bash
# Create an INFO message
curl -X POST http://localhost:8080/api/messages \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Hello, Kafka and Redis with Java 23!",
    "sender": "developer",
    "type": "INFO"
  }'

# Create an ERROR message (urgent)
curl -X POST http://localhost:8080/api/messages \
  -H "Content-Type: application/json" \
  -d '{
    "content": "System error occurred",
    "sender": "system",
    "type": "ERROR"
  }'
```

### Retrieve Messages

```bash
# Get all messages
curl http://localhost:8080/api/messages

# Get urgent messages only (ERROR, WARNING)
curl http://localhost:8080/api/messages/urgent

# Get messages by sender
curl http://localhost:8080/api/messages/sender/developer

# Get specific message by ID
curl http://localhost:8080/api/messages/{message-id}
```

### Message Management

```bash
# Delete specific message
curl -X DELETE http://localhost:8080/api/messages/{message-id}

# Cleanup old messages (older than 60 minutes)
curl -X DELETE "http://localhost:8080/api/messages/cleanup?minutes=60"
```

## 🛠️ Development Commands

### Gradle Tasks

```bash
# Application lifecycle
./gradlew bootRun          # Run application
./gradlew runApp           # Run with dev settings
./gradlew bootJar          # Build executable JAR

# Testing and quality
./gradlew test             # Run tests
./gradlew check            # Run all checks
./gradlew checkFormat      # Code formatting check

# Dependencies and documentation
./gradlew dependencies     # Show dependency tree
./gradlew dependencyGraph  # Generate dependency report
./gradlew tasks            # List all available tasks

# Docker integration
./gradlew buildDockerImage # Build Docker image
```

### Docker Management

```bash
# Infrastructure management
docker-compose up -d           # Start all services
docker-compose down            # Stop all services
docker-compose down -v         # Stop and remove volumes
docker-compose logs -f         # View logs
docker-compose restart kafka  # Restart specific service

# Individual service management
docker-compose up -d kafka redis    # Start only Kafka and Redis
docker-compose stop kafka-ui        # Stop Kafka UI
```

### Development Workflow

```bash
# 1. Ensure Java 23 is active
java --version  # Should show 23.x.x

# 2. Start infrastructure
docker-compose up -d

# 3. Run application in development mode
./gradlew runApp

# 4. Make changes and the app will auto-reload
# (Spring Boot DevTools enabled)

# 5. Run tests
./gradlew test

# 6. Build for production
./gradlew bootJar
```

## 🚦 Troubleshooting

### Java Version Issues

**"Incompatible Java version" Error**
```bash
# Check current Java version
java --version

# If using Java 24, switch to Java 23
sdk use java 23.0.1-oracle

# Verify Gradle can find Java 23
./gradlew --version
```

**JAVA_HOME Issues**
```bash
# Set JAVA_HOME explicitly
export JAVA_HOME=$HOME/.sdkman/candidates/java/23.0.1-oracle

# Or for Homebrew users
export JAVA_HOME=/usr/local/Cellar/openjdk@23/23.0.1/libexec/openjdk.jdk/Contents/Home
```

### Common Issues

**Port Conflicts**
```bash
# Check what's using port 8080
lsof -i :8080
# Kill the process if needed
kill -9 $(lsof -t -i:8080)
```

**Docker Issues**
```bash
# Reset Docker environment
docker-compose down -v
docker system prune -f
docker-compose up -d
```

**Gradle Issues**
```bash
# Clean build cache
./gradlew clean build --refresh-dependencies
```

## 🔧 Configuration

### Environment Variables

```bash
# Application settings
export SPRING_PROFILES_ACTIVE=dev
export SERVER_PORT=8080

# Kafka settings
export SPRING_KAFKA_BOOTSTRAP_SERVERS=localhost:9092
export APP_KAFKA_TOPIC_MESSAGES=messages

# Redis settings
export SPRING_DATA_REDIS_HOST=localhost
export SPRING_DATA_REDIS_PORT=6379

# JVM settings for Java 23
export JAVA_OPTS="-Xms256m -Xmx512m"
```

## 🏗️ Architecture Overview

This project implements **Onion Architecture** with the following layers:

### Layer Structure
```
📦 com.example.playground
├── 🎯 domain/                    # Domain Layer (Core)
│   ├── model/                   # Business entities
│   └── repository/              # Repository interfaces
├── 🔄 application/              # Application Layer
│   └── service/                 # Business logic orchestration
├── 🔌 infrastructure/           # Infrastructure Layer
│   ├── config/                  # Framework configurations
│   ├── messaging/               # Kafka implementations
│   └── repository/              # Redis implementations
└── 🌐 presentation/             # Presentation Layer
    ├── controller/              # REST API endpoints
    └── dto/                     # Data transfer objects
```

### Key Features

- **Dependency Inversion**: Inner layers don't depend on outer layers
- **Domain-Driven Design**: Rich domain models with business logic
- **Event Sourcing**: Kafka for message streaming
- **Caching Strategy**: Redis for performance optimization
- **Java 23 Compatibility**: Uses stable features of Java 23

## 📊 Monitoring and Observability

### Actuator Endpoints

```bash
# Application health and metrics
curl http://localhost:8080/actuator/health
curl http://localhost:8080/actuator/info
curl http://localhost:8080/actuator/metrics
curl http://localhost:8080/actuator/prometheus

# Application configuration
curl http://localhost:8080/actuator/env
curl http://localhost:8080/actuator/configprops
```

### Log Monitoring

```bash
# Application logs
./gradlew bootRun --info

# Docker service logs
docker-compose logs -f kafka
docker-compose logs -f redis
```

## 📚 Documentation

- [`docs/spring-boot-architecture.md`](docs/spring-boot-architecture.md) - Detailed architecture guide
- [`docs/sequence-diagrams.md`](docs/sequence-diagrams.md) - Interactive sequence diagrams
- [`docs/architecture.md`](docs/architecture.md) - Docker Compose infrastructure
- [`docs/kafka-concepts.md`](docs/kafka-concepts.md) - Kafka fundamentals and best practices

## 🎯 Next Steps

Once you're up and running:

1. **Explore the APIs** - Try all the message endpoints
2. **Monitor with UIs** - Check Kafka UI and Redis Insight
3. **Review Architecture** - Study the onion architecture implementation
4. **Extend Features** - Add your own message types and processing logic
5. **Performance Testing** - Use the application under load
6. **Integration Tests** - Run TestContainers-based tests

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Follow the existing architecture patterns
4. Add tests for new functionality
5. Update documentation
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Happy Coding with Java 23 and Event-Driven Architecture!** 🎉