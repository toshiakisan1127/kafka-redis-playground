package com.example.playground.domain.model;

import java.time.LocalDateTime;
import java.util.Objects;

/**
 * ドメインモデル: メッセージ
 * Kafkaで送受信し、Redisにキャッシュするメッセージを表現
 */
public class Message {
    private final String id;
    private final String content;
    private final String sender;
    private final LocalDateTime timestamp;
    private final MessageType type;

    public Message(String id, String content, String sender, LocalDateTime timestamp, MessageType type) {
        this.id = Objects.requireNonNull(id, "Message ID cannot be null");
        this.content = Objects.requireNonNull(content, "Message content cannot be null");
        this.sender = Objects.requireNonNull(sender, "Message sender cannot be null");
        this.timestamp = Objects.requireNonNull(timestamp, "Message timestamp cannot be null");
        this.type = Objects.requireNonNull(type, "Message type cannot be null");
    }

    // ファクトリーメソッド
    public static Message create(String content, String sender, MessageType type) {
        return new Message(
            java.util.UUID.randomUUID().toString(),
            content,
            sender,
            LocalDateTime.now(),
            type
        );
    }

    // Getters
    public String getId() {
        return id;
    }

    public String getContent() {
        return content;
    }

    public String getSender() {
        return sender;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public MessageType getType() {
        return type;
    }

    // ドメインロジック: メッセージが古いかどうかを判定
    public boolean isOlderThan(int minutes) {
        return timestamp.isBefore(LocalDateTime.now().minusMinutes(minutes));
    }

    // ドメインロジック: メッセージが緊急かどうかを判定
    public boolean isUrgent() {
        return type == MessageType.ERROR || type == MessageType.WARNING;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (obj == null || getClass() != obj.getClass()) return false;
        Message message = (Message) obj;
        return Objects.equals(id, message.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }

    @Override
    public String toString() {
        return "Message{" +
                "id='" + id + '\'' +
                ", content='" + content + '\'' +
                ", sender='" + sender + '\'' +
                ", timestamp=" + timestamp +
                ", type=" + type +
                '}';
    }
}
