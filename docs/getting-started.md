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

### 2. Configure Environment (Optional)
```bash
# Copy environment template
cp .env.template .env

# Edit as needed (defaults work for local development)
vim .env
```

**Default .env settings (Local Development):**
```bash
KAFKA_BOOTSTRAP_SERVERS=kafka:29092
REDIS_HOST=redis
PROCESSING_DELAY=3000
# ... other settings
```

### 3. Start Everything with Docker Compose
```bash
# Option 1: Full local stack (Kafka + Redis + App)
docker-compose --profile local-infra up --build -d

# Option 2: App only (if using external Kafka/Redis)
docker-compose up --build -d

# Verify all services are running
docker-compose ps

# Expected output for full stack:
# zookeeper               Running
# kafka                   Running  
# redis                   Running
# redis-insight           Running
# kafka-ui                Running
# kafka-redis-app         Running
```

### 4. Verify Application
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

## Environment Configuration

### Local Development (Default)
The default configuration uses local Docker containers for all services:

```bash
# .env file (automatically loaded)
KAFKA_BOOTSTRAP_SERVERS=kafka:29092
REDIS_HOST=redis
KAFKA_CONSUMER_GROUP_ID=message-consumer-group
PROCESSING_DELAY=3000
```

### Using External Services (Staging/Production)
For staging or production environments with managed Kafka/Redis:

#### Option 1: Environment File
```bash
# Create environment-specific file
cp .env.template .env.staging

# Edit for your environment
vim .env.staging
```

**Example .env.staging:**
```bash
KAFKA_BOOTSTRAP_SERVERS=kafka-staging.company.com:9092
REDIS_HOST=redis-staging.company.com
REDIS_PORT=6379
KAFKA_CONSUMER_GROUP_ID=message-consumer-group-staging
PROCESSING_DELAY=0
SPRING_PROFILES_ACTIVE=staging
```

**Run with staging config:**
```bash
docker-compose --env-file .env.staging up --build -d
```

#### Option 2: Environment Variables
```bash
# Run with production settings
KAFKA_BOOTSTRAP_SERVERS=kafka-prod.company.com:9092 \
REDIS_HOST=redis-prod.company.com \
KAFKA_CONSUMER_GROUP_ID=message-consumer-group-prod \
PROCESSING_DELAY=0 \
docker-compose up --build -d
```

#### Option 3: App-Only Mode
```bash
# Run only the Spring Boot app (no local Kafka/Redis)
docker-compose up app --build
```

### Configuration Variables

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka cluster address | `kafka:29092` | `kafka-prod.com:9092` |
| `REDIS_HOST` | Redis server host | `redis` | `redis-cluster.aws.com` |
| `REDIS_PORT` | Redis server port | `6379` | `6379` |
| `KAFKA_CONSUMER_GROUP_ID` | Consumer group identifier | `message-consumer-group` | `prod-consumers` |
| `PROCESSING_DELAY` | Demo delay in milliseconds | `3000` | `0` (production) |
| `SPRING_PROFILES_ACTIVE` | Spring profile | `docker` | `prod`, `staging` |

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
docker-compose --profile local-infra up --build -d
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

### Customizing Settings
```bash
# Disable processing delay
echo "PROCESSING_DELAY=0" >> .env
docker-compose restart app

# Change consumer group
echo "KAFKA_CONSUMER_GROUP_ID=my-custom-group" >> .env
docker-compose restart app

# Enable production profile
echo "SPRING_PROFILES_ACTIVE=prod" >> .env
docker-compose restart app
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

## Deployment Patterns

### Local Development
```bash
# Full stack with local infrastructure
docker-compose --profile local-infra up --build -d
```

### Staging Environment
```bash
# Using managed Kafka/Redis services
docker-compose --env-file .env.staging up --build -d
```

### Production Environment
```bash
# With production configuration
KAFKA_BOOTSTRAP_SERVERS=kafka-prod.company.com:9092 \
REDIS_HOST=redis-prod.company.com \
KAFKA_CONSUMER_GROUP_ID=message-consumer-group-prod \
PROCESSING_DELAY=0 \
SPRING_PROFILES_ACTIVE=prod \
docker-compose up --build -d
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
- Configurable delay makes Kafka processing visible
- Rich logging with emojis
- Real-time monitoring via Kafka UI

### ✅ **Environment Flexibility**
- Local development with Docker containers
- Staging/Production with managed services
- Configuration via environment variables

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
