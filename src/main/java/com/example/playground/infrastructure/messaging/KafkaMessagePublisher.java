package com.example.playground.infrastructure.messaging;

import com.example.playground.application.service.MessagePublisher;
import com.example.playground.domain.model.Message;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

/**
 * Kafkaを使用したMessagePublisherの実装
 * アプリケーション層のMessagePublisherインターフェースを実装し、
 * Kafkaへのメッセージ送信を担当
 */
@Component
public class KafkaMessagePublisher implements MessagePublisher {
    
    private static final Logger logger = LoggerFactory.getLogger(KafkaMessagePublisher.class);
    
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;
    private final String topicName;
    
    public KafkaMessagePublisher(
            KafkaTemplate<String, String> kafkaTemplate,
            ObjectMapper objectMapper,
            @Value("${app.kafka.topic.messages:messages}") String topicName) {
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
        this.topicName = topicName;
    }
    
    @Override
    public void publish(Message message) {
        try {
            // メッセージをJSONに変換
            String messageJson = objectMapper.writeValueAsString(new MessageEvent(message));
            
            // Kafkaに送信（メッセージIDをキーとして使用）
            kafkaTemplate.send(topicName, message.getId(), messageJson)
                    .whenComplete((result, ex) -> {
                        if (ex == null) {
                            logger.info("Message sent successfully: id={}, topic={}, partition={}, offset={}",
                                    message.getId(), topicName, 
                                    result.getRecordMetadata().partition(),
                                    result.getRecordMetadata().offset());
                        } else {
                            logger.error("Failed to send message: id={}, topic={}", 
                                    message.getId(), topicName, ex);
                        }
                    });
                    
        } catch (JsonProcessingException e) {
            logger.error("Failed to serialize message: id={}", message.getId(), e);
            throw new RuntimeException("Failed to serialize message", e);
        }
    }
    
    /**
     * Kafka送信用のイベントDTO
     */
    public static class MessageEvent {
        private String id;
        private String content;
        private String sender;
        private String timestamp;
        private String type;
        
        public MessageEvent() {}
        
        public MessageEvent(Message message) {
            this.id = message.getId();
            this.content = message.getContent();
            this.sender = message.getSender();
            this.timestamp = message.getTimestamp().toString();
            this.type = message.getType().name();
        }
        
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
