#!/bin/bash

# Manual Test Script for Kafka Redis Playground
# 手動テスト用のインタラクティブスクリプト

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# CI環境ではカラー無効化
if [ "$CI" = "true" ] || [ ! -t 1 ]; then
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    MAGENTA=''
    CYAN=''
    NC=''
fi

# 設定
BASE_URL="http://localhost:8888"
API_URL="${BASE_URL}/api/messages"

# ユーティリティ関数
print_header() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}\n"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# HTTPリクエスト実行
execute_request() {
    local description="$1"
    local method="$2"
    local url="$3"
    local data="$4"
    
    print_info "Executing: $description"
    print_info "Method: $method"
    print_info "URL: $url"
    
    if [ -n "$data" ]; then
        print_info "Data: $data"
    fi
    
    echo -e "\n${MAGENTA}Response:${NC}"
    
    local response
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n\nHTTP Status: %{http_code}\nTime: %{time_total}s" "$url")
    elif [ "$method" = "POST" ]; then
        response=$(curl -s -w "\n\nHTTP Status: %{http_code}\nTime: %{time_total}s" \
            -X POST -H "Content-Type: application/json" -d "$data" "$url")
    elif [ "$method" = "DELETE" ]; then
        response=$(curl -s -w "\n\nHTTP Status: %{http_code}\nTime: %{time_total}s" \
            -X DELETE "$url")
    fi
    
    # jqが利用可能ならJSONをフォーマット、そうでなければそのまま表示
    if command -v jq >/dev/null 2>&1; then
        echo "$response" | head -n -2 | jq . 2>/dev/null || echo "$response"
    else
        echo "$response"
    fi
    echo
}

# メニュー表示
show_menu() {
    print_header "Kafka Redis Playground Manual Test"
    echo -e "${YELLOW}Select an option:${NC}"
    echo "1. Health Check"
    echo "2. Create Message"
    echo "3. Get All Messages"
    echo "4. Get Messages by Sender"
    echo "5. Get Urgent Messages"
    echo "6. Get Message by ID"
    echo "7. Delete Message by ID"
    echo "8. Cleanup Old Messages"
    echo "9. Performance Test"
    echo "10. Test Error Cases"
    echo "11. Monitor Services"
    echo "0. Exit"
    echo
}

# ヘルスチェック
health_check() {
    print_header "Health Check"
    execute_request "Application health check" "GET" "$BASE_URL/actuator/health" ""
}

# メッセージ作成
create_message() {
    print_header "Create Message"
    
    echo -e "${YELLOW}Message Types: INFO, WARNING, ERROR, SUCCESS${NC}"
    
    if [ "$CI" = "true" ]; then
        # CI環境では自動テストデータを使用
        local content="Automated test message"
        local sender="ci-test"
        local type="INFO"
        print_info "Using automated test data in CI environment"
        print_info "Content: $content"
        print_info "Sender: $sender"
        print_info "Type: $type"
    else
        read -p "Enter message content: " content
        read -p "Enter sender: " sender
        read -p "Enter message type (INFO/WARNING/ERROR/SUCCESS): " type
    fi
    
    local data="{\"content\":\"$content\",\"sender\":\"$sender\",\"type\":\"$type\"}"
    execute_request "Create new message" "POST" "$API_URL" "$data"
}

# 全メッセージ取得
get_all_messages() {
    print_header "Get All Messages"
    execute_request "Retrieve all messages" "GET" "$API_URL" ""
}

# 送信者でメッセージ取得
get_messages_by_sender() {
    print_header "Get Messages by Sender"
    
    local sender
    if [ "$CI" = "true" ]; then
        sender="ci-test"
        print_info "Using automated sender in CI environment: $sender"
    else
        read -p "Enter sender name: " sender
    fi
    
    execute_request "Get messages by sender: $sender" "GET" "$API_URL/sender/$sender" ""
}

# 緊急メッセージ取得
get_urgent_messages() {
    print_header "Get Urgent Messages"
    execute_request "Get urgent messages (ERROR type)" "GET" "$API_URL/urgent" ""
}

# IDでメッセージ取得
get_message_by_id() {
    print_header "Get Message by ID"
    
    local message_id
    if [ "$CI" = "true" ]; then
        message_id="test-id-123"
        print_info "Using test ID in CI environment: $message_id"
    else
        read -p "Enter message ID: " message_id
    fi
    
    execute_request "Get message by ID: $message_id" "GET" "$API_URL/$message_id" ""
}

# メッセージ削除
delete_message() {
    print_header "Delete Message by ID"
    
    local message_id
    if [ "$CI" = "true" ]; then
        message_id="test-id-123"
        print_info "Using test ID in CI environment: $message_id"
        local confirm="y"
    else
        read -p "Enter message ID to delete: " message_id
        read -p "Are you sure you want to delete message $message_id? (y/n): " -n 1 -r confirm
        echo
    fi
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        execute_request "Delete message: $message_id" "DELETE" "$API_URL/$message_id" ""
    else
        print_info "Delete operation cancelled"
    fi
}

# 古いメッセージクリーンアップ
cleanup_messages() {
    print_header "Cleanup Old Messages"
    
    local minutes
    local confirm
    if [ "$CI" = "true" ]; then
        minutes="0"
        confirm="y"
        print_info "Using automated cleanup in CI environment: $minutes minutes"
    else
        read -p "Enter minutes (messages older than this will be deleted): " minutes
        read -p "Are you sure you want to delete messages older than $minutes minutes? (y/n): " -n 1 -r confirm
        echo
    fi
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        execute_request "Cleanup messages older than $minutes minutes" "DELETE" "$API_URL/cleanup?minutes=$minutes" ""
    else
        print_info "Cleanup operation cancelled"
    fi
}

