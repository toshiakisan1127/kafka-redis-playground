package com.example.playground.infrastructure.messaging;

import com.example.playground.domain.model.Message;
import com.example.playground.domain.model.MessageType;
import com.example.playground.domain.repository.MessageRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

/**
 * Consumer Group の Consumer-A
 * 同一Consumer Group内で負荷分散される3つのConsumerの1つ
 */
@Component
public class ConsumerA {
    
    private static final Logger logger = LoggerFactory.getLogger(ConsumerA.class);
    
    private final MessageRepository messageRepository;
    private final ObjectMapper objectMapper;
    
    @Value("${app.kafka.consumer.processing-delay:1000}")
    private int processingDelayMs;
    
    public ConsumerA(MessageRepository messageRepository, ObjectMapper objectMapper) {
        this.messageRepository = messageRepository;
        this.objectMapper = objectMapper;
    }
    
    @KafkaListener(
        topics = "${app.kafka.topic.messages:messages}",
        groupId = "${app.kafka.consumer.group-id:message-consumer-group}",
        containerFactory = "kafkaListenerContainerFactory",
        clientIdPrefix = "consumer-a"
    )
    public void handleMessage(
            @Payload String messageJson,
            @Header(KafkaHeaders.RECEIVED_KEY) String key,
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            @Header(KafkaHeaders.RECEIVED_PARTITION) int partition,
            @Header(KafkaHeaders.OFFSET) long offset) {
        
        try {
            logger.info("🟦 [Consumer-A] Received message: key={}, topic={}, partition={}, offset={}", 
                    key, topic, partition, offset);
            
            // 処理遅延（負荷分散の観察のため）
            if (processingDelayMs > 0) {
                logger.info("⏳ [Consumer-A] Processing delay: {}ms", processingDelayMs);
                Thread.sleep(processingDelayMs);
            }
            
            // JSONからメッセージイベントに変換
            MessageEvent event = objectMapper.readValue(messageJson, MessageEvent.class);
            
            // ドメインモデルに変換
            Message message = convertToMessage(event);
            
            logger.info("💾 [Consumer-A] Saving message: id={}, content='{}', sender={}", 
                    message.getId(), message.getContent(), message.getSender());
            
            // Redis に保存
            messageRepository.save(message);
            
            logger.info("✅ [Consumer-A] Message processed successfully: id={}, type={}", 
                    message.getId(), message.getType());
                    
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            logger.warn("⚠️ [Consumer-A] Processing interrupted: key={}", key);
        } catch (JsonProcessingException e) {
            logger.error("❌ [Consumer-A] Failed to deserialize message: key={}, payload={}", key, messageJson, e);
        } catch (Exception e) {
            logger.error("💥 [Consumer-A] Failed to process message: key={}", key, e);
        }
    }
    
    private Message convertToMessage(MessageEvent event) {
        return new Message(
                event.getId(),
                event.getContent(),
                event.getSender(),
                LocalDateTime.parse(event.getTimestamp()),
                MessageType.valueOf(event.getType())
        );
    }
    
    public static class MessageEvent {
        private String id;
        private String content;
        private String sender;
        private String timestamp;
        private String type;
        
        public MessageEvent() {}
        
        // Getters and Setters
        public String getId() { return id; }
        public void setId(String id) { this.id = id; }
        
        public String getContent() { return content; }
        public void setContent(String content) { this.content = content; }
        
        public String getSender() { return sender; }
        public void setSender(String sender) { this.sender = sender; }
        
        public String getTimestamp() { return timestamp; }
        public void setTimestamp(String timestamp) { this.timestamp = timestamp; }
        
        public String getType() { return type; }
        public void setType(String type) { this.type = type; }
    }
}
