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

## Planned Features

- [x] Docker environment setup
- [ ] Kafka producer and consumer implementation
- [ ] Redis caching strategies
- [ ] Message processing with Kafka + Redis integration
- [ ] Configuration examples and best practices

## Learning Goals

- Understanding Kafka messaging patterns
- Implementing Redis caching strategies  
- Building distributed systems with event-driven architecture
- Hands-on experience with containerized development environments
