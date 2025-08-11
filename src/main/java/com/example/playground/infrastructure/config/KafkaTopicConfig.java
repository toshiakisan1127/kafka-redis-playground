package com.example.playground.infrastructure.config;

import org.apache.kafka.clients.admin.AdminClientConfig;
import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;
import org.springframework.kafka.core.KafkaAdmin;

import java.util.HashMap;
import java.util.Map;

/**
 * Kafkaトピック自動作成設定
 * アプリケーション起動時に必要なトピックを自動作成
 */
@Configuration
public class KafkaTopicConfig {
    
    @Value("${spring.kafka.bootstrap-servers:localhost:9092}")
    private String bootstrapServers;
    
    @Value("${app.kafka.topic.messages:messages}")
    private String messagesTopicName;
    
    /**
     * KafkaAdmin Bean
     * トピックの自動作成に必要
     */
    @Bean
    public KafkaAdmin kafkaAdmin() {
        Map<String, Object> configs = new HashMap<>();
        configs.put(AdminClientConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        return new KafkaAdmin(configs);
    }
    
    /**
     * メッセージトピックの定義
     * アプリケーション起動時に自動作成される
     */
    @Bean
    public NewTopic messagesTopic() {
        return TopicBuilder.name(messagesTopicName)
                .partitions(3)          // パーティション数
                .replicas(1)            // レプリカ数（単一ブローカー環境）
                .compact()              // ログ圧縮有効化
                .build();
    }
    
    /**
     * DLQ（Dead Letter Queue）トピック
     * エラーメッセージ用（将来的な拡張用）
     */
    @Bean
    public NewTopic deadLetterTopic() {
        return TopicBuilder.name(messagesTopicName + ".DLQ")
                .partitions(1)
                .replicas(1)
                .build();
    }
}
