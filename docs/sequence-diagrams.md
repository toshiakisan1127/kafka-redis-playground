# Sequence Diagrams

このドキュメントでは、Spring Bootアプリケーションの主要なフローをシーケンス図で説明します。

## メッセージ作成フロー

```mermaid
sequenceDiagram
    participant Client as クライアント
    participant Controller as MessageController
    participant Service as MessageService
    participant Publisher as KafkaMessagePublisher
    participant Kafka as Kafka Broker
    participant Consumer as KafkaMessageConsumer
    participant Repository as RedisMessageRepository
    participant Redis as Redis

    Client->>+Controller: POST /api/messages
    Note over Client,Controller: {"content": "Hello", "sender": "user1", "type": "INFO"}
    
    Controller->>+Service: createAndSendMessage()
    Service->>Service: Message.create()
    Note over Service: ドメインモデル生成<br/>ID、timestamp自動設定
    
    Service->>+Publisher: publish(message)
    Publisher->>Publisher: JSON変換
    Publisher->>+Kafka: send(topic, messageId, messageJson)
    Kafka-->>-Publisher: SendResult
    Publisher-->>-Service: void
    
    Note over Kafka,Consumer: 非同期処理
    Kafka->>+Consumer: @KafkaListener
    Consumer->>Consumer: JSON変換
    Consumer->>+Repository: save(message)
    Repository->>+Redis: 保存処理（Redis Sets使用）
    Redis-->>-Repository: OK
    Repository-->>-Consumer: Message
    Consumer-->>-Kafka: ACK
    
    Service-->>-Controller: Message
    Controller->>Controller: MessageResponse.from()
    Controller-->>-Client: 201 Created + MessageResponse
```

## メッセージ取得フロー

```mermaid
sequenceDiagram
    participant Client as クライアント
    participant Controller as MessageController
    participant Service as MessageService
    participant Repository as RedisMessageRepository
    participant Redis as Redis

    Client->>+Controller: GET /api/messages
    Controller->>+Service: getAllMessages()
    Service->>+Repository: findAll()
    
    Repository->>+Redis: smembers("messages")
    Note over Repository,Redis: Redis Sets使用で重複なし
    Redis-->>-Repository: messageIds[]
    
    loop messageIds
        Repository->>+Redis: get("message:id")
        Redis-->>-Repository: messageJson
        Repository->>Repository: JSON→MessageDto→Message変換
    end
    
    Repository-->>-Service: List<Message>
    Service-->>-Controller: List<Message>
    
    loop messages
        Controller->>Controller: MessageResponse.from()
    end
    
    Controller-->>-Client: 200 OK + List<MessageResponse>
```

## 緊急メッセージ取得フロー

```mermaid
sequenceDiagram
    participant Client as クライアント
    participant Controller as MessageController
    participant Service as MessageService
    participant Repository as RedisMessageRepository
    participant Redis as Redis

    Client->>+Controller: GET /api/messages/urgent
    Controller->>+Service: getUrgentMessages()
    Service->>+Repository: findAll()
    
    Repository->>+Redis: smembers("messages")
    Redis-->>-Repository: messageIds[]
    
    loop messageIds
        Repository->>+Redis: get("message:id")
        Redis-->>-Repository: messageJson
        Repository->>Repository: JSON→Message変換
    end
    
    Repository-->>-Service: List<Message>
    
    Service->>Service: stream().filter(Message::isUrgent)
    Note over Service: ドメインロジック<br/>ERROR, WARNINGのみ抽出
    
    Service-->>-Controller: List<Message> (urgent only)
    Controller-->>-Client: 200 OK + List<MessageResponse>
```

## 古いメッセージ削除フロー

