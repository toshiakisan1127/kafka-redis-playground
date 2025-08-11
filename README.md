# Kafka & Redis Playground

A hands-on learning playground for exploring Apache Kafka and Redis integration with Spring Boot, featuring a modern **Onion Architecture** implementation.

## 🚀 Tech Stack

- **Apache Kafka** - Distributed event streaming platform
- **Redis** - In-memory data structure store
- **Spring Boot 3.5.4** - Latest stable Java application framework
- **Java 23** - Latest stable JDK
- **Gradle 8.10.2** - Modern build tool with optimization
- **Docker Compose** - Container orchestration for local development

## 📋 Prerequisites

- **Java 23** (configured in your IDE)
- **Docker** and **Docker Compose**
- **Git**

## 🏃‍♂️ Quick Start

### 1. Clone and Setup

```bash
git clone https://github.com/toshiakisan1127/kafka-redis-playground.git
cd kafka-redis-playground
```

### 2. Start Infrastructure Services

```bash
# Start Kafka, Redis, and management UIs
docker-compose up -d

# Verify all services are running
docker-compose ps
```

### 3. Run Spring Boot Application

```bash
# Option 1: Standard startup
./gradlew bootRun

# Option 2: Development mode (with optimized JVM settings)
./gradlew runApp

# Option 3: Build and run JAR
./gradlew bootJar
java -jar build/libs/kafka-redis-playground-1.0.0.jar
```

### 4. Verify Application is Running

```bash
# Health check
curl http://localhost:8888/actuator/health

# Expected response:
# {"status":"UP"}
```

## 🔗 Service Access

| Service | URL | Description |
|---------|-----|-------------|
| **Spring Boot App** | http://localhost:8888 | Main application with REST API |
| **Kafka UI** | http://localhost:8081 | Web interface for Kafka management |
| **Redis Insight** | http://localhost:8001 | Web interface for Redis management |
| **Actuator** | http://localhost:8888/actuator | Application monitoring endpoints |

## 🧪 Testing the Application

### Create Messages

```bash
# Create an INFO message
curl -X POST http://localhost:8888/api/messages \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Hello, Kafka and Redis with Java 23!",
    "sender": "developer",
    "type": "INFO"
  }'

# Create an ERROR message (urgent)
curl -X POST http://localhost:8888/api/messages \
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
curl http://localhost:8888/api/messages

# Get urgent messages only (ERROR, WARNING)
curl http://localhost:8888/api/messages/urgent

# Get messages by sender
curl http://localhost:8888/api/messages/sender/developer

# Get specific message by ID
curl http://localhost:8888/api/messages/{message-id}
```

### Message Management

```bash
# Delete specific message
curl -X DELETE http://localhost:8888/api/messages/{message-id}

# Cleanup old messages (older than 60 minutes)
curl -X DELETE "http://localhost:8888/api/messages/cleanup?minutes=60"
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
# 1. Start infrastructure
docker-compose up -d

# 2. Run application in development mode
./gradlew runApp

# 3. Make changes and the app will auto-reload
# (Spring Boot DevTools enabled)

# 4. Run tests
./gradlew test

# 5. Build for production
./gradlew bootJar
```

## 🚦 Troubleshooting

### Common Issues

**Port Conflicts**
```bash
# Check what's using port 8888
lsof -i :8888
# Kill the process if needed
kill -9 $(lsof -t -i:8888)

# If you need to use a different port, set environment variable:
export SERVER_PORT=9999
./gradlew bootRun
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

**Java Compatibility**
- Ensure your IDE is configured to use **Java 23**
- Project uses Gradle 8.10.2 which is compatible with Java 23
- Check Project Settings → SDK → Java 23

## 🔧 Configuration

### Environment Variables

```bash
# Application settings
export SPRING_PROFILES_ACTIVE=dev
export SERVER_PORT=8888  # Default port (can be changed)

# Kafka settings
export SPRING_KAFKA_BOOTSTRAP_SERVERS=localhost:9092
export APP_KAFKA_TOPIC_MESSAGES=messages

# Redis settings
export SPRING_DATA_REDIS_HOST=localhost
export SPRING_DATA_REDIS_PORT=6379
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
curl http://localhost:8888/actuator/health
curl http://localhost:8888/actuator/info
curl http://localhost:8888/actuator/metrics
curl http://localhost:8888/actuator/prometheus

# Application configuration
curl http://localhost:8888/actuator/env
curl http://localhost:8888/actuator/configprops
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