# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

### Build & Test
```bash
# Build the application
./gradlew build

# Run tests
./gradlew test

# Run specific test
./gradlew test --tests "MessageTest"

# Run application locally (requires Java 21)
./gradlew runApp

# Build Docker image
./gradlew buildDockerImage
```

### Docker Development Environment
```bash
# Start full stack (Kafka, Redis, Spring Boot app)
docker-compose --profile local-infra up --build -d

# Start only infrastructure (for local development)
docker-compose --profile local-infra up -d kafka redis zookeeper kafka-ui redis-insight

# Stop all services
docker-compose down

# View logs
docker-compose logs -f app
docker-compose logs -f kafka
```

### Environment Configuration
- Copy `.env.template` to `.env` for local overrides
- Default configuration in `src/main/resources/application.properties`
- Environment variables override properties file values

## Code Architecture

This project implements **Onion Architecture** with clean separation of concerns:

### Layer Structure
```
📦 Domain Layer (src/main/java/com/example/playground/domain/)
├── model/           # Core business entities (Message, MessageType)
└── repository/      # Repository interfaces

📦 Application Layer (src/main/java/com/example/playground/application/)
└── service/         # Business use cases (MessageService, MessagePublisher)

📦 Infrastructure Layer (src/main/java/com/example/playground/infrastructure/)
├── config/          # Kafka, Redis configuration
├── messaging/       # Kafka producers/consumers  
└── repository/      # Repository implementations (RedisMessageRepository)

📦 Presentation Layer (src/main/java/com/example/playground/presentation/)
├── controller/      # REST API endpoints (MessageController)
└── dto/             # Request/Response objects
```

### Key Architectural Patterns
- **Event-Driven Architecture**: Messages flow through Kafka for async processing
- **Repository Pattern**: `MessageRepository` interface with Redis implementation
- **Domain Models**: `Message` with business logic methods (`isUrgent()`, `isOlderThan()`)
- **Dependency Injection**: All layers use constructor injection
- **DTO Mapping**: Separate DTOs for API contracts vs domain models

### Message Flow
1. REST API receives message creation request
2. `MessageService` creates domain `Message` and publishes to Kafka
3. `KafkaMessageConsumer` processes message asynchronously  
4. Consumer saves message to Redis via `MessageRepository`
5. API queries fetch messages from Redis

### Critical Components
- **Message**: Immutable domain model with factory method and business logic
- **MessageService**: Core application service orchestrating message operations
- **KafkaMessageConsumer**: Handles async message processing with configurable delay
- **RedisMessageRepository**: Implements duplicate prevention using Redis Sets

## Key Configuration

### Required Environment Variables
- `KAFKA_BOOTSTRAP_SERVERS`: Kafka broker addresses
- `REDIS_HOST`: Redis server hostname  
- `PROCESSING_DELAY`: Consumer delay for demo purposes (default: 3000ms)

### Important Properties
- `app.kafka.topic.messages`: Kafka topic name
- `app.kafka.consumer.processing-delay`: Artificial delay for observing Kafka processing
- `spring.data.redis.database`: Redis database number for message storage

### Service Access Points
- **Application**: http://localhost:8888
- **Kafka UI**: http://localhost:8080 
- **Redis Insight**: http://localhost:8001

## Testing Strategy

### Unit Tests
- Domain model tests in `src/test/java/com/example/playground/domain/model/`
- Use JUnit 5 (`@Test` annotations)
- Run with: `./gradlew test`

### Integration Testing
- Project uses Testcontainers for Kafka and Redis integration tests
- Dependencies: `testcontainers:kafka`, `testcontainers:junit-jupiter`

## Development Notes

### Java Version
- **Java 21** (Amazon Corretto) required
- Uses modern Java features like `String.valueOf()`, records where applicable
- Gradle toolchain configured for Java 21

### Message Processing
- Consumer has configurable 3-second delay for demonstration purposes
- Redis Sets prevent duplicate message IDs across multiple app instances
- All timestamps use `LocalDateTime` with ISO-8601 serialization

### Error Handling
- Kafka consumer includes comprehensive error logging with emojis for visibility
- Failed messages logged but not sent to DLQ (implementation placeholder exists)
- Validation on API requests using `@Valid` annotations