# Getting Started Guide

This guide provides detailed instructions for setting up and running the Kafka & Redis Playground application.

## Prerequisites

### Required Software
- **Java 23** - Latest stable JDK
- **Docker** and **Docker Compose** - For running Kafka and Redis
- **Git** - For cloning the repository

### Java 23 Setup
Configure your IDE to use Java 23:
- **IntelliJ IDEA**: File → Project Structure → Project → SDK → Java 23
- **VS Code**: Java Extension Pack → Configure Java Runtime
- **Eclipse**: Project Properties → Java Build Path → Libraries → Modulepath/Classpath → JRE System Library

## Installation

### 1. Clone the Repository
```bash
git clone https://github.com/toshiakisan1127/kafka-redis-playground.git
cd kafka-redis-playground
```

### 2. Start Infrastructure Services
```bash
# Start all services in detached mode
docker-compose up -d

# Verify all services are running
docker-compose ps

# Expected output:
# kafka-redis-playground-kafka-1        Running
# kafka-redis-playground-redis-1        Running
# kafka-redis-playground-kafka-ui-1     Running
# kafka-redis-playground-redis-insight-1 Running
```

### 3. Verify Infrastructure
```bash
# Check Kafka is ready
docker exec -it kafka-redis-playground-kafka-1 kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --list

# Check Redis is ready
docker exec -it kafka-redis-playground-redis-1 redis-cli ping
# Expected: PONG
```

### 4. Run the Spring Boot Application
```bash
# Option 1: Standard startup
./gradlew bootRun

# Option 2: Development mode (with optimized JVM settings)
./gradlew runApp

# Option 3: Build and run JAR
./gradlew bootJar
java -jar build/libs/kafka-redis-playground-1.0.0.jar
```

### 5. Verify Application
```bash
# Health check
curl http://localhost:8888/actuator/health

# Expected response:
# {"status":"UP","components":{"diskSpace":{"status":"UP"},...}}

# Check if topics were auto-created
curl http://localhost:8888/actuator/info
```

## Service URLs

| Service | URL | Purpose |
|---------|-----|---------|
| **Spring Boot API** | http://localhost:8888 | Main application |
| **Actuator Health** | http://localhost:8888/actuator/health | Health monitoring |
| **Kafka UI** | http://localhost:8081 | Kafka cluster management |
| **Redis Insight** | http://localhost:8001 | Redis data browser |

## Quick API Test

### Create Your First Message
```bash
curl -X POST http://localhost:8888/api/messages \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Welcome to Kafka & Redis Playground!",
    "sender": "getting-started",
    "type": "INFO"
  }'
```

### Retrieve Messages
```bash
# Get all messages
curl http://localhost:8888/api/messages | jq

# Get messages by sender
curl http://localhost:8888/api/messages/sender/getting-started | jq

# Get urgent messages (ERROR, WARNING types)
curl http://localhost:8888/api/messages/urgent | jq
```

## Verification Steps

### 1. Check Kafka Integration
```bash
# In Kafka UI (http://localhost:8081)
# - Navigate to Topics → messages
# - You should see the message you created
# - Check partitions and consumer groups
```

### 2. Check Redis Integration
```bash
# In Redis Insight (http://localhost:8001)
# - Connect to localhost:6379
# - Browse keys starting with "message:"
# - You should see your cached messages
```

### 3. Check Application Logs
```bash
# View application logs
./gradlew bootRun --info

# Key log entries to look for:
# - "Started KafkaRedisPlaygroundApplication"
# - "Cluster ID: [kafka-cluster-id]"
# - Topic creation logs
```

## Environment Configuration

### Default Ports
- **Application**: 8888
- **Kafka**: 9092
- **Redis**: 6379
- **Kafka UI**: 8081
- **Redis Insight**: 8001

### Environment Variables
```bash
# Application settings
export SPRING_PROFILES_ACTIVE=dev
export SERVER_PORT=8888

# Kafka settings
export SPRING_KAFKA_BOOTSTRAP_SERVERS=localhost:9092
export APP_KAFKA_TOPIC_MESSAGES=messages

# Redis settings
export SPRING_DATA_REDIS_HOST=localhost
export SPRING_DATA_REDIS_PORT=6379
```

## What Happens During Startup

1. **Infrastructure Check**: Spring Boot connects to Kafka and Redis
2. **Topic Creation**: `messages` and `messages.DLQ` topics are auto-created
3. **Consumer Registration**: Message consumer group is registered with Kafka
4. **Cache Initialization**: Redis connection pool is established
5. **API Activation**: REST endpoints become available

## Next Steps

- **Explore APIs**: See [API Reference](api-reference.md)
- **Development**: Read [Development Guide](development-guide.md)
- **Architecture**: Study [Architecture Guide](spring-boot-architecture.md)
- **Deep Dive**: Learn [Kafka & Redis](kafka-redis-guide.md)

## Need Help?

- **Issues**: Check [Troubleshooting Guide](troubleshooting.md)
- **Architecture**: Review [Sequence Diagrams](sequence-diagrams.md)
- **Community**: Open an issue on GitHub
