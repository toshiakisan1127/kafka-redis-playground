package com.example.playground.presentation.dto;

import com.example.playground.domain.model.Message;
import com.fasterxml.jackson.annotation.JsonFormat;

import java.time.LocalDateTime;

/**
 * メッセージレスポンスDTO
 */
public class MessageResponse {
    
    private String id;
    private String content;
    private String sender;
    
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime timestamp;
    
    private String type;
    private boolean urgent;
    
    // デフォルトコンストラクタ
    public MessageResponse() {}
    
    public MessageResponse(String id, String content, String sender, 
                          LocalDateTime timestamp, String type, boolean urgent) {
        this.id = id;
        this.content = content;
        this.sender = sender;
        this.timestamp = timestamp;
        this.type = type;
        this.urgent = urgent;
    }
    
    /**
     * ドメインモデルからDTOを生成するファクトリーメソッド
     */
    public static MessageResponse from(Message message) {
        return new MessageResponse(
                message.getId(),
                message.getContent(),
                message.getSender(),
                message.getTimestamp(),
                message.getType().name(),
                message.isUrgent()
        );
    }
    
    // Getters and Setters
    public String getId() {
        return id;
    }
    
    public void setId(String id) {
        this.id = id;
    }
    
    public String getContent() {
        return content;
    }
    
    public void setContent(String content) {
        this.content = content;
    }
    
    public String getSender() {
        return sender;
    }
    
    public void setSender(String sender) {
        this.sender = sender;
    }
    
    public LocalDateTime getTimestamp() {
        return timestamp;
    }
    
    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }
    
    public String getType() {
        return type;
    }
    
    public void setType(String type) {
        this.type = type;
    }
    
    public boolean isUrgent() {
        return urgent;
    }
    
    public void setUrgent(boolean urgent) {
        this.urgent = urgent;
    }
}
