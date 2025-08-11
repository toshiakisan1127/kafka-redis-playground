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
    
    Service->>+Repository: save(message)
    Repository->>Repository: MessageDto変換
    Repository->>+Redis: set(key, json)
    Redis-->>-Repository: OK
    Repository->>+Redis: rightPush(lists, messageId)
    Redis-->>-Repository: OK
    Repository-->>-Service: Message
    
    Service-->>-Controller: Message
    Controller->>Controller: MessageResponse.from()
    Controller-->>-Client: 201 Created + MessageResponse
    
    Note over Kafka,Consumer: 非同期処理
    Kafka->>+Consumer: @KafkaListener
    Consumer->>Consumer: JSON変換
    Consumer->>+Repository: save(message)
    Repository->>+Redis: 保存処理
    Redis-->>-Repository: OK
    Repository-->>-Consumer: Message
    Consumer-->>-Kafka: ACK
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
    
    Repository->>+Redis: lrange("messages", 0, -1)
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
    
    Repository->>+Redis: lrange("messages", 0, -1)
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
            Repository->>+Redis: lrem("messages", messageId)
            Redis-->>-Repository: OK
            Repository->>+Redis: lrem("sender:xxx", messageId)
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
    participant Consumer as KafkaMessageConsumer

    Client->>+Controller: POST /api/messages (不正データ)
    Controller->>Controller: @Valid検証
    
    alt バリデーションエラー
        Controller-->>Client: 400 Bad Request
    else バリデーション成功
        Controller->>+Service: createAndSendMessage()
        Service->>+Publisher: publish(message)
        Publisher->>+Kafka: send()
        
        alt Kafka送信失敗
            Kafka-->>-Publisher: Exception
            Publisher->>Publisher: ログ出力
            Publisher-->>Service: RuntimeException
            Service-->>Controller: RuntimeException
            Controller-->>-Client: 500 Internal Server Error
        else Kafka送信成功
            Kafka-->>-Publisher: Success
            Publisher-->>-Service: void
            Service-->>-Controller: Message
            Controller-->>-Client: 201 Created
        end
    end
    
    Note over Consumer: 非同期エラー処理
    Kafka->>+Consumer: 不正なメッセージ
    Consumer->>Consumer: JSON変換失敗
    Consumer->>Consumer: ログ出力
    Note over Consumer: DLQ送信<br/>（将来実装予定）
    Consumer-->>-Kafka: NACK
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

### Gradleタスク実行例

```bash
# アプリケーション起動
./gradlew bootRun

# 開発用設定でアプリケーション起動
./gradlew runApp

# テスト実行
./gradlew test

# JARビルド
./gradlew bootJar

# 依存関係確認
./gradlew dependencies

# 特定の依存関係詳細
./gradlew dependencyInsight --dependency spring-kafka
```

### API テスト例

```bash
# アプリケーション起動後
curl -X POST http://localhost:8080/api/messages \
  -H "Content-Type: application/json" \
  -d '{"content": "Test message", "sender": "developer", "type": "INFO"}'

# メッセージ確認
curl http://localhost:8080/api/messages
```

## 注記

### アーキテクチャの特徴
- **依存関係の方向**: 外層から内層への一方向
- **ドメイン層の独立性**: `Message`クラスは外部技術に依存しない
- **インターフェース分離**: `MessageRepository`と`MessagePublisher`でインフラ層を抽象化

### 非同期処理
- Kafkaへの送信は同期的だが、受信処理は非同期
- メッセージの二重保存を避けるため、Redisでの重複チェックが可能

### エラー処理
- バリデーションエラーは400番台で返却
- インフラエラーは500番台で返却
- Kafkaの非同期エラーはログ出力とDLQ（将来実装）で対応

### ビルドツール
- **Gradle 8.8**を使用
- **Java 21**対応
- **Spring Boot 3.3.2**との統合
- パフォーマンス最適化設定済み（`gradle.properties`）
