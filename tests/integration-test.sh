#!/bin/bash

# Kafka Redis Playground Integration Test
# このスクリプトは、全APIエンドポイントをテストします

set -e  # エラー時に停止

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# CI環境ではカラー無効化
if [ "$CI" = "true" ] || [ ! -t 1 ]; then
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# 設定
BASE_URL="http://localhost:8888"
API_URL="${BASE_URL}/api/messages"
TEST_LOG="test-results.log"

# テスト結果カウンタ
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Docker Composeコマンドの検出
DOCKER_COMPOSE_CMD="docker-compose"
if command -v "docker" >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
elif ! command -v "docker-compose" >/dev/null 2>&1; then
    echo "Error: Neither 'docker compose' nor 'docker-compose' is available"
    exit 1
fi

# ログ関数
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message" | tee -a "$TEST_LOG"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message" | tee -a "$TEST_LOG"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message" | tee -a "$TEST_LOG"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message" | tee -a "$TEST_LOG"
            ;;
    esac
}

# テスト結果記録
record_test() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$result" = "PASS" ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log "SUCCESS" "✓ $test_name"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log "ERROR" "✗ $test_name - $details"
    fi
}

# HTTPレスポンステスト
test_http_request() {
    local description="$1"
    local method="$2"
    local url="$3"
    local data="$4"
    local expected_status="$5"
    local content_check="$6"
    
    log "INFO" "Testing: $description"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$url")
    elif [ "$method" = "POST" ]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$url")
    elif [ "$method" = "DELETE" ]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X DELETE "$url")
    fi
    
    http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    body=$(echo "$response" | sed -e 's/HTTPSTATUS:.*//')
    
    # ステータスコードチェック
    if [ "$http_code" = "$expected_status" ]; then
        # コンテンツチェック（指定されている場合）
        if [ -n "$content_check" ]; then
            if echo "$body" | grep -q "$content_check"; then
                record_test "$description" "PASS"
                echo "Response: $body" >> "$TEST_LOG"
                return 0
            else
                record_test "$description" "FAIL" "Content check failed: expected '$content_check'"
                echo "Response: $body" >> "$TEST_LOG"
                echo "Full response body for debugging: $body" >&2
                return 1
            fi
        else
            record_test "$description" "PASS"
            echo "Response: $body" >> "$TEST_LOG"
            return 0
        fi
    else
        record_test "$description" "FAIL" "Expected status $expected_status, got $http_code"
        echo "Response: $body" >> "$TEST_LOG"
        return 1
    fi
}

# 緊急メッセージテスト（柔軟なチェック）
test_urgent_messages_flexible() {
    local max_attempts=8
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log "INFO" "Testing urgent messages (attempt $attempt/$max_attempts)"
        
        local response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$API_URL/urgent")
        local http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
        local body=$(echo "$response" | sed -e 's/HTTPSTATUS:.*//')
        
        echo "Urgent messages response (attempt $attempt): $body" >> "$TEST_LOG"
        
        # ステータスコードが200で、何らかのERRORまたはWARNINGメッセージがあれば成功
        if [ "$http_code" = "200" ]; then
            # ERRORタイプまたはWARNINGタイプのメッセージをチェック
            if echo "$body" | grep -q '"type":"ERROR"' || echo "$body" | grep -q '"type":"WARNING"'; then
                record_test "Get urgent messages (flexible check)" "PASS"
                echo "Found urgent message: $body" >> "$TEST_LOG"
                return 0
            fi
            
            # 空の配列の場合は継続
            if echo "$body" | grep -q '\[\]'; then
                log "WARNING" "No urgent messages found yet, waiting... (attempt $attempt/$max_attempts)"
            else
                log "WARNING" "Urgent messages response doesn't contain ERROR/WARNING type, waiting... (attempt $attempt/$max_attempts)"
            fi
        else
            log "WARNING" "HTTP error $http_code, retrying... (attempt $attempt/$max_attempts)"
        fi
        
        # 最後の試行でない場合は待機
        if [ $attempt -lt $max_attempts ]; then
            sleep 5
        fi
        attempt=$((attempt + 1))
    done
    
    # 最終的に失敗
    record_test "Get urgent messages (flexible check)" "FAIL" "No urgent messages found after $max_attempts attempts"
    echo "Final response: $body" >> "$TEST_LOG"
    return 1
}

# 環境セットアップ
setup_environment() {
    log "INFO" "環境セットアップを開始します..."
    
    # 既存のコンテナを停止
    log "INFO" "既存のコンテナを停止中..."
    $DOCKER_COMPOSE_CMD down --remove-orphans 2>/dev/null || true
    
    # .envファイルをコピー（存在しない場合）
    if [ ! -f ".env" ]; then
        log "INFO" ".envファイルを作成中..."
        cp .env.template .env
    fi
    
    # コンテナを起動
    log "INFO" "Docker環境を起動中..."
    $DOCKER_COMPOSE_CMD --profile local-infra up --build -d
    
    # サービス起動待機
    log "INFO" "サービスの起動を待機中..."
    local max_attempts=60
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s "$BASE_URL/actuator/health" > /dev/null 2>&1; then
            log "SUCCESS" "サービスが起動しました"
            break
        fi
        
        attempt=$((attempt + 1))
        log "INFO" "起動待機中... ($attempt/$max_attempts)"
        sleep 5
    done
    
    if [ $attempt -eq $max_attempts ]; then
        log "ERROR" "サービスの起動がタイムアウトしました"
        return 1
    fi
    
    # Kafkaとの接続待機
    log "INFO" "Kafkaサービスの接続を待機中..."
    sleep 15  # CI環境では少し長めに待機
    
    return 0
}

