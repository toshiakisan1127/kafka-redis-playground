# Spring Boot Application Structure

このディレクトリにはSpring Bootアプリケーションが含まれています。オニオンアーキテクチャを採用し、最新の**Spring Boot 3.5.4**と**Amazon Corretto 21**を使用したKafkaとRedisのメッセージング システムです。

## 技術スタック

- **Spring Boot 3.5.4** - 最新安定版フレームワーク
- **Amazon Corretto 21** - 企業グレードJava実行環境
- **Gradle 8.10.2** - モダンビルドツール
- **Apache Kafka 3.9+** - イベントストリーミング
- **Redis 7.0+** - インメモリデータストア

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
# メッセージ作成（Amazon Corretto 21対応）
curl -X POST http://localhost:8888/api/messages \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Hello from Amazon Corretto 21 with Spring Boot 3.5.4!",
    "sender": "developer",
    "type": "INFO"
  }'

# 全メッセージ取得
curl http://localhost:8888/api/messages

# 緊急メッセージ取得
curl http://localhost:8888/api/messages/urgent
```

## 起動方法

### 前提条件
- **Amazon Corretto 21** のインストール（Docker使用時は不要）
- **Docker と Docker Compose** のインストール

### Amazon Corretto 21 インストール

```bash
# SDKMAN を使用（推奨）
curl -s "https://get.sdkman.io" | bash
sdk install java 21.0.1-amzn

# バージョン確認
java --version
# 期待値: openjdk 21.x.x Amazon Corretto
```

### アプリケーション起動

1. **インフラサービス起動**:
```bash
# 完全なローカル環境（推奨）
docker-compose --profile local-infra up --build -d

# アプリケーションのみ（外部Kafka/Redisを使用）
docker-compose up --build -d
```

2. **ローカル開発でSpring Bootアプリケーション起動**:
```bash
# 標準起動
./gradlew bootRun

# 開発用起動（JVM最適化設定済み）
./gradlew runApp

# プロダクション用ビルド
./gradlew bootJar
java -jar build/libs/kafka-redis-playground-1.0.0.jar
```

## Gradleタスク

### アプリケーション実行
```bash
./gradlew bootRun                # 標準起動
./gradlew runApp                 # 開発用起動（最適化設定）
./gradlew bootJar                # 実行可能JAR作成
```

### 開発・テスト
```bash
./gradlew test                   # テスト実行
./gradlew check                  # 全チェック実行
./gradlew checkFormat            # コードフォーマット確認
```

### 依存関係・ドキュメント
```bash
./gradlew dependencies           # 依存関係ツリー表示
./gradlew dependencyGraph        # 依存関係レポート生成
./gradlew tasks                  # 利用可能タスク一覧
```

### Docker関連
```bash
./gradlew buildDockerImage       # Dockerイメージビルド
```

## Amazon Corretto 21 の特徴

このプロジェクトではAmazon Corretto 21の以下の特徴を活用しています：

### 企業グレードの安定性
- AWS最適化されたOpenJDK分散
- 長期サポート（LTS）版
- プロダクション環境での実績

### パフォーマンス最適化
```gradle
// build.gradle で自動設定済み
tasks.withType(JavaCompile) {\n    options.compilerArgs += [
        '-Xlint:unchecked',
        '-Xlint:deprecation'
    ]
}
```

## 設定

### application.properties
`src/main/resources/application.properties`で以下の設定が可能：

```properties
# アプリケーション設定（Spring Boot 3.5.4対応）
spring.application.name=kafka-redis-playground
server.port=8888

# Kafka設定（最新バージョン対応）
spring.kafka.bootstrap-servers=localhost:9092
app.kafka.topic.messages=messages

# Redis設定
spring.data.redis.host=localhost
spring.data.redis.port=6379

# ログ設定
logging.level.com.example.playground=DEBUG
```

### 環境変数
```bash
export SPRING_PROFILES_ACTIVE=dev
export JAVA_OPTS="-Xms256m -Xmx512m"
```

## モニタリング

### Actuatorエンドポイント
```bash
# ヘルスチェック
curl http://localhost:8888/actuator/health

# メトリクス
curl http://localhost:8888/actuator/metrics

# アプリケーション情報
curl http://localhost:8888/actuator/info
```

### 管理UI
- **Kafka UI**: http://localhost:8080
- **Redis Insight**: http://localhost:8001

## テスト

```bash
# 全テスト実行
./gradlew test

# 特定テストクラス実行
./gradlew test --tests MessageTest

# カバレッジレポート生成
./gradlew test jacocoTestReport
```

## パフォーマンス最適化

### JVM設定（Amazon Corretto 21最適化）
```bash
export JAVA_OPTS="
  -Xms256m
  -Xmx512m
  -XX:+UseZGC
  -XX:+UnlockExperimentalVMOptions
"
```

### Gradle最適化
```properties
# gradle.properties で設定済み
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.jvmargs=-Xmx2048m
```

## トラブルシューティング

### Amazon Corretto 21 関連
```bash
# Java バージョン確認
java --version

# Amazon Corretto確認
java -XshowSettings:properties -version | grep java.vendor

# SDKMAN でバージョン切り替え
sdk use java 21.0.1-amzn
```

### 依存関係の問題
```bash
# キャッシュクリア
./gradlew clean build --refresh-dependencies

# 依存関係競合確認
./gradlew dependencyInsight --dependency spring-boot
```

## ビルド成果物

- **実行可能JAR**: `build/libs/kafka-redis-playground-1.0.0.jar`
- **テストレポート**: `build/reports/tests/test/index.html`
- **依存関係レポート**: `./gradlew dependencyInsight --dependency <dependency-name>`

## オニオンアーキテクチャの特徴

1. **依存関係の方向**: 外層から内層への一方向の依存
2. **ドメイン層の独立性**: ビジネスロジックが外部技術に依存しない
3. **インターフェースによる抽象化**: リポジトリやサービスはインターフェースで定義
4. **テスタビリティ**: 各層が独立してテスト可能
5. **モダンJava活用**: Amazon Corretto 21の安定性を活用

## プロジェクト構成

```
├── build.gradle                              # Gradle設定（Amazon Corretto 21対応）
├── gradle.properties                         # ビルド最適化設定
├── settings.gradle                           # プロジェクト設定
├── gradle/wrapper/                           # Gradle Wrapper
│   └── gradle-wrapper.properties
├── src/main/java/com/example/playground/
│   ├── KafkaRedisPlaygroundApplication.java  # メインクラス
│   ├── domain/                               # ドメイン層
│   ├── application/                          # アプリケーション層
│   ├── infrastructure/                       # インフラ層
│   └── presentation/                         # プレゼンテーション層
├── src/main/resources/
│   └── application.properties                # 設定ファイル
└── src/test/java/                           # テストクラス
```

## 今後の拡張予定

- **Amazon Corretto 21の活用**: Virtual Threads、パフォーマンス最適化等
- **Spring Boot 3.5の新機能**: 最新のSpring機能活用
- **パフォーマンス最適化**: ZGCガベージコレクター活用
- **モニタリング強化**: Micrometer Tracingとの統合
- **セキュリティ強化**: Spring Security 6.5の活用
