package com.example.playground.application.service;

import com.example.playground.domain.model.Message;

/**
 * メッセージ送信インターフェース
 * アプリケーション層でKafkaへのメッセージ送信を抽象化
 */
public interface MessagePublisher {
    
    /**
     * メッセージをKafkaに送信する
     * @param message 送信するメッセージ
     */
    void publish(Message message);
}