```mermaid
sequenceDiagram
    participant Client as クライアント
    participant Controller as MessageController
    participant Service as MessageService
    participant Repository as RedisMessageRepository
    participant Redis as Redis

    Client->>+Controller: DELETE /api/messages/cleanup?minutes=60
    Controller->>+Service: cleanupOldMessages(60)
    Service->>+Repository: deleteOldMessages(60)
    
    Repository->>+Repository: findAll()
    Repository->>+Redis: 全メッセージ取得
    Redis-->>-Repository: List<Message>
    Repository-->>-Repository: List<Message>
    
    Repository->>Repository: cutoffTime = now - 60分
    
    loop messages
        Repository->>Repository: message.timestamp < cutoffTime?
        alt 古いメッセージの場合
            Repository->>+Redis: delete("message:id")
            Redis-->>-Repository: OK
            Repository->>+Redis: srem("messages", messageId)
            Redis-->>-Repository: OK
            Repository->>+Redis: srem("sender:xxx", messageId)
            Redis-->>-Repository: OK
            Repository->>Repository: deletedCount++
        end
    end
    
    Repository-->>-Service: deletedCount
    Service-->>-Controller: deletedCount
    Controller->>Controller: CleanupResponse生成
    Controller-->>-Client: 200 OK + CleanupResponse
```

## エラーハンドリングフロー

```mermaid
sequenceDiagram
    participant Client as クライアント
    participant Controller as MessageController
    participant Service as MessageService
    participant Publisher as KafkaMessagePublisher
    participant Kafka as Kafka Broker

    Client->>+Controller: POST /api/messages (不正データ)
    Controller->>Controller: @Valid検証
    
    alt バリデーションエラー
        Controller-->>-Client: 400 Bad Request
    else バリデーション成功
        Controller->>+Service: createAndSendMessage()
        Service->>+Publisher: publish(message)
        Publisher->>+Kafka: send()
        
        alt Kafka送信失敗
            Kafka-->>-Publisher: Exception
            Publisher->>Publisher: ログ出力
            Publisher-->>-Service: RuntimeException
            Service-->>-Controller: RuntimeException
            Controller-->>-Client: 500 Internal Server Error
        else Kafka送信成功
            Kafka-->>-Publisher: Success
            Publisher-->>-Service: void
            Service-->>-Controller: Message
            Controller-->>-Client: 201 Created
        end
    end
```

## 非同期Consumer エラーフロー

```mermaid
sequenceDiagram
    participant Kafka as Kafka Broker
    participant Consumer as KafkaMessageConsumer
    participant Repository as RedisMessageRepository

    Note over Kafka,Consumer: 非同期エラー処理
    Kafka->>+Consumer: 不正なメッセージ
    Consumer->>Consumer: JSON変換失敗
    Consumer->>Consumer: ログ出力
    Note over Consumer: DLQ送信<br/>（将来実装予定）
    Consumer-->>-Kafka: NACK
```

## Redisエラーハンドリングフロー

```mermaid
sequenceDiagram
    participant Client as クライアント
    participant Controller as MessageController
    participant Service as MessageService
    participant Repository as RedisMessageRepository
    participant Redis as Redis

    Client->>+Controller: GET /api/messages
    Controller->>+Service: getAllMessages()
    Service->>+Repository: findAll()
    
    alt Redis接続成功
        Repository->>+Redis: smembers("messages")
        Redis-->>-Repository: messageIds[]
        
        loop messageIds
            Repository->>+Redis: get("message:id")
            alt データ取得成功
                Redis-->>-Repository: messageJson
            else データ取得失敗
                Redis-->>-Repository: null
                Repository->>Repository: ログ出力（警告）
            end
        end
        
        Repository-->>-Service: List<Message>
        Service-->>-Controller: List<Message>
        Controller-->>-Client: 200 OK + List<MessageResponse>
        
    else Redis接続失敗
        Repository->>+Redis: smembers("messages")
        Redis-->>-Repository: ConnectionException
        Repository->>Repository: ログ出力（エラー）
        Repository-->>-Service: RedisConnectionException
        Service-->>-Controller: RedisConnectionException
        Controller-->>-Client: 503 Service Unavailable
    end
```

## バリデーションエラーフロー

```mermaid
sequenceDiagram
    participant Client as クライアント
    participant Controller as MessageController
    participant GlobalHandler as @ControllerAdvice

    Client->>+Controller: POST /api/messages (不正データ)
    Controller->>Controller: @Valid検証失敗
    Controller->>+GlobalHandler: MethodArgumentNotValidException
    GlobalHandler->>GlobalHandler: エラーレスポンス作成
    GlobalHandler-->>-Controller: ErrorResponse
    Controller-->>-Client: 400 Bad Request + ErrorResponse
```

## ビジネスロジックエラーフロー

```mermaid
sequenceDiagram
    participant Client as クライアント
    participant Controller as MessageController
    participant Service as MessageService
    participant GlobalHandler as @ControllerAdvice

    Client->>+Controller: POST /api/messages
    Controller->>+Service: createAndSendMessage()
    Service->>Service: ビジネスルール検証失敗
    Service-->>-Controller: IllegalArgumentException
    Controller->>+GlobalHandler: IllegalArgumentException
    GlobalHandler->>GlobalHandler: エラーレスポンス作成
    GlobalHandler-->>-Controller: ErrorResponse
    Controller-->>-Client: 422 Unprocessable Entity + ErrorResponse
```

## 依存関係とアーキテクチャ

```mermaid
graph TD
    A[Client] --> B[MessageController]
    B --> C[MessageService]
    C --> D[MessageRepository Interface]
    C --> E[MessagePublisher Interface]
    
    F[RedisMessageRepository] -.-> D
    G[KafkaMessagePublisher] -.-> E
    H[KafkaMessageConsumer] --> D
    
    F --> I[Redis]
    G --> J[Kafka]
    H --> J
    
    style D fill:#e1f5fe
    style E fill:#e1f5fe
    style C fill:#f3e5f5
    style B fill:#fff3e0
    style F fill:#e8f5e8
    style G fill:#e8f5e8
    style H fill:#e8f5e8
    
    classDef domain fill:#e1f5fe
    classDef application fill:#f3e5f5
    classDef presentation fill:#fff3e0
    classDef infrastructure fill:#e8f5e8
```

## 開発・テスト用コマンド

### Docker環境での開発

```bash
# 完全な環境起動
docker-compose --profile local-infra up --build -d

# アプリケーションのみ再ビルド
docker-compose build app
docker-compose restart app

# ログ確認
docker-compose logs -f app

# テスト実行（コンテナ内）
docker-compose exec app ./gradlew test

# JARビルド
docker-compose exec app ./gradlew bootJar

# 依存関係確認
docker-compose exec app ./gradlew dependencies

# 特定の依存関係詳細
docker-compose exec app ./gradlew dependencyInsight --dependency spring-kafka
```

### API テスト例

```bash
# アプリケーション起動後
curl -X POST http://localhost:8888/api/messages \
  -H "Content-Type: application/json" \
  -d '{"content": "Test message", "sender": "developer", "type": "INFO"}'

# メッセージ確認
curl http://localhost:8888/api/messages
```

### CI/CD用コマンド

```bash
# GitHub Actions等のCI環境で
docker build -t kafka-redis-playground .
docker run --rm kafka-redis-playground ./gradlew test jacocoTestReport

# またはdocker-composeでテスト
docker-compose run --rm app ./gradlew test jacocoTestReport
```

## 注記

### アーキテクチャの特徴
- **依存関係の方向**: 外層から内層への一方向
- **ドメイン層の独立性**: `Message`クラスは外部技術に依存しない
- **インターフェース分離**: `MessageRepository`と`MessagePublisher`でインフラ層を抽象化

### 非同期処理とデータ整合性
- **単一保存**: Publisherは送信のみ、Consumerが保存を担当
- **Redis Sets使用**: 重複メッセージIDを自動で排除
- **観察可能**: 3秒遅延でKafka処理フローを可視化

### エラー処理
- **バリデーションエラー**: 400 Bad Request
- **ビジネスロジックエラー**: 422 Unprocessable Entity
- **Kafkaエラー**: 500 Internal Server Error
- **Redisエラー**: 503 Service Unavailable

### エラーハンドリング修正点
- **パーティシパント管理**: 非アクティブエラーを完全修正
- **フロー分離**: 各エラータイプを独立したフローに分離
- **統一的処理**: `@ControllerAdvice`によるグローバルエラーハンドリング

### 技術スタック
- **Amazon Corretto 21** - 企業グレードJava環境
- **Spring Boot 3.5.4** - 最新フレームワーク
- **Gradle 8.10.2** - モダンビルドツール
- **完全Docker化** - ローカル開発からプロダクションまで