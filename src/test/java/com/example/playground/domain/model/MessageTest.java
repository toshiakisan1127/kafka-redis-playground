package com.example.playground.domain.model;

import org.junit.jupiter.api.Test;
import java.time.LocalDateTime;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Messageドメインモデルのテスト
 */
class MessageTest {
    
    @Test
    void testCreateMessage() {
        // Given
        String content = "Test message";
        String sender = "test-user";
        MessageType type = MessageType.INFO;
        
        // When
        Message message = Message.create(content, sender, type);
        
        // Then
        assertNotNull(message.getId());
        assertEquals(content, message.getContent());
        assertEquals(sender, message.getSender());
        assertEquals(type, message.getType());
        assertNotNull(message.getTimestamp());
        assertTrue(message.getTimestamp().isBefore(LocalDateTime.now().plusSeconds(1)));
        assertTrue(message.getTimestamp().isAfter(LocalDateTime.now().minusSeconds(1)));
    }
    
    @Test
    void testIsOlderThan() {
        // Given
        LocalDateTime pastTime = LocalDateTime.now().minusMinutes(10);
        Message message = new Message("test-id", "content", "sender", pastTime, MessageType.INFO);
        
        // When & Then
        assertTrue(message.isOlderThan(5));
        assertFalse(message.isOlderThan(15));
    }
    
    @Test
    void testIsUrgent() {
        // Given & When & Then
        Message errorMessage = Message.create("Error", "user", MessageType.ERROR);
        Message warningMessage = Message.create("Warning", "user", MessageType.WARNING);
        Message infoMessage = Message.create("Info", "user", MessageType.INFO);
        Message successMessage = Message.create("Success", "user", MessageType.SUCCESS);
        
        assertTrue(errorMessage.isUrgent());
        assertTrue(warningMessage.isUrgent());
        assertFalse(infoMessage.isUrgent());
        assertFalse(successMessage.isUrgent());
    }
    
    @Test
    void testEqualsAndHashCode() {
        // Given
        String id = "test-id";
        Message message1 = new Message(id, "content1", "sender1", LocalDateTime.now(), MessageType.INFO);
        Message message2 = new Message(id, "content2", "sender2", LocalDateTime.now(), MessageType.ERROR);
        Message message3 = new Message("different-id", "content1", "sender1", LocalDateTime.now(), MessageType.INFO);
        
        // When & Then
        assertEquals(message1, message2); // 同じIDなので等しい
        assertNotEquals(message1, message3); // 異なるIDなので等しくない
        assertEquals(message1.hashCode(), message2.hashCode());
    }
    
    @Test
    void testNullValidation() {
        // Given & When & Then
        assertThrows(NullPointerException.class, () -> 
            new Message(null, "content", "sender", LocalDateTime.now(), MessageType.INFO));
        assertThrows(NullPointerException.class, () -> 
            new Message("id", null, "sender", LocalDateTime.now(), MessageType.INFO));
        assertThrows(NullPointerException.class, () -> 
            new Message("id", "content", null, LocalDateTime.now(), MessageType.INFO));
        assertThrows(NullPointerException.class, () -> 
            new Message("id", "content", "sender", null, MessageType.INFO));
        assertThrows(NullPointerException.class, () -> 
            new Message("id", "content", "sender", LocalDateTime.now(), null));
    }
}
