package com.example.playground.presentation.controller;

import com.example.playground.application.service.MessageService;
import com.example.playground.domain.model.Message;
import com.example.playground.domain.model.MessageType;
import com.example.playground.domain.repository.MessageRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;
import java.util.stream.IntStream;

/**
 * 複数Producer/Consumer構成のデモコントローラー
 * 3つのProducerから並行してメッセージを送信し、
 * Consumer Groupによる負荷分散を確認する
 */
@RestController
@RequestMapping("/api/multi-demo")
public class MultiProducerConsumerDemoController {
    
    private static final Logger logger = LoggerFactory.getLogger(MultiProducerConsumerDemoController.class);
    
    private final MessageService messageService;
    private final MessageRepository messageRepository;
    private final Executor executor = Executors.newFixedThreadPool(10);
    
    public MultiProducerConsumerDemoController(
            MessageService messageService,
            MessageRepository messageRepository) {
        this.messageService = messageService;
        this.messageRepository = messageRepository;
    }
    
    /**
     * 3つのProducerから並行でメッセージを送信するデモ
     * GET /api/multi-demo/send-batch?count=10
     */
    @PostMapping("/send-batch")
    public ResponseEntity<BatchSendResponse> sendBatchMessages(
            @RequestParam(defaultValue = "9") int count) {
        
        logger.info("🚀 Starting batch message sending with {} messages from 3 producers", count);
        
        long startTime = System.currentTimeMillis();
        
        // 3つのProducerから並行してメッセージ送信
        List<CompletableFuture<Void>> futures = List.of(
            sendMessagesFromProducer("Producer-A", count / 3, MessageType.ORDER),
            sendMessagesFromProducer("Producer-B", count / 3, MessageType.NOTIFICATION),
            sendMessagesFromProducer("Producer-C", count / 3, MessageType.EVENT)
        );
        
        // 残りのメッセージを最初のProducerから送信
        int remaining = count % 3;
        if (remaining > 0) {
            futures.add(sendMessagesFromProducer("Producer-A", remaining, MessageType.ORDER));
        }
        
        // すべての送信完了を待機
        CompletableFuture.allOf(futures.toArray(new CompletableFuture[0]))
                .whenComplete((result, ex) -> {
                    long duration = System.currentTimeMillis() - startTime;
                    if (ex == null) {
                        logger.info("✅ All {} messages sent successfully in {}ms", count, duration);
                    } else {
                        logger.error("❌ Failed to send some messages", ex);
                    }
                });
        
        return ResponseEntity.ok(new BatchSendResponse(count, "Messages sent successfully"));
    }
    
    /**
     * 指定されたProducerから非同期でメッセージを送信
     */
    private CompletableFuture<Void> sendMessagesFromProducer(
            String producerName, 
            int messageCount, 
            MessageType messageType) {
        
        return CompletableFuture.runAsync(() -> {
            logger.info("📤 {} starting to send {} messages of type {}", 
                    producerName, messageCount, messageType);
            
            IntStream.range(0, messageCount)
                    .forEach(i -> {
                        try {
                            String messageId = UUID.randomUUID().toString();
                            String content = String.format("[%s] Message #%d - %s message from %s at %s", 
                                    messageType, i + 1, messageType.name().toLowerCase(), 
                                    producerName, LocalDateTime.now());
                            
                            Message message = new Message(
                                    messageId,
                                    content,
                                    producerName,
                                    LocalDateTime.now(),
                                    messageType
                            );
                            
                            messageService.sendMessage(message);
                            
                            // 送信間隔を少し空ける（負荷分散を観察しやすくするため）
                            Thread.sleep(100);
                            
                        } catch (Exception e) {
                            logger.error("❌ {} failed to send message #{}", producerName, i + 1, e);
                        }
                    });
            
            logger.info("✅ {} completed sending {} messages", producerName, messageCount);
        }, executor);
    }
    
    /**
     * Consumer Group内の各Consumerの処理状況を確認
     * GET /api/multi-demo/consumer-status
     */
    @GetMapping("/consumer-status")
    public ResponseEntity<ConsumerStatusResponse> getConsumerStatus() {
        
        // Redisから処理済みメッセージを取得
        List<Message> allMessages = messageRepository.findAll();
        
        // Producerごとの送信統計
        long producerACount = allMessages.stream()
                .filter(m -> "Producer-A".equals(m.getSender()))
                .count();
        long producerBCount = allMessages.stream()
                .filter(m -> "Producer-B".equals(m.getSender()))
                .count();
        long producerCCount = allMessages.stream()
                .filter(m -> "Producer-C".equals(m.getSender()))
                .count();
        
        // MessageTypeごとの統計
        long orderCount = allMessages.stream()
                .filter(m -> MessageType.ORDER.equals(m.getType()))
                .count();
        long notificationCount = allMessages.stream()
                .filter(m -> MessageType.NOTIFICATION.equals(m.getType()))
                .count();
        long eventCount = allMessages.stream()
                .filter(m -> MessageType.EVENT.equals(m.getType()))
                .count();
        
        ConsumerStatusResponse response = new ConsumerStatusResponse(
                allMessages.size(),
                producerACount,
                producerBCount,
                producerCCount,
                orderCount,
                notificationCount,
                eventCount,
                System.currentTimeMillis()
        );
        
        return ResponseEntity.ok(response);
    }
    