# パフォーマンステスト
performance_test() {
    print_header "Performance Test"
    
    print_info "Creating 10 concurrent messages..."
    
    local start_time=$(date +%s)
    
    for i in {1..10}; do
        local data="{\"content\":\"Performance test message $i\",\"sender\":\"perf-test\",\"type\":\"INFO\"}"
        curl -s -X POST -H "Content-Type: application/json" -d "$data" "$API_URL" &
    done
    
    wait
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_success "Created 10 messages in $duration seconds"
    
    print_info "Waiting for Kafka processing..."
    sleep 5
    
    print_info "Checking performance test results:"
    execute_request "Get performance test messages" "GET" "$API_URL/sender/perf-test" ""
}

# エラーケーステスト
test_error_cases() {
    print_header "Test Error Cases"
    
    print_info "Testing various error scenarios..."
    
    # 空のコンテンツ
    print_info "1. Testing empty content"
    local empty_content='{"content":"","sender":"test","type":"INFO"}'
    execute_request "Empty content test" "POST" "$API_URL" "$empty_content"
    
    # 空の送信者
    print_info "2. Testing empty sender"
    local empty_sender='{"content":"Test message","sender":"","type":"INFO"}'
    execute_request "Empty sender test" "POST" "$API_URL" "$empty_sender"
    
    # 無効なタイプ
    print_info "3. Testing invalid message type"
    local invalid_type='{"content":"Test message","sender":"test","type":"INVALID"}'
    execute_request "Invalid type test" "POST" "$API_URL" "$invalid_type"
    
    # 存在しないメッセージ取得
    print_info "4. Testing non-existent message retrieval"
    execute_request "Non-existent message test" "GET" "$API_URL/non-existent-id" ""
}

# サービス監視
monitor_services() {
    print_header "Monitor Services"
    
    echo -e "${YELLOW}Available monitoring endpoints:${NC}"
    echo "1. Kafka UI: http://localhost:8080"
    echo "2. Redis Insight: http://localhost:8001"
    echo "3. Application Logs"
    echo "4. Docker Container Status"
    echo
    
    if [ "$CI" = "true" ]; then
        print_info "CI environment detected - showing container status"
        choice="4"
    else
        read -p "Select monitoring option (1-4): " choice
    fi
    
    case $choice in
        1)
            print_info "Kafka UI available at: http://localhost:8080"
            if [ "$CI" != "true" ] && command -v open >/dev/null 2>&1; then
                open "http://localhost:8080"
            elif [ "$CI" != "true" ] && command -v xdg-open >/dev/null 2>&1; then
                xdg-open "http://localhost:8080"
            else
                print_info "Please open http://localhost:8080 in your browser"
            fi
            ;;
        2)
            print_info "Redis Insight available at: http://localhost:8001"
            if [ "$CI" != "true" ] && command -v open >/dev/null 2>&1; then
                open "http://localhost:8001"
            elif [ "$CI" != "true" ] && command -v xdg-open >/dev/null 2>&1; then
                xdg-open "http://localhost:8001"
            else
                print_info "Please open http://localhost:8001 in your browser"
            fi
            ;;
        3)
            print_info "Showing application logs (last 50 lines):"
            if command -v docker >/dev/null 2>&1; then
                if docker compose version >/dev/null 2>&1; then
                    docker compose logs --tail=50 app
                elif command -v docker-compose >/dev/null 2>&1; then
                    docker-compose logs --tail=50 app
                else
                    print_error "Docker Compose not available"
                fi
            else
                print_error "Docker not available"
            fi
            ;;
        4)
            print_info "Docker container status:"
            if command -v docker >/dev/null 2>&1; then
                if docker compose version >/dev/null 2>&1; then
                    docker compose ps
                elif command -v docker-compose >/dev/null 2>&1; then
                    docker-compose ps
                else
                    print_error "Docker Compose not available"
                fi
            else
                print_error "Docker not available"
            fi
            ;;
        *)
            print_error "Invalid option"
            ;;
    esac
}

# メイン実行ループ
main() {
    # 初期チェック
    if ! curl -s "$BASE_URL/actuator/health" > /dev/null 2>&1; then
        print_error "Application is not running. Please start it first with:"
        print_error "docker compose --profile local-infra up --build -d"
        exit 1
    fi
    
    # CI環境では自動テストモードで実行
    if [ "$CI" = "true" ]; then
        print_info "Running in CI mode - executing automated tests"
        health_check
        create_message
        get_all_messages
        get_messages_by_sender
        get_urgent_messages
        test_error_cases
        performance_test
        print_success "All manual tests completed in CI mode"
        return 0
    fi
    
    # 対話モード
    while true; do
        show_menu
        read -p "Enter your choice: " choice
        
        case $choice in
            1) health_check ;;
            2) create_message ;;
            3) get_all_messages ;;
            4) get_messages_by_sender ;;
            5) get_urgent_messages ;;
            6) get_message_by_id ;;
            7) delete_message ;;
            8) cleanup_messages ;;
            9) performance_test ;;
            10) test_error_cases ;;
            11) monitor_services ;;
            0) 
                print_success "Goodbye!"
                exit 0
                ;;
            *) 
                print_error "Invalid option. Please try again."
                ;;
        esac
        
        echo
        if [ "$CI" != "true" ]; then
            read -p "Press Enter to continue..." -r
        fi
    done
}

# スクリプト実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
