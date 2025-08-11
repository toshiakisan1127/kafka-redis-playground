# Kafka & Redis Playground

A hands-on learning playground for exploring Apache Kafka and Redis integration with Spring Boot, featuring a modern **Onion Architecture** implementation.

## 🚀 Tech Stack

- **Spring Boot 3.5.4** - Latest stable Java application framework
- **Amazon Corretto 21** - Enterprise-grade Java runtime
- **Apache Kafka** - Distributed event streaming platform
- **Redis** - In-memory data structure store
- **Gradle 8.10.2** - Modern build tool
- **Docker Compose** - Complete containerization

## 🏃‍♂️ Quick Start

### Prerequisites
- **Docker** and **Docker Compose** - For running the entire stack
- **Git** - For cloning the repository

### Get Started
```bash
# 1. Clone the repository
git clone https://github.com/toshiakisan1127/kafka-redis-playground.git
cd kafka-redis-playground

# 2. Configure environment (optional)
cp .env.template .env

# 3. Start everything with Docker
docker-compose --profile local-infra up --build -d

# 4. Test the API
curl http://localhost:8888/actuator/health
```

## 🔗 Service Access

| Service | URL | Description |
|---------|-----|-------------|
| **Spring Boot API** | http://localhost:8888 | REST API with Onion Architecture |
| **Kafka UI** | http://localhost:8080 | Kafka management interface |
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

## 🎬 Observable Processing

Watch Kafka message processing in real-time with **3-second delays**:

```bash
# Send multiple messages
for i in {1..5}; do
  curl -X POST http://localhost:8888/api/messages \
    -H "Content-Type: application/json" \
    -d "{\"content\": \"Demo message $i\", \"sender\": \"demo\", \"type\": \"INFO\"}"
done

# Watch processing in Kafka UI: http://localhost:8080
# Follow logs: docker-compose logs -f app
```

## 🧪 Testing

### Automated Integration Tests
```bash
# Run comprehensive integration tests
./tests/integration-test.sh

# Run specific test types
./tests/integration-test.sh test        # API tests only
./tests/integration-test.sh performance # Performance tests only
./tests/integration-test.sh setup       # Environment setup only
./tests/integration-test.sh cleanup     # Environment cleanup only
```

### Manual Testing
```bash
# Interactive testing interface
./tests/manual-test.sh
```

### Load Testing
```bash
# Basic load test
./tests/load-test.sh

# Advanced load tests
./tests/load-test.sh --users 20 --requests 50  # Custom load
./tests/load-test.sh --spike                   # Spike test
./tests/load-test.sh --endurance               # Endurance test
```

**Test Coverage:**
- ✅ All API endpoints (create, read, delete, filter)
- ✅ Kafka producer/consumer integration
- ✅ Redis caching and duplicate prevention
- ✅ Error handling and validation
- ✅ Performance and load testing
- ✅ CI/CD pipeline integration

## 📚 Documentation

- **[Getting Started Guide](docs/getting-started.md)** - Detailed setup and usage
- **[Development Guide](docs/development-guide.md)** - Development workflow and commands
- **[API Reference](docs/api-reference.md)** - Complete API documentation
- **[Architecture Guide](docs/spring-boot-architecture.md)** - Onion Architecture details
- **[Kafka & Redis Guide](docs/kafka-redis-guide.md)** - Deep dive into messaging and caching
- **[Sequence Diagrams](docs/sequence-diagrams.md)** - Visual flow diagrams
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions
- **[Testing Guide](tests/README.md)** - Comprehensive testing documentation

## 🏗️ Architecture

This project implements **Onion Architecture** with clean separation of concerns:

```
📦 Domain Layer (Core Business Logic)
├── 🔄 Application Layer (Use Cases)
├── 🔌 Infrastructure Layer (External Concerns)
└── 🌐 Presentation Layer (API Endpoints)
```

**Key Features:**
- **No Duplicate Messages** - Redis Sets prevent ID duplicates
- **Observable Processing** - 3-second delays for demonstration
- **Environment Flexibility** - Local dev + production ready
- **Complete Docker Stack** - No local Java installation needed
- **Comprehensive Testing** - Integration, performance, and load tests

## 🎯 What You'll Learn

- **Onion Architecture** - Clean, testable, maintainable code structure
- **Event-Driven Architecture** - Kafka producer/consumer patterns
- **Caching Strategies** - Redis Sets for duplicate prevention
- **Modern Java** - Amazon Corretto 21 with enterprise features
- **Spring Boot 3.5** - Latest framework capabilities
- **Docker Integration** - Complete containerized development
- **Testing Strategies** - Integration and performance testing

## 🚀 Deployment Options

### Local Development
```bash
# Full stack with local infrastructure
docker-compose --profile local-infra up --build -d
```

### Production Environment
```bash
# Using managed Kafka/Redis services
KAFKA_BOOTSTRAP_SERVERS=kafka-prod.com:9092 \
REDIS_HOST=redis-prod.com \
docker-compose up --build -d
```

## 🤝 Contributing

Contributions are welcome! Please read our [Development Guide](docs/development-guide.md) for details on our development process.

Before submitting a PR, please run the integration tests:
```bash
./tests/integration-test.sh
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Ready to explore modern event-driven architecture with Amazon Corretto?** ☕🚀