    /**
     * Consumer Group処理テスト用のストレステスト
     * POST /api/multi-demo/stress-test?duration=30&ratePerSecond=10
     */
    @PostMapping("/stress-test")
    public ResponseEntity<StressTestResponse> startStressTest(
            @RequestParam(defaultValue = "30") int durationSeconds,
            @RequestParam(defaultValue = "10") int ratePerSecond) {
        
        logger.info("🔥 Starting stress test: {}s duration, {} messages/sec", durationSeconds, ratePerSecond);
        
        CompletableFuture.runAsync(() -> {
            long endTime = System.currentTimeMillis() + (durationSeconds * 1000L);
            int messageCounter = 0;
            
            while (System.currentTimeMillis() < endTime) {
                try {
                    // 3つのProducerからローテーションで送信
                    String[] producers = {"Producer-A", "Producer-B", "Producer-C"};
                    MessageType[] types = {MessageType.ORDER, MessageType.NOTIFICATION, MessageType.EVENT};
                    
                    for (int i = 0; i < ratePerSecond && System.currentTimeMillis() < endTime; i++) {
                        String producer = producers[messageCounter % 3];
                        MessageType type = types[messageCounter % 3];
                        
                        String messageId = UUID.randomUUID().toString();
                        String content = String.format("[STRESS] Message #%d from %s", messageCounter + 1, producer);
                        
                        Message message = new Message(
                                messageId,
                                content,
                                producer,
                                LocalDateTime.now(),
                                type
                        );
                        
                        messageService.sendMessage(message);
                        messageCounter++;
                    }
                    
                    Thread.sleep(1000); // 1秒間隔
                    
                } catch (Exception e) {
                    logger.error("❌ Error during stress test", e);
                }
            }
            
            logger.info("✅ Stress test completed. Sent {} messages", messageCounter);
        }, executor);
        
        return ResponseEntity.ok(new StressTestResponse(
                durationSeconds, ratePerSecond, "Stress test started"));
    }
    
    // Response DTOs
    public static class BatchSendResponse {
        private final int messageCount;
        private final String status;
        
        public BatchSendResponse(int messageCount, String status) {
            this.messageCount = messageCount;
            this.status = status;
        }
        
        public int getMessageCount() { return messageCount; }
        public String getStatus() { return status; }
    }
    
    public static class ConsumerStatusResponse {
        private final long totalProcessedMessages;
        private final long producerAMessages;
        private final long producerBMessages;
        private final long producerCMessages;
        private final long orderMessages;
        private final long notificationMessages;
        private final long eventMessages;
        private final long timestamp;
        
        public ConsumerStatusResponse(long totalProcessedMessages, 
                                    long producerAMessages, long producerBMessages, long producerCMessages,
                                    long orderMessages, long notificationMessages, long eventMessages,
                                    long timestamp) {
            this.totalProcessedMessages = totalProcessedMessages;
            this.producerAMessages = producerAMessages;
            this.producerBMessages = producerBMessages;
            this.producerCMessages = producerCMessages;
            this.orderMessages = orderMessages;
            this.notificationMessages = notificationMessages;
            this.eventMessages = eventMessages;
            this.timestamp = timestamp;
        }
        
        public long getTotalProcessedMessages() { return totalProcessedMessages; }
        public long getProducerAMessages() { return producerAMessages; }
        public long getProducerBMessages() { return producerBMessages; }
        public long getProducerCMessages() { return producerCMessages; }
        public long getOrderMessages() { return orderMessages; }
        public long getNotificationMessages() { return notificationMessages; }
        public long getEventMessages() { return eventMessages; }
        public long getTimestamp() { return timestamp; }
    }
    
    public static class StressTestResponse {
        private final int durationSeconds;
        private final int ratePerSecond;
        private final String status;
        
        public StressTestResponse(int durationSeconds, int ratePerSecond, String status) {
            this.durationSeconds = durationSeconds;
            this.ratePerSecond = ratePerSecond;
            this.status = status;
        }
        
        public int getDurationSeconds() { return durationSeconds; }
        public int getRatePerSecond() { return ratePerSecond; }
        public String getStatus() { return status; }
    }
}
