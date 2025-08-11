# Multi Producer/Consumer Demo Guide

このドキュメントでは、3つのProducerと3つのConsumerを使ったKafka Consumer Groupの負荷分散を体験する方法を説明します。

## 🎯 学習目標

- Consumer Groupでの自動負荷分散を理解する
- Kafka Partitioningの効果を確認する
- 異なる処理速度のConsumerの動作を観察する
- スケーラブルなメッセージング アーキテクチャを学ぶ

## 🏗️ アーキテクチャ概要

```
┌─────────────┐    ┌─────────────────────────────────┐    ┌─────────────────┐
│ Producer-A  │    │        Kafka Topic              │    │   Consumer-A    │
│ Producer-B  │───▶│      (3 Partitions)            │───▶│   Consumer-B    │ 
│ Producer-C  │    │                                 │    │   Consumer-C    │
└─────────────┘    └─────────────────────────────────┘    └─────────────────┘
                                                                     │
                                                            ┌─────────────────┐
                                                            │      Redis      │
                                                            │  (Message Store)│
                                                            └─────────────────┘
```

### Consumer の特徴

| Consumer | Processing Speed | Delay | Color | Description |
|----------|------------------|-------|-------|-------------|
| Consumer-A | Standard | 1000ms | 🟦 Blue | 標準的な処理速度 |
| Consumer-B | Slower | 1500ms | 🟩 Green | 遅い処理をシミュレート |
| Consumer-C | Faster | 800ms | 🟨 Yellow | 高速処理をシミュレート |

## 🚀 Demo の実行

### 1. 環境の起動

```bash
# Docker Composeで全環境を起動
docker-compose --profile local-infra up --build -d

# ログの確認
docker-compose logs -f app
```

### 2. バッチメッセージ送信デモ

3つのProducerから同時にメッセージを送信し、Consumer Groupでの分散処理を確認します。

```bash
# 15メッセージを3つのProducerから送信 (各Producer 5メッセージ)
curl -X POST "http://localhost:8888/api/multi-demo/send-batch?count=15"

# 処理状況の確認
curl http://localhost:8888/api/multi-demo/consumer-status
```

**期待される結果:**
```json
{
  "totalProcessedMessages": 15,
  "producerAMessages": 6,
  "producerBMessages": 5,
  "producerCMessages": 4,
  "orderMessages": 6,
  "notificationMessages": 5,
  "eventMessages": 4,
  "timestamp": 1691771234567
}
```

### 3. ログでの確認

各Consumerがどのメッセージを処理しているかを確認:

```bash
# 特定のConsumerのログをフィルタ
docker-compose logs app | grep "Consumer-A"
docker-compose logs app | grep "Consumer-B" 
docker-compose logs app | grep "Consumer-C"

# リアルタイムでの確認
docker-compose logs -f app | grep -E "Consumer-[ABC]"
```

**ログ例:**
```
🟦 [Consumer-A] Received message: key=msg-123, partition=0, offset=5
🟩 [Consumer-B] Received message: key=msg-124, partition=1, offset=3
🟨 [Consumer-C] Received message: key=msg-125, partition=2, offset=7
```

### 4. ストレステスト

高負荷での Consumer Group の動作を確認:

```bash
# 30秒間、毎秒10メッセージを送信
curl -X POST "http://localhost:8888/api/multi-demo/stress-test?duration=30&ratePerSecond=10"

# リアルタイムで処理状況をモニタリング
watch -n 2 'curl -s http://localhost:8888/api/multi-demo/consumer-status | jq'
```

## 📊 Kafka UIでの観察

1. **Kafka UI** (http://localhost:8080) にアクセス
2. **Topics** → **messages** を選択
3. **Consumers** タブで Consumer Group の状態を確認

### 確認ポイント

1. **Partition Assignment**: どのConsumerがどのPartitionを担当しているか
2. **Lag**: 各Consumerの処理遅延
3. **Offset**: 各Partitionでの処理進捗

## 🔍 観察ポイント

### 1. 負荷分散の確認

```bash
# 複数回ステータスを確認して分散を確認
for i in {1..3}; do
  echo "=== Check $i ==="
  curl -s http://localhost:8888/api/multi-demo/consumer-status | jq '.producerAMessages, .producerBMessages, .producerCMessages'
  sleep 5
done
```

### 2. 処理速度の違い

異なる処理速度のConsumerがどのように負荷分散に影響するかを観察:

- Consumer-C (高速) がより多くのメッセージを処理する可能性
- Consumer-B (低速) の処理が遅れる場合の再分散

### 3. Partition とのマッピング

```bash
# Kafkaのパーティション情報を確認
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --describe --topic messages
```

## 🎓 学習効果の確認

### Consumer Group の理解度チェック

1. **Q: なぜ同一Consumer Group内でメッセージが分散されるのか？**
   - A: Kafkaが自動的にPartitionをConsumerに割り当て、各メッセージは1つのConsumerのみが処理する

2. **Q: Consumer-B が遅い場合、どうなるか？**
   - A: 他のConsumerが処理を継続し、Consumer-BのPartitionのみが遅れる

3. **Q: Consumerを追加/削除した場合どうなるか？**
   - A: Consumer Group の再バランスが発生し、Partition割り当てが変更される

### 実践的な実験

```bash
# 1. 単一Producerからの大量送信
curl -X POST "http://localhost:8888/api/multi-demo/send-batch?count=30"

# 2. 高頻度ストレステスト
curl -X POST "http://localhost:8888/api/multi-demo/stress-test?duration=60&ratePerSecond=20"

# 3. 処理状況の継続監視
watch -n 1 'curl -s http://localhost:8888/api/multi-demo/consumer-status'
```

## 🛠️ トラブルシューティング

### Consumer が処理しない場合

```bash
# Consumer Group の状態確認
docker exec kafka kafka-consumer-groups --bootstrap-server localhost:9092 --describe --group message-consumer-group

# アプリケーションログの確認
docker-compose logs app | tail -50
```

### Partition への分散が偏る場合

```bash
# メッセージキーの確認（キーによってPartitionが決まる）
curl -s http://localhost:8888/api/multi-demo/consumer-status | jq

# Partition情報の確認
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --describe --topic messages
```

## 📚 次のステップ

この基本的な Multi Producer/Consumer 構成を理解したら、以下の発展的なトピックに進むことをお勧めします:

1. **Kafka Streams** - ストリーム処理の実装
2. **複数Topic間の連携** - イベント駆動アーキテクチャ
3. **Dead Letter Queue** - エラーハンドリング
4. **Kafka Connect** - 外部システムとの連携
5. **Schema Registry** - メッセージスキーマ管理

このデモが実務レベルのKafka理解への第一歩となることを願っています！🚀
