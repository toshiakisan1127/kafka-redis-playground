# Spring Boot Application Structure

このディレクトリにはSpring Bootアプリケーションが含まれています。オニオンアーキテクチャを採用し、KafkaとRedisを活用したメッセージング システムです。

## アーキテクチャ

```
src/main/java/com/example/playground/
├── domain/                    # ドメイン層（最内層）
│   ├── model/                # ドメインモデル
│   │   ├── Message.java      # メッセージエンティティ
│   │   └── MessageType.java  # メッセージタイプenum
│   └── repository/           # ドメインリポジトリインターフェース
│       └── MessageRepository.java
├── application/              # アプリケーション層
│   └── service/             # アプリケーションサービス
│       ├── MessageService.java     # メッセージビジネスロジック
│       └── MessagePublisher.java   # Kafka送信インターフェース
├── infrastructure/          # インフラ層（最外層）
│   ├── config/             # 設定クラス
│   │   ├── KafkaConfig.java
│   │   └── RedisConfig.java
│   ├── messaging/          # Kafkaメッセージング
│   │   ├── KafkaMessagePublisher.java
│   │   └── KafkaMessageConsumer.java
│   └── repository/         # リポジトリ実装
│       └── RedisMessageRepository.java
└── presentation/           # プレゼンテーション層
    ├── controller/         # REST APIコントローラー
    │   └── MessageController.java
    └── dto/               # データ転送オブジェクト
        ├── CreateMessageRequest.java
        └── MessageResponse.java
```

## 主要な機能

- **メッセージ作成**: REST APIでメッセージを作成
- **Kafka送信**: 作成されたメッセージをKafkaトピックに送信
- **Kafka受信**: Kafkaからメッセージを受信してRedisに保存
- **Redis保存**: メッセージをRedisにキャッシュ
- **メッセージ取得**: 様々な条件でメッセージを検索・取得

## API エンドポイント

### メッセージ操作
- `POST /api/messages` - メッセージを作成してKafkaに送信
- `GET /api/messages` - 全てのメッセージを取得
- `GET /api/messages/{id}` - IDでメッセージを取得
- `GET /api/messages/sender/{sender}` - 送信者でメッセージを取得
- `GET /api/messages/urgent` - 緊急メッセージ（ERROR、WARNING）を取得
- `DELETE /api/messages/{id}` - メッセージを削除
- `DELETE /api/messages/cleanup?minutes={minutes}` - 古いメッセージを削除

### リクエスト例

```bash
# メッセージ作成
curl -X POST http://localhost:8080/api/messages \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Hello, Kafka and Redis!",
    "sender": "user1",
    "type": "INFO"
  }'

# 全メッセージ取得
curl http://localhost:8080/api/messages

# 緊急メッセージ取得
curl http://localhost:8080/api/messages/urgent
```

## 起動方法

1. **前提条件**: docker-compose.ymlでKafkaとRedisを起動
```bash
docker-compose up -d
```

2. **アプリケーション起動**:
```bash
./mvnw spring-boot:run
```

## 設定

`src/main/resources/application.properties`で以下の設定が可能：

- Kafka接続設定
- Redis接続設定
- トピック名
- コンシューマーグループID
- ログレベル

## テスト

```bash
./mvnw test
```

## オニオンアーキテクチャの特徴

1. **依存関係の方向**: 外層から内層への一方向の依存
2. **ドメイン層の独立性**: ビジネスロジックが外部技術に依存しない
3. **インターフェースによる抽象化**: リポジトリやサービスはインターフェースで定義
4. **テスタビリティ**: 各層が独立してテスト可能
