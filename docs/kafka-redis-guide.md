# Kafka & Redis Deep Dive Guide

This guide explains how Publisher/Consumer patterns work in our Kafka & Redis playground, including architecture decisions and configuration details.

## Architecture Overview

### Message Flow
```
REST API → Publisher → Kafka Topic → Consumer → Redis Cache
    ↓                                             ↓
JSON Request                               Cached Message
```

### Components

1. **Publisher**: `KafkaMessagePublisher` - Sends messages to Kafka
2. **Consumer**: `KafkaMessageConsumer` - Receives messages from Kafka and caches in Redis
3. **Repository**: `RedisMessageRepository` - Manages Redis storage
4. **Topic Management**: `KafkaTopicConfig` - Auto-creates topics

## Publisher Configuration

### KafkaMessagePublisher
```java
@Component
public class KafkaMessagePublisher implements MessagePublisher {
    
    @Value("${app.kafka.topic.messages:messages}")
    private String topicName;  // Default: "messages"
    
    public void publish(Message message) {
        // Send to Kafka with message ID as key
        kafkaTemplate.send(topicName, message.getId(), messageJson);
    }
}
```

**Key Points:**
- **Topic**: `messages` (configurable via `app.kafka.topic.messages`)
- **Key Strategy**: Uses message ID for partitioning
- **Serialization**: JSON format for message content
- **Async Callbacks**: Logs success/failure of message sending

### Publisher Properties
```properties
# Producer configuration
spring.kafka.producer.key-serializer=org.apache.kafka.common.serialization.StringSerializer
spring.kafka.producer.value-serializer=org.apache.kafka.common.serialization.StringSerializer

# Performance settings (from KafkaConfig.java)
acks=all                    # Wait for all replicas
retries=3                   # Retry on failure
batch.size=16384           # Batch messages for efficiency
linger.ms=1                # Small delay for batching
```

## Consumer Configuration

### KafkaMessageConsumer
```java
@Component
public class KafkaMessageConsumer {
    
    @KafkaListener(
        topics = "${app.kafka.topic.messages:messages}",
        groupId = "${app.kafka.consumer.group-id:message-consumer-group}",
        containerFactory = "kafkaListenerContainerFactory"
    )
    public void handleMessage(@Payload String messageJson, ...) {
        // Process message and save to Redis
    }
}
```

**Configuration Details:**
- **Consumer Group**: `message-consumer-group`
- **Topic Subscription**: `messages` topic
- **Concurrency**: 3 consumer instances (parallel processing)
- **Offset Management**: Auto-commit every 1 second

### Consumer Group Behavior

#### Partition Assignment
```
Topic: messages (3 partitions)
Consumer Group: message-consumer-group (3 instances)

Partition 0 → Consumer Instance 1
Partition 1 → Consumer Instance 2  
Partition 2 → Consumer Instance 3
```

#### Load Balancing
- **Round-robin assignment** of partitions to consumers
- **Automatic rebalancing** when consumers join/leave
- **Offset tracking** per partition for fault tolerance

### Consumer Properties
```properties
# Consumer configuration
spring.kafka.consumer.group-id=message-consumer-group
spring.kafka.consumer.auto-offset-reset=earliest
spring.kafka.consumer.enable-auto-commit=true
spring.kafka.consumer.auto-commit-interval-ms=1000

# Processing settings
max.poll.records=100       # Messages per poll
session.timeout.ms=30000   # Consumer heartbeat timeout
```

## Topic Configuration

### Auto-Created Topics
Our `KafkaTopicConfig` automatically creates:

1. **messages** topic
   - **Partitions**: 3 (for parallel processing)
   - **Replication Factor**: 1 (single broker setup)
   - **Cleanup Policy**: Compact (keeps latest per key)