# 環境クリーンアップ
cleanup_environment() {
    log "INFO" "環境をクリーンアップしています..."
    $DOCKER_COMPOSE_CMD down --remove-orphans
    log "SUCCESS" "クリーンアップ完了"
}

# メインテスト実行
run_tests() {
    log "INFO" "=== Kafka Redis Playground Integration Tests ==="
    
    # テストログをクリア
    > "$TEST_LOG"
    
    # 1. ヘルスチェック
    test_http_request "Health Check" "GET" "$BASE_URL/actuator/health" "" "200" "UP"
    
    # 2. 初期状態で全メッセージ取得（空のはず）
    test_http_request "Get all messages (初期状態)" "GET" "$API_URL" "" "200" "\[\]"
    
    # 3. WARNING メッセージ作成（緊急メッセージ用）
    local warning_data='{"content":"This is a warning message","sender":"test-user","type":"WARNING"}'
    test_http_request "Create WARNING message" "POST" "$API_URL" "$warning_data" "201" "This is a warning message"
    
    # 4. INFO メッセージ作成
    local message_data='{"content":"Hello Integration Test","sender":"test-user","type":"INFO"}'
    test_http_request "Create INFO message" "POST" "$API_URL" "$message_data" "201" "Hello Integration Test"
    
    # 5. ERROR メッセージ作成（緊急メッセージ）
    local error_data='{"content":"Critical error occurred","sender":"system","type":"ERROR"}'
    test_http_request "Create ERROR message" "POST" "$API_URL" "$error_data" "201" "Critical error occurred"
    
    # 6. SUCCESS メッセージ作成
    local success_data='{"content":"Operation completed","sender":"system","type":"SUCCESS"}'
    test_http_request "Create SUCCESS message" "POST" "$API_URL" "$success_data" "201" "Operation completed"
    
    # Kafka処理を待機（CI環境では長めに）
    if [ "$CI" = "true" ]; then
        log "INFO" "CI環境: Kafka メッセージ処理を待機中..."
        sleep 20
    else
        log "INFO" "Kafka メッセージ処理を待機中..."
        sleep 10
    fi
    
    # 7. 全メッセージ取得
    test_http_request "Get all messages" "GET" "$API_URL" "" "200" "Hello Integration Test"
    
    # 8. 送信者でフィルタリング
    test_http_request "Get messages by sender" "GET" "$API_URL/sender/test-user" "" "200" "test-user"
    
    # 9. 緊急メッセージ取得（ERROR/WARNING タイプ）- 柔軟なチェック
    test_urgent_messages_flexible
    
    # 10. 無効なメッセージタイプでテスト
    local invalid_data='{"content":"Invalid type test","sender":"test","type":"INVALID"}'
    test_http_request "Create message with invalid type" "POST" "$API_URL" "$invalid_data" "400"
    
    # 11. 空のコンテンツでテスト
    local empty_content='{"content":"","sender":"test","type":"INFO"}'
    test_http_request "Create message with empty content" "POST" "$API_URL" "$empty_content" "400"
    
    # 12. クリーンアップテスト
    test_http_request "Cleanup old messages" "DELETE" "$API_URL/cleanup?minutes=0" "" "200" "Deleted"
    
    # 13. クリーンアップ後の確認
    sleep 2
    test_http_request "Get all messages after cleanup" "GET" "$API_URL" "" "200"
}

# パフォーマンステスト
run_performance_test() {
    log "INFO" "=== Performance Test ==="
    
    local start_time=$(date +%s)
    
    # 複数メッセージを並行作成
    for i in {1..10}; do
        local data="{\"content\":\"Performance test message $i\",\"sender\":\"perf-test\",\"type\":\"INFO\"}"
        curl -s -X POST -H "Content-Type: application/json" -d "$data" "$API_URL" &
    done
    
    wait  # 全てのバックグラウンドプロセス完了を待機
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log "SUCCESS" "Performance test completed in $duration seconds"
    
    # 処理待機（CI環境では長めに）
    if [ "$CI" = "true" ]; then
        sleep 15
    else
        sleep 10
    fi
    
    # 結果確認
    test_http_request "Get performance test messages" "GET" "$API_URL/sender/perf-test" "" "200"
}

# 結果サマリー表示
show_summary() {
    log "INFO" "=== Test Summary ==="
    log "INFO" "Total Tests: $TOTAL_TESTS"
    log "SUCCESS" "Passed: $PASSED_TESTS"
    log "ERROR" "Failed: $FAILED_TESTS"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        log "SUCCESS" "🎉 All tests passed!"
        return 0
    else
        log "ERROR" "❌ Some tests failed. Check $TEST_LOG for details."
        return 1
    fi
}

# メイン実行
main() {
    log "INFO" "Kafka Redis Playground Integration Test を開始します"
    
    # CI環境では環境セットアップをスキップ
    if [ "$CI" != "true" ]; then
        # 環境セットアップ
        if ! setup_environment; then
            log "ERROR" "環境セットアップに失敗しました"
            exit 1
        fi
    fi
    
    # テスト実行
    run_tests
    
    # パフォーマンステスト
    run_performance_test
    
    # 結果表示
    local test_result=0
    if ! show_summary; then
        test_result=1
    fi
    
    # CI環境以外ではクリーンアップ確認
    if [ "$CI" != "true" ]; then
        read -p "環境をクリーンアップしますか？ (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cleanup_environment
        else
            log "INFO" "環境は起動したままです。手動でクリーンアップしてください: $DOCKER_COMPOSE_CMD down"
        fi
    fi
    
    exit $test_result
}

# スクリプト引数処理
case "${1:-}" in
    "setup")
        setup_environment
        ;;
    "test")
        run_tests
        show_summary
        ;;
    "cleanup")
        cleanup_environment
        ;;
    "performance")
        run_performance_test
        ;;
    *)
        main
        ;;
esac
