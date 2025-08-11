package com.example.playground.infrastructure.repository;

import com.example.playground.domain.model.Message;
import com.example.playground.domain.model.MessageType;
import com.example.playground.domain.repository.MessageRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;

/**
 * Redisを使用したMessageRepositoryの実装
 * ドメイン層のRepositoryインターフェースを実装し、
 * Redisへのデータ永続化を担当
 */
@Repository
public class RedisMessageRepository implements MessageRepository {
    
    private static final String MESSAGE_KEY_PREFIX = "message:";
    private static final String MESSAGE_SET_KEY = "messages"; // ListからSetに変更
    private static final String SENDER_INDEX_PREFIX = "sender:";
    
    private final RedisTemplate<String, String> redisTemplate;
    private final ObjectMapper objectMapper;
    
    public RedisMessageRepository(RedisTemplate<String, String> redisTemplate, ObjectMapper objectMapper) {
        this.redisTemplate = redisTemplate;
        this.objectMapper = objectMapper;
    }
    
    @Override
    public Message save(Message message) {
        try {
            String messageKey = MESSAGE_KEY_PREFIX + message.getId();
            String senderIndexKey = SENDER_INDEX_PREFIX + message.getSender();
            
            // メッセージをJSONとして保存
            String messageJson = objectMapper.writeValueAsString(new MessageDto(message));
            redisTemplate.opsForValue().set(messageKey, messageJson);
            
            // 全メッセージのSetに追加（重複は自動で排除される）
            redisTemplate.opsForSet().add(MESSAGE_SET_KEY, message.getId());
            
            // 送信者インデックスにも追加（こちらもSetに変更）
            redisTemplate.opsForSet().add(senderIndexKey, message.getId());
            
            return message;
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Failed to serialize message", e);
        }
    }
    
    @Override
    public Optional<Message> findById(String id) {
        String messageKey = MESSAGE_KEY_PREFIX + id;
        String messageJson = redisTemplate.opsForValue().get(messageKey);
        
        if (messageJson == null) {
            return Optional.empty();
        }
        
        try {
            MessageDto dto = objectMapper.readValue(messageJson, MessageDto.class);
            return Optional.of(dto.toMessage());
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Failed to deserialize message", e);
        }
    }
    
    @Override
    public List<Message> findBySender(String sender) {
        String senderIndexKey = SENDER_INDEX_PREFIX + sender;
        Set<String> messageIds = redisTemplate.opsForSet().members(senderIndexKey);
        
        if (messageIds == null || messageIds.isEmpty()) {
            return new ArrayList<>();
        }
        
        // N+1問題を解決：一括取得を使用
        return getMessagesByIds(messageIds);
    }
    
    @Override
    public List<Message> findAll() {
        Set<String> messageIds = redisTemplate.opsForSet().members(MESSAGE_SET_KEY);
        
        if (messageIds == null || messageIds.isEmpty()) {
            return new ArrayList<>();
        }
        
        // N+1問題を解決：一括取得を使用
        return getMessagesByIds(messageIds);
    }
    
    /**
     * 複数のメッセージIDから一括でメッセージを取得する
     * N+1問題を解決するためのヘルパーメソッド
     * 
     * @param messageIds 取得するメッセージIDのセット
     * @return メッセージのリスト
     */
    private List<Message> getMessagesByIds(Set<String> messageIds) {
        if (messageIds == null || messageIds.isEmpty()) {
            return new ArrayList<>();
        }
        
        // メッセージキーのリストを作成
        List<String> keys = messageIds.stream()
                .map(id -> MESSAGE_KEY_PREFIX + id)
                .toList();
        
        // 一括取得でN+1問題を解決
        List<String> messageJsons = redisTemplate.opsForValue().multiGet(keys);
        
        if (messageJsons == null) {
            return new ArrayList<>();
        }
        
        return messageJsons.stream()
                .filter(Objects::nonNull)
                .map(this::deserializeMessage)
                .filter(Objects::nonNull)
                .toList();
    }
    
    /**
     * JSON文字列からMessageオブジェクトをデシリアライズする
     * エラーハンドリングを含む
     * 
     * @param messageJson JSONstring
     * @return Messageオブジェクト、デシリアライズに失敗した場合はnull
     */
    private Message deserializeMessage(String messageJson) {
        try {
            MessageDto dto = objectMapper.readValue(messageJson, MessageDto.class);
            return dto.toMessage();
        } catch (JsonProcessingException e) {
            // ログを出力して該当メッセージをスキップ
            // 本来はloggerを使用することを推奨
            System.err.println("Failed to deserialize message: " + e.getMessage());
            return null;
        }
    }
    
    @Override
    public void deleteById(String id) {
        String messageKey = MESSAGE_KEY_PREFIX + id;
        
        // メッセージを取得して送信者情報を得る
        Optional<Message> message = findById(id);
        
        // メッセージを削除
        redisTemplate.delete(messageKey);
        
        // SetからIDを削除
        redisTemplate.opsForSet().remove(MESSAGE_SET_KEY, id);
        
        // 送信者インデックスからも削除
        if (message.isPresent()) {
            String senderIndexKey = SENDER_INDEX_PREFIX + message.get().getSender();
            redisTemplate.opsForSet().remove(senderIndexKey, id);
        }
    }
    
    @Override
    public int deleteOldMessages(int minutes) {
        List<Message> allMessages = findAll();
        LocalDateTime cutoffTime = LocalDateTime.now().minusMinutes(minutes);
        
        int deletedCount = 0;
        for (Message message : allMessages) {
            if (message.getTimestamp().isBefore(cutoffTime)) {
                deleteById(message.getId());
                deletedCount++;
            }
        }
        
        return deletedCount;
    }
    
    /**
     * Redis保存用のDTO
     * Jackson用のデフォルトコンストラクタとsetterを持つ
     */
    public static class MessageDto {
        private String id;
        private String content;
        private String sender;
        private LocalDateTime timestamp;
        private MessageType type;
        
        // デフォルトコンストラクタ（Jackson用）
        public MessageDto() {}
        
        // Messageからの変換コンストラクタ
        public MessageDto(Message message) {
            this.id = message.getId();
            this.content = message.getContent();
            this.sender = message.getSender();
            this.timestamp = message.getTimestamp();
            this.type = message.getType();
        }
        
        // DTOからMessageへの変換
        public Message toMessage() {
            return new Message(id, content, sender, timestamp, type);
        }
        
        // Getters and Setters
        public String getId() { return id; }
        public void setId(String id) { this.id = id; }
        
        public String getContent() { return content; }
        public void setContent(String content) { this.content = content; }
        
        public String getSender() { return sender; }
        public void setSender(String sender) { this.sender = sender; }
        
        public LocalDateTime getTimestamp() { return timestamp; }
        public void setTimestamp(LocalDateTime timestamp) { this.timestamp = timestamp; }
        
        public MessageType getType() { return type; }
        public void setType(MessageType type) { this.type = type; }
    }
}
