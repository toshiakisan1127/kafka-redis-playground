# Kafka & Redis Playground

A hands-on learning playground for exploring Apache Kafka and Redis integration with Spring Boot.

## Tech Stack

- **Apache Kafka** - Distributed event streaming platform
- **Redis** - In-memory data structure store
- **Spring Boot** - Java application framework
- **Docker Compose** - Container orchestration for local development

## Getting Started

### Prerequisites
- Docker and Docker Compose installed

### Quick Start

1. Clone the repository:
```bash
git clone https://github.com/toshiakisan1127/kafka-redis-playground.git
cd kafka-redis-playground
```

2. Start the services:
```bash
docker-compose up -d
```

3. Verify services are running:
```bash
docker-compose ps
```

### Services Overview

| Service | Port | Description |
|---------|------|-------------|
| Kafka | 9092 | Kafka broker |
| Zookeeper | 2181 | Kafka coordination service |
| Redis | 6379 | Redis server |
| Kafka UI | 8080 | Web interface for Kafka (http://localhost:8080) |
| Redis Insight | 8001 | Web interface for Redis (http://localhost:8001) |

### Basic Commands

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down

# Clean up (removes volumes)
docker-compose down -v
```

## 📚 Documentation

### Architecture & Concepts
- [`docs/architecture.md`](docs/architecture.md) - Docker Compose setup and service relationships with visual diagrams
- [`docs/kafka-concepts.md`](docs/kafka-concepts.md) - Comprehensive Kafka fundamentals, best practices, and design patterns
- [`docs/zookeeper-deep-dive.md`](docs/zookeeper-deep-dive.md) - Zookeeper's role in cluster management and coordination

### Learning Path
1. **Start here**: [`docs/architecture.md`](docs/architecture.md) - Understand the overall setup and how services connect
2. **Core concepts**: [`docs/kafka-concepts.md`](docs/kafka-concepts.md) - Learn Kafka fundamentals, offset management, and topic design
3. **Deep dive**: [`docs/zookeeper-deep-dive.md`](docs/zookeeper-deep-dive.md) - Master cluster coordination and distributed system concepts

## Planned Features

- [x] Docker environment setup
- [x] Comprehensive documentation with visual diagrams
- [x] Kafka and Zookeeper architecture explanation
- [ ] Kafka producer and consumer implementation
- [ ] Redis caching strategies
- [ ] Message processing with Kafka + Redis integration
- [ ] Spring Boot application examples
- [ ] Configuration examples and best practices

## Learning Goals

- Understanding Kafka messaging patterns and distributed system design
- Implementing Redis caching strategies with real-world examples
- Building distributed systems with event-driven architecture
- Hands-on experience with containerized development environments
- Mastering Kafka concepts: brokers, topics, partitions, consumers, and offset management
- Learning Zookeeper's role in cluster coordination and leader election

## Contributing

Contributions are welcome! Whether it's improving documentation, adding examples, or fixing issues, feel free to open a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.