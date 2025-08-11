package com.example.playground.application.service;

import com.example.playground.domain.model.Message;
import com.example.playground.domain.model.MessageType;
import com.example.playground.domain.repository.MessageRepository;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;

/**
 * メッセージ関連のアプリケーションサービス
 * ビジネスロジックを実装し、ドメインモデルとリポジトリを組み合わせて機能を提供
 */
@Service
public class MessageService {
    
    private final MessageRepository messageRepository;
    private final MessagePublisher messagePublisher;
    
    public MessageService(MessageRepository messageRepository, MessagePublisher messagePublisher) {
        this.messageRepository = messageRepository;
        this.messagePublisher = messagePublisher;
    }
    
    /**
     * メッセージを作成し、Kafkaに送信してリポジトリに保存する
     * @param content メッセージ内容
     * @param sender 送信者
     * @param type メッセージタイプ
     * @return 作成されたメッセージ
     */
    public Message createAndSendMessage(String content, String sender, MessageType type) {
        Message message = Message.create(content, sender, type);
        
        // Kafkaに送信
        messagePublisher.publish(message);
        
        // リポジトリに保存
        return messageRepository.save(message);
    }
    
    /**
     * IDでメッセージを取得する
     * @param id メッセージID
     * @return メッセージ（存在しない場合はOptional.empty()）
     */
    public Optional<Message> getMessageById(String id) {
        return messageRepository.findById(id);
    }
    
    /**
     * 送信者でメッセージを取得する
     * @param sender 送信者
     * @return メッセージリスト
     */
    public List<Message> getMessagesBySender(String sender) {
        return messageRepository.findBySender(sender);
    }
    
    /**
     * 全てのメッセージを取得する
     * @return メッセージリスト
     */
    public List<Message> getAllMessages() {
        return messageRepository.findAll();
    }
    
    /**
     * 緊急メッセージのみを取得する
     * @return 緊急メッセージリスト
     */
    public List<Message> getUrgentMessages() {
        return messageRepository.findAll()
                .stream()
                .filter(Message::isUrgent)
                .toList();
    }
    
    /**
     * 古いメッセージを削除する
     * @param minutes 何分前より古いメッセージを削除するか
     * @return 削除されたメッセージ数
     */
    public int cleanupOldMessages(int minutes) {
        return messageRepository.deleteOldMessages(minutes);
    }
    
    /**
     * メッセージを削除する
     * @param id 削除するメッセージのID
     */
    public void deleteMessage(String id) {
        messageRepository.deleteById(id);
    }
}
