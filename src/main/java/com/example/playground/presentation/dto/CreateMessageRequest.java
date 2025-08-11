package com.example.playground.presentation.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

/**
 * メッセージ作成リクエストDTO
 */
public class CreateMessageRequest {
    
    @NotBlank(message = "Content cannot be blank")
    private String content;
    
    @NotBlank(message = "Sender cannot be blank")
    private String sender;
    
    @NotBlank(message = "Type cannot be blank")
    @Pattern(regexp = "INFO|WARNING|ERROR|SUCCESS", 
             message = "Type must be one of: INFO, WARNING, ERROR, SUCCESS")
    private String type;
    
    // デフォルトコンストラクタ
    public CreateMessageRequest() {}
    
    public CreateMessageRequest(String content, String sender, String type) {
        this.content = content;
        this.sender = sender;
        this.type = type;
    }
    
    // Getters and Setters
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
    
    public String getType() {
        return type;
    }
    
    public void setType(String type) {
        this.type = type;
    }
}
