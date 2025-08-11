package com.example.playground.presentation.controller;

import com.example.playground.application.service.MessageService;
import com.example.playground.domain.model.Message;
import com.example.playground.domain.model.MessageType;
import com.example.playground.presentation.dto.CreateMessageRequest;
import com.example.playground.presentation.dto.MessageResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

/**
 * メッセージ関連のREST APIコントローラー
 * プレゼンテーション層として、HTTPリクエストを受け取り、
 * アプリケーション層のサービスを呼び出してレスポンスを返す
 */
@RestController
@RequestMapping("/api/messages")
@CrossOrigin(origins = "*") // 開発用、本番では適切に設定
public class MessageController {
    
    private final MessageService messageService;
    
    public MessageController(MessageService messageService) {
        this.messageService = messageService;
    }
    
    /**
     * メッセージを作成してKafkaに送信
     */
    @PostMapping
    public ResponseEntity<MessageResponse> createMessage(@Valid @RequestBody CreateMessageRequest request) {
        Message message = messageService.createAndSendMessage(
                request.getContent(),
                request.getSender(),
                MessageType.valueOf(request.getType().toUpperCase())
        );
        
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(MessageResponse.from(message));
    }
    
    /**
     * 全てのメッセージを取得
     */
    @GetMapping
    public ResponseEntity<List<MessageResponse>> getAllMessages() {
        List<Message> messages = messageService.getAllMessages();
        List<MessageResponse> responses = messages.stream()
                .map(MessageResponse::from)
                .toList();
        
        return ResponseEntity.ok(responses);
    }
    
    /**
     * IDでメッセージを取得
     */
    @GetMapping("/{id}")
    public ResponseEntity<MessageResponse> getMessageById(@PathVariable String id) {
        Optional<Message> message = messageService.getMessageById(id);
        
        return message.map(m -> ResponseEntity.ok(MessageResponse.from(m)))
                .orElse(ResponseEntity.notFound().build());
    }
    
    /**
     * 送信者でメッセージを取得
     */
    @GetMapping("/sender/{sender}")
    public ResponseEntity<List<MessageResponse>> getMessagesBySender(@PathVariable String sender) {
        List<Message> messages = messageService.getMessagesBySender(sender);
        List<MessageResponse> responses = messages.stream()
                .map(MessageResponse::from)
                .toList();
        
        return ResponseEntity.ok(responses);
    }
    
    /**
     * 緊急メッセージのみを取得
     */
    @GetMapping("/urgent")
    public ResponseEntity<List<MessageResponse>> getUrgentMessages() {
        List<Message> messages = messageService.getUrgentMessages();
        List<MessageResponse> responses = messages.stream()
                .map(MessageResponse::from)
                .toList();
        
        return ResponseEntity.ok(responses);
    }
    
    /**
     * メッセージを削除
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteMessage(@PathVariable String id) {
        messageService.deleteMessage(id);
        return ResponseEntity.noContent().build();
    }
    
    /**
     * 古いメッセージを削除
     */
    @DeleteMapping("/cleanup")
    public ResponseEntity<CleanupResponse> cleanupOldMessages(
            @RequestParam(defaultValue = "60") int minutes) {
        int deletedCount = messageService.cleanupOldMessages(minutes);
        return ResponseEntity.ok(new CleanupResponse(deletedCount, minutes));
    }
    
    /**
     * クリーンアップ結果のレスポンス
     */
    public static class CleanupResponse {
        private final int deletedCount;
        private final int minutes;
        
        public CleanupResponse(int deletedCount, int minutes) {
            this.deletedCount = deletedCount;
            this.minutes = minutes;
        }
        
        public int getDeletedCount() { return deletedCount; }
        public int getMinutes() { return minutes; }
        public String getMessage() { 
            return String.format("Deleted %d messages older than %d minutes", deletedCount, minutes);
        }
    }
}
