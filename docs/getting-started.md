# Getting Started Guide

This guide provides detailed instructions for setting up and running the Kafka & Redis Playground application.

## Prerequisites

### Required Software
- **Docker** and **Docker Compose** - For running the entire stack
- **Git** - For cloning the repository

## Installation

### 1. Clone the Repository
```bash
git clone https://github.com/toshiakisan1127/kafka-redis-playground.git
cd kafka-redis-playground
```

### 2. Start Everything with Docker Compose
```bash
# Start all services including Spring Boot app
docker-compose up -d

# Or build and start (if code changed)
docker-compose up --build -d

# Verify all services are running
docker-compose ps

# Expected output:
# zookeeper               Running
# kafka                   Running  
# redis                   Running
# redis-insight           Running
# kafka-ui                Running
# kafka-redis-app         Running
```

### 3. Verify Application
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
| **Kafka UI** | http://localhost:8080 | Kafka cluster management |
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

## Watching the Processing Delay

The app is configured with a **3-second processing delay** to make Kafka message processing visible:

### Send Multiple Messages
```bash
# Send 5 messages quickly
for i in {1..5}; do
  curl -X POST http://localhost:8888/api/messages \
    -H "Content-Type: application/json" \
    -d "{\"content\": \"Demo message $i\", \"sender\": \"demo\", \"type\": \"INFO\"}"
done
```

### Watch in Kafka UI
1. Go to http://localhost:8080
2. Navigate to **Topics → messages**
3. See messages being processed one by one with 3-second delays

### Watch the Logs
```bash
# Follow Spring Boot app logs
docker-compose logs -f app

# You'll see:
# 🚀 Received message: key=uuid-1234, partition=0, offset=15
# ⏳ Processing delay: 3000ms for better observation...
# 💾 Saving message to Redis: id=uuid-1234, content='Demo message 1'
# ✅ Message processed and saved: id=uuid-1234, sender=demo, type=INFO
```

## Data Management

### Clear All Redis Data
```bash
# Option 1: Clear all Redis data (recommended)
docker exec -it redis redis-cli FLUSHALL

# Option 2: Clear only current database (db 0)
docker exec -it redis redis-cli FLUSHDB

# Option 3: Via Redis Insight UI
# - Go to http://localhost:8001
# - Connect to redis:6379 (internal) or localhost:6379 (external)
# - Use "Flush Database" button

# Verify Redis is empty
docker exec -it redis redis-cli KEYS "*"
# Should return: (empty array)
```

### Clear Kafka Topics (Optional)
```bash
# Delete and recreate the messages topic
docker exec -it kafka kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --delete --topic messages

# Topic will be auto-recreated when application starts
```

### Reset Everything
```bash
# Stop and remove all containers + volumes
docker-compose down -v

# Start fresh
docker-compose up --build -d
```

## Verification Steps

### 1. Check Kafka Integration
```bash
# In Kafka UI (http://localhost:8080)
# - Navigate to Topics → messages
# - You should see the message you created
# - Check partitions and consumer groups
```

### 2. Check Redis Integration
```bash
# In Redis Insight (http://localhost:8001)
# - Connect to localhost:6379
# - Browse keys starting with "message:"
# - You should see your cached messages as Sets (no duplicates!)
```

### 3. Check Application Logs
```bash
# View application logs
docker-compose logs -f app

# Key log entries to look for:
# - "Started KafkaRedisPlaygroundApplication"
# - "🚀 Received message" 
# - "⏳ Processing delay"
# - "✅ Message processed and saved"
```

## Configuration

### Environment Variables (in docker-compose.yml)
```yaml
environment:
  # Kafka settings (internal network)
  SPRING_KAFKA_BOOTSTRAP_SERVERS: kafka:29092
  
  # Redis settings (internal network) 
  SPRING_DATA_REDIS_HOST: redis
  
  # Processing delay for demo (3 seconds)
  APP_KAFKA_CONSUMER_PROCESSING_DELAY: 3000
```

### Customize Processing Delay
```bash
# Edit docker-compose.yml
APP_KAFKA_CONSUMER_PROCESSING_DELAY: 5000  # 5 seconds
# or
APP_KAFKA_CONSUMER_PROCESSING_DELAY: 0     # No delay

# Restart app
docker-compose restart app
```

## Development Tips

### Testing Different Scenarios
```bash
# 1. Clear Redis data
docker exec -it redis redis-cli FLUSHALL

# 2. Send test messages
for i in {1..3}; do
  curl -X POST http://localhost:8888/api/messages \
    -H "Content-Type: application/json" \
    -d "{\"content\": \"Test $i\", \"sender\": \"test\", \"type\": \"INFO\"}"
done

# 3. Verify no duplicates (thanks to Redis Sets!)
curl http://localhost:8888/api/messages | jq 'length'
# Should show: 3 (not 6)
```

### Common Commands
```bash
# Check Redis keys
docker exec -it redis redis-cli KEYS "*"

# Count Redis keys
docker exec -it redis redis-cli DBSIZE

# Monitor Redis commands in real-time
docker exec -it redis redis-cli MONITOR

# Check Kafka consumer groups
docker exec -it kafka kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 --list

# List Kafka topics
docker exec -it kafka kafka-topics.sh \
  --bootstrap-server localhost:9092 --list

# Check topic details
docker exec -it kafka kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --describe --topic messages

# Rebuild only the app (after code changes)
docker-compose build app
docker-compose restart app
```

## Architecture Features

### ✅ **Onion Architecture**
- Clean separation of concerns
- Domain-driven design
- Testable and maintainable

### ✅ **No Duplicate Messages**
- Publisher sends to Kafka only
- Consumer saves to Redis only
- Redis Sets prevent ID duplicates

### ✅ **Observable Processing**
- 3-second delay makes Kafka processing visible
- Rich logging with emojis
- Real-time monitoring via Kafka UI

### ✅ **Complete Docker Stack**
- No local Java/Gradle installation needed
- Consistent environment across machines
- Easy deployment and scaling

## Next Steps

- **Explore APIs**: See [API Reference](api-reference.md)
- **Development**: Read [Development Guide](development-guide.md)
- **Architecture**: Study [Architecture Guide](spring-boot-architecture.md)
- **Deep Dive**: Learn [Kafka & Redis](kafka-redis-guide.md)

## Need Help?

- **Issues**: Check [Troubleshooting Guide](troubleshooting.md)
- **Architecture**: Review [Sequence Diagrams](sequence-diagrams.md)
- **Community**: Open an issue on GitHub
