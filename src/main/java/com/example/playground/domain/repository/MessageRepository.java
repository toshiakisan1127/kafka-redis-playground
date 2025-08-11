package com.example.playground.domain.repository;

import com.example.playground.domain.model.Message;
import java.util.List;
import java.util.Optional;

/**
 * メッセージリポジトリのドメインインターフェース
 * オニオンアーキテクチャでは、ドメイン層がインフラ層に依存しないよう
 * ドメイン層でインターフェースを定義し、インフラ層で実装する
 */
public interface MessageRepository {
    
    /**
     * メッセージを保存する
     * @param message 保存するメッセージ
     * @return 保存されたメッセージ
     */
    Message save(Message message);
    
    /**
     * IDでメッセージを取得する
     * @param id メッセージID
     * @return メッセージ（存在しない場合はOptional.empty()）
     */
    Optional<Message> findById(String id);
    
    /**
     * 送信者でメッセージを取得する
     * @param sender 送信者
     * @return メッセージリスト
     */
    List<Message> findBySender(String sender);
    
    /**
     * 全てのメッセージを取得する
     * @return メッセージリスト
     */
    List<Message> findAll();
    
    /**
     * メッセージを削除する
     * @param id 削除するメッセージのID
     */
    void deleteById(String id);
    
    /**
     * 古いメッセージを削除する
     * @param minutes 何分前より古いメッセージを削除するか
     * @return 削除されたメッセージ数
     */
    int deleteOldMessages(int minutes);
}
