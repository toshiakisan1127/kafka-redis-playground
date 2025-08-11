#!/bin/bash

# CI/CD Integration Test Script
# CI/CD環境での統合テスト実行用スクリプト

set -e

# カラー定義（CI環境では無効化）
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# 設定
BASE_URL="http://localhost:8888"
API_URL="${BASE_URL}/api/messages"
TEST_LOG="ci-test-results.log"
MAX_WAIT_TIME=300  # 5分

# テスト結果カウンタ
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

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

# サービス起動待機
wait_for_services() {
    log "INFO" "Waiting for services to be ready..."
    
    local attempt=0
    local max_attempts=$((MAX_WAIT_TIME / 5))
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s "$BASE_URL/actuator/health" | grep -q "UP"; then
            log "SUCCESS" "Services are ready"
            return 0
        fi
        
        attempt=$((attempt + 1))
        log "INFO" "Waiting for services... ($attempt/$max_attempts)"
        sleep 5
    done
    
    log "ERROR" "Services failed to start within $MAX_WAIT_TIME seconds"
    return 1
}

# HTTPリクエストテスト
test_http_request() {
    local description="$1"
    local method="$2"
    local url="$3"
    local data="$4"
    local expected_status="$5"
    local content_check="$6"
    
    local response
    local http_code
    local body
    
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

# 緊急メッセージテスト（リトライ機能付き）
test_urgent_messages_with_retry() {
    local max_attempts=6
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log "INFO" "Testing urgent messages (attempt $attempt/$max_attempts)"
        
        local response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$API_URL/urgent")
        local http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
        local body=$(echo "$response" | sed -e 's/HTTPSTATUS:.*//')
        
        if [ "$http_code" = "200" ] && echo "$body" | grep -q "CI Error Test"; then
            record_test "Get urgent messages (with retry)" "PASS"
            echo "Response: $body" >> "$TEST_LOG"
            return 0
        fi
        
        log "WARNING" "Urgent message not found yet, waiting... (attempt $attempt/$max_attempts)"
        echo "Current response: $body" >> "$TEST_LOG"
        
        # Kafkaの処理を待機
        sleep 5
        attempt=$((attempt + 1))
    done
    
    # 最終的に失敗
    record_test "Get urgent messages (with retry)" "FAIL" "Urgent message not found after $max_attempts attempts"
    echo "Final response: $body" >> "$TEST_LOG"
    return 1
}

# コアテスト実行
run_core_tests() {
    log "INFO" "=== Core Integration Tests ==="
    
    # テストログをクリア
    > "$TEST_LOG"
    
    # 1. ヘルスチェック
    test_http_request "Health Check" "GET" "$BASE_URL/actuator/health" "" "200" "UP"
    
    # 2. 初期状態で全メッセージ取得（空のはず）
    test_http_request "Get all messages (initial state)" "GET" "$API_URL" "" "200" "\[\]"
    
    # 3. メッセージ作成テスト
    local message_data='{"content":"CI Test Message","sender":"ci-test","type":"INFO"}'
    test_http_request "Create INFO message" "POST" "$API_URL" "$message_data" "201" "CI Test Message"
    
    # 4. ERROR メッセージ作成（緊急メッセージ）
    local error_data='{"content":"CI Error Test","sender":"ci-test","type":"ERROR"}'
    test_http_request "Create ERROR message" "POST" "$API_URL" "$error_data" "201" "CI Error Test"
    
    # Kafka処理を待機（CI環境では長めに）
    log "INFO" "Waiting for Kafka processing..."
    sleep 15
    
    # 5. 全メッセージ取得
    test_http_request "Get all messages" "GET" "$API_URL" "" "200" "CI Test Message"
    
    # 6. 緊急メッセージ取得（ERROR タイプ）- リトライ機能付き
    test_urgent_messages_with_retry
    
    # 7. 送信者でフィルタリング
    test_http_request "Get messages by sender" "GET" "$API_URL/sender/ci-test" "" "200" "ci-test"
    
    # 8. バリデーションエラーテスト
    local invalid_data='{"content":"","sender":"test","type":"INFO"}'
    test_http_request "Create message with empty content" "POST" "$API_URL" "$invalid_data" "400"
    
    # 9. 無効なタイプでテスト
    local invalid_type='{"content":"Test","sender":"test","type":"INVALID"}'
    test_http_request "Create message with invalid type" "POST" "$API_URL" "$invalid_type" "400"
}

# パフォーマンステスト実行
run_performance_tests() {
    log "INFO" "=== Performance Tests ==="
    
    local start_time=$(date +%s)
    
    # 10件の並行リクエスト
    for i in {1..10}; do
        local data='{"content":"Perf test '${i}'","sender":"perf-test","type":"INFO"}'
        curl -s -X POST -H "Content-Type: application/json" -d "$data" "$API_URL" &
    done
    
    wait  # 全てのバックグラウンドプロセス完了を待機
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log "SUCCESS" "Performance test completed in $duration seconds"
    
    # 処理待機
    sleep 15
    
    # 結果確認
    test_http_request "Get performance test messages" "GET" "$API_URL/sender/perf-test" "" "200"
}

# 結果サマリー表示
show_summary() {
    log "INFO" "=== CI Test Summary ==="
    log "INFO" "Total Tests: $TOTAL_TESTS"
    log "SUCCESS" "Passed: $PASSED_TESTS"
    
    if [ $FAILED_TESTS -gt 0 ]; then
        log "ERROR" "Failed: $FAILED_TESTS"
        log "ERROR" "❌ Some tests failed. Check $TEST_LOG for details."
        return 1
    else
        log "SUCCESS" "🎉 All tests passed!"
        return 0
    fi
}

# メイン実行
main() {
    log "INFO" "Starting CI/CD Integration Tests"
    
    # サービス起動待機
    if ! wait_for_services; then
        log "ERROR" "Services are not ready"
        exit 1
    fi
    
    # コアテスト実行
    run_core_tests
    
    # パフォーマンステスト実行
    run_performance_tests
    
    # 結果表示
    if ! show_summary; then
        exit 1
    fi
    
    log "SUCCESS" "CI/CD Integration Tests completed successfully"
}

# スクリプト実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