2. **messages.DLQ** topic
   - **Purpose**: Dead Letter Queue for failed messages
   - **Partitions**: 1 (error handling doesn't need parallelism)
   - **Future Use**: Error message storage and replay

### Topic Properties
```java
@Bean
public NewTopic messagesTopic() {
    return TopicBuilder.name("messages")
            .partitions(3)          // Parallel processing
            .replicas(1)            // Single broker
            .compact()              // Log compaction
            .build();
}
```

## Redis Integration

### Caching Strategy
The consumer saves messages to Redis for fast retrieval:

```java
// Redis key patterns
message:${messageId}        // Individual messages
messages                   // List of all message IDs
sender:${senderName}       // Messages by sender index
```

### Data Structure
```json
{
  "id": "uuid-12345",
  "content": "Hello, Kafka!",
  "sender": "developer",
  "timestamp": "2025-08-11T14:37:59.805",
  "type": "INFO"
}
```

### Redis Operations
- **Create**: Add to hash and update indexes
- **Read**: Get from hash by key
- **Index**: Maintain sender and type indexes
- **Cleanup**: Remove old messages based on timestamp

## Message Processing Flow

### 1. Message Creation (Publisher)
```java
// REST API creates message
Message message = Message.create(content, sender, type);

// Service publishes to Kafka
messagePublisher.publish(message);

// Simultaneously saves to Redis (for immediate availability)
messageRepository.save(message);
```

### 2. Message Consumption (Consumer)
```java
// Consumer receives from Kafka
@KafkaListener(topics = "messages")
public void handleMessage(String messageJson) {
    // Deserialize
    MessageEvent event = objectMapper.readValue(messageJson);
    Message message = convertToMessage(event);
    
    // Save to Redis (might be duplicate, but ensures consistency)
    messageRepository.save(message);
}
```

### 3. Why Both Save to Redis?
- **Immediate Availability**: REST API saves for instant read access
- **Durability**: Kafka consumer saves for cross-instance consistency
- **Idempotency**: Redis overwrites ensure no duplicates

## Monitoring and Observability

### Kafka Monitoring
```bash
# Consumer group status
docker exec -it kafka-redis-playground-kafka-1 kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --describe --group message-consumer-group

# Topic details
docker exec -it kafka-redis-playground-kafka-1 kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --describe --topic messages
```

**Key Metrics:**
- **LAG**: Messages waiting to be processed
- **OFFSET**: Current position in topic
- **PARTITION**: Which consumer handles which partition

### Redis Monitoring
```bash
# Redis info
docker exec -it kafka-redis-playground-redis-1 redis-cli info memory

# Key count
docker exec -it kafka-redis-playground-redis-1 redis-cli info keyspace

# Monitor commands
docker exec -it kafka-redis-playground-redis-1 redis-cli monitor
```

## Configuration Reference

### Application Properties
```properties
# Core topic configuration
app.kafka.topic.messages=messages
app.kafka.consumer.group-id=message-consumer-group

# Kafka connection
spring.kafka.bootstrap-servers=localhost:9092

# Redis connection
spring.data.redis.host=localhost
spring.data.redis.port=6379
```

### Environment Variables
```bash
# Override topic name
export APP_KAFKA_TOPIC_MESSAGES=my-custom-topic

# Override consumer group
export APP_KAFKA_CONSUMER_GROUP_ID=my-consumer-group

# Scale consumer instances
export KAFKA_CONSUMER_CONCURRENCY=5
```

## Advanced Scenarios

### Multiple Consumer Groups
```java
// Analytics consumer group (separate processing)
@KafkaListener(
    topics = "messages", 
    groupId = "analytics-consumer-group"
)
public void analyzeMessage(String messageJson) {
    // Different processing logic
    // Same messages, different consumer group
}
```

### Topic Scaling
```java
// Add more partitions for higher throughput
@Bean
public NewTopic scaledMessagesTopic() {
    return TopicBuilder.name("messages")
            .partitions(10)  // Increased from 3
            .replicas(1)
            .build();
}
```

### Error Handling
```java
// Future: Dead Letter Queue handling
@KafkaListener(topics = "messages.DLQ")
public void handleFailedMessage(String messageJson) {
    // Retry logic or manual intervention
}
```

## Best Practices

### Publisher
- **Use meaningful keys** for partitioning
- **Handle send failures** with retry logic
- **Monitor send latency** and throughput

### Consumer
- **Process idempotently** (handle duplicate messages)
- **Fail fast** on unrecoverable errors
- **Monitor consumer lag** to prevent backlog

### Topic Design
- **Right-size partitions** based on throughput needs
- **Consider retention policies** for storage management
- **Plan for scaling** with partition count

This setup provides a robust, scalable foundation for event-driven architecture with Kafka and Redis! 🚀
