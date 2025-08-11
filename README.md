# Kafka & Redis Playground

A hands-on learning playground for exploring Apache Kafka and Redis integration with Spring Boot, featuring a modern **Onion Architecture** implementation.

## 🚀 Tech Stack

- **Spring Boot 3.5.4** - Latest stable Java application framework
- **Java 23** - Latest stable JDK
- **Apache Kafka** - Distributed event streaming platform
- **Redis** - In-memory data structure store
- **Gradle 8.10.2** - Modern build tool
- **Docker Compose** - Container orchestration

## 🏃‍♂️ Quick Start

### Prerequisites
- Java 23 (configured in your IDE)
- Docker and Docker Compose

### Get Started
```bash
# 1. Clone the repository
git clone https://github.com/toshiakisan1127/kafka-redis-playground.git
cd kafka-redis-playground

# 2. Start infrastructure
docker-compose up -d

# 3. Run the application
./gradlew bootRun

# 4. Test the API
curl http://localhost:8888/actuator/health
```

## 🔗 Service Access

| Service | URL | Description |
|---------|-----|-------------|
| **Spring Boot App** | http://localhost:8888 | REST API with Onion Architecture |
| **Kafka UI** | http://localhost:8081 | Kafka management interface |
| **Redis Insight** | http://localhost:8001 | Redis management interface |

## 🧪 Try the API

```bash
# Create a message
curl -X POST http://localhost:8888/api/messages \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Hello, Kafka and Redis!",
    "sender": "developer",
    "type": "INFO"
  }'

# Get all messages
curl http://localhost:8888/api/messages

# Get urgent messages
curl http://localhost:8888/api/messages/urgent
```

## 📚 Documentation

- **[Getting Started Guide](docs/getting-started.md)** - Detailed setup and usage
- **[Development Guide](docs/development-guide.md)** - Development workflow and commands
- **[API Reference](docs/api-reference.md)** - Complete API documentation
- **[Architecture Guide](docs/spring-boot-architecture.md)** - Onion Architecture details
- **[Kafka & Redis Guide](docs/kafka-redis-guide.md)** - Deep dive into messaging and caching
- **[Sequence Diagrams](docs/sequence-diagrams.md)** - Visual flow diagrams
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions

## 🏗️ Architecture

This project implements **Onion Architecture** with clean separation of concerns:

```
📦 Domain Layer (Core Business Logic)
├── 🔄 Application Layer (Use Cases)
├── 🔌 Infrastructure Layer (External Concerns)
└── 🌐 Presentation Layer (API Endpoints)
```

**Key Features:**
- Domain-Driven Design with rich business models
- Event sourcing with Kafka message streaming
- Redis caching for performance optimization
- Complete test coverage with TestContainers

## 🎯 What You'll Learn

- **Onion Architecture** - Clean, testable, maintainable code structure
- **Event-Driven Architecture** - Kafka producer/consumer patterns
- **Caching Strategies** - Redis integration with Spring Boot
- **Modern Java** - Java 23 features and best practices
- **Spring Boot 3.5** - Latest framework capabilities
- **Docker Integration** - Containerized development workflow

## 🤝 Contributing

Contributions are welcome! Please read our [Development Guide](docs/development-guide.md) for details on our development process.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Ready to explore modern event-driven architecture?** 🚀
