#!/bin/bash

# Load Test Script for Kafka Redis Playground
# 負荷テスト用スクリプト

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
LOAD_TEST_LOG="load-test-results.log"

# デフォルト設定
DEFAULT_CONCURRENT_USERS=10
DEFAULT_REQUESTS_PER_USER=10
DEFAULT_RAMP_UP_TIME=5

# ログ関数
log() {
    local level=$1
    shift
    local message="$@"
    
    case $level in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message" | tee -a "$LOAD_TEST_LOG"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message" | tee -a "$LOAD_TEST_LOG"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message" | tee -a "$LOAD_TEST_LOG"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message" | tee -a "$LOAD_TEST_LOG"
            ;;
    esac
}

# 使用方法表示
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
  -u, --users NUMBER       Number of concurrent users (default: $DEFAULT_CONCURRENT_USERS)
  -r, --requests NUMBER    Number of requests per user (default: $DEFAULT_REQUESTS_PER_USER)
  -t, --rampup NUMBER      Ramp-up time in seconds (default: $DEFAULT_RAMP_UP_TIME)
  -m, --mixed              Run mixed workload test
  -s, --spike              Run spike test
  -e, --endurance          Run endurance test
  -h, --help               Show this help message

Examples:
  $0                       # Run basic load test with default settings
  $0 -u 20 -r 50          # 20 users, 50 requests each
  $0 --mixed               # Run mixed workload test
  $0 --spike               # Run spike test
  $0 --endurance           # Run endurance test
EOF
}

# 基本負荷テスト
run_basic_load_test() {
    local users=$1
    local requests_per_user=$2
    local ramp_up_time=$3
    
    log "INFO" "=== Basic Load Test ==="
    log "INFO" "Concurrent Users: $users"
    log "INFO" "Requests per User: $requests_per_user"
    log "INFO" "Ramp-up Time: $ramp_up_time seconds"
    log "INFO" "Total Requests: $((users * requests_per_user))"
    
    local results_file="load_test_results_$(date +%Y%m%d_%H%M%S).txt"
    
    # テスト開始時刻
    local start_time=$(date +%s)
    
    # 並行ユーザーシミュレーション
    for ((user=1; user<=users; user++)); do
        {
            local success_count=0
            local error_count=0
            
            for ((req=1; req<=requests_per_user; req++)); do
                # メッセージデータ
                local data="{\"content\":\"Load test message from user $user, request $req\",\"sender\":\"load-test-user-$user\",\"type\":\"INFO\"}"
                
                # HTTPリクエスト実行
                local response=$(curl -s -w "%{http_code}" -X POST \
                    -H "Content-Type: application/json" \
                    -d "$data" \
                    "$API_URL" 2>/dev/null || echo "000")
                
                if [[ "$response" =~ 201$ ]]; then
                    success_count=$((success_count + 1))
                    echo "User $user, Request $req: SUCCESS" >> "$results_file"
                else
                    error_count=$((error_count + 1))
                    echo "User $user, Request $req: ERROR - $response" >> "$results_file"
                fi
                
                # 短い間隔
                sleep 0.1
            done
            
            echo "User $user: Completed $requests_per_user requests (Success: $success_count, Errors: $error_count)" >> "$results_file"
            
        } &
        
        # ランプアップ時間
        if [ $user -lt $users ] && [ $ramp_up_time -gt 0 ]; then
            sleep $((ramp_up_time / users))
        fi
    done
    
    # 全ユーザーの完了を待機
    wait
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    # 結果集計
    analyze_results "$results_file" $total_duration $users $requests_per_user
}

# 結果分析
analyze_results() {
    local results_file=$1
    local total_duration=$2
    local users=$3
    local requests_per_user=$4
    
    log "INFO" "=== Load Test Results ==="
    
    local total_requests=$((users * requests_per_user))
    local success_count=$(grep -c "SUCCESS" "$results_file" 2>/dev/null || echo 0)
    local error_count=$(grep -c "ERROR" "$results_file" 2>/dev/null || echo 0)
    local success_rate=0
    
    if [ $total_requests -gt 0 ]; then
        success_rate=$((success_count * 100 / total_requests))
    fi
    
    log "INFO" "Test Duration: $total_duration seconds"
    log "INFO" "Total Requests: $total_requests"
    log "SUCCESS" "Successful Requests: $success_count ($success_rate%)"
    
    if [ $error_count -gt 0 ]; then
        log "ERROR" "Failed Requests: $error_count"
    fi
    
    local throughput=0
    if [ $total_duration -gt 0 ]; then
        throughput=$((total_requests / total_duration))
    fi
    log "INFO" "Throughput: $throughput requests/second"
    
    # 結果ファイルの保存場所を通知
    log "INFO" "Detailed results saved to: $results_file"
}

# ミックスワークロードテスト
run_mixed_workload_test() {
    log "INFO" "=== Mixed Workload Test ==="
    
    local duration=30  # 30秒間のテスト（CI環境では短縮）
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    
    log "INFO" "Running mixed workload for $duration seconds..."
    
    # 異なるタイプのリクエストを並行実行
    {
        # 重い作成処理
        while [ $(date +%s) -lt $end_time ]; do
            local data='{"content":"Heavy workload message","sender":"heavy-worker","type":"ERROR"}'
            curl -s -X POST -H "Content-Type: application/json" -d "$data" "$API_URL" > /dev/null 2>&1 || true
            sleep 2
        done
    } &
    
    {
        # 軽い読み込み処理
        while [ $(date +%s) -lt $end_time ]; do
            curl -s "$API_URL" > /dev/null 2>&1 || true
            sleep 1
        done
    } &
    
    {
        # 中程度の作成処理
        while [ $(date +%s) -lt $end_time ]; do
            local data='{"content":"Medium workload message","sender":"medium-worker","type":"INFO"}'
            curl -s -X POST -H "Content-Type: application/json" -d "$data" "$API_URL" > /dev/null 2>&1 || true
            sleep 1
        done
    } &
    
    wait
    
    log "SUCCESS" "Mixed workload test completed"
}

# スパイクテスト
run_spike_test() {
    log "INFO" "=== Spike Test ==="
    
    # 通常負荷で開始
    log "INFO" "Phase 1: Normal load (3 users)"
    run_basic_load_test 3 5 1
    
    sleep 2
    
    # スパイク負荷
    log "INFO" "Phase 2: Spike load (10 users)"
    run_basic_load_test 10 3 1
    
    sleep 2
    
    # 通常負荷に戻る
    log "INFO" "Phase 3: Return to normal load (3 users)"
    run_basic_load_test 3 5 1
    
    log "SUCCESS" "Spike test completed"
}

# 耐久テスト
run_endurance_test() {
    log "INFO" "=== Endurance Test ==="
    
    local duration=60  # 1分間（CI環境では短縮）
    local users=5
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    
    log "INFO" "Running endurance test for $duration seconds with $users users..."
    
    local request_count=0
    
    while [ $(date +%s) -lt $end_time ]; do
        for ((user=1; user<=users; user++)); do
            {
                local data="{\"content\":\"Endurance test message $request_count\",\"sender\":\"endurance-user-$user\",\"type\":\"INFO\"}"
                curl -s -X POST -H "Content-Type: application/json" -d "$data" "$API_URL" > /dev/null 2>&1 || true
            } &
        done
        
        request_count=$((request_count + users))
        
        # 3秒間隔
        sleep 3
        
        # 進捗表示
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        local remaining=$((end_time - current_time))
        log "INFO" "Endurance test progress: ${elapsed}s elapsed, ${remaining}s remaining (Requests sent: $request_count)"
    done
    
    wait
    
    log "SUCCESS" "Endurance test completed. Total requests sent: $request_count"
}

# 前提条件チェック
check_prerequisites() {
    # アプリケーションの起動チェック
    if ! curl -s "$BASE_URL/actuator/health" > /dev/null 2>&1; then
        log "ERROR" "Application is not running. Please start it first:"
        log "ERROR" "docker compose --profile local-infra up --build -d"
        exit 1
    fi
    
    # 必要なツールのチェック
    for tool in curl; do
        if ! command -v $tool >/dev/null 2>&1; then
            log "ERROR" "Required tool '$tool' is not installed"
            exit 1
        fi
    done
}

# メイン実行
main() {
    local users=$DEFAULT_CONCURRENT_USERS
    local requests_per_user=$DEFAULT_REQUESTS_PER_USER
    local ramp_up_time=$DEFAULT_RAMP_UP_TIME
    local test_type="basic"
    
    # 引数解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--users)
                users="$2"
                shift 2
                ;;
            -r|--requests)
                requests_per_user="$2"
                shift 2
                ;;
            -t|--rampup)
                ramp_up_time="$2"
                shift 2
                ;;
            -m|--mixed)
                test_type="mixed"
                shift
                ;;
            -s|--spike)
                test_type="spike"
                shift
                ;;
            -e|--endurance)
                test_type="endurance"
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # 前提条件チェック
    check_prerequisites
    
    # テストログ初期化
    > "$LOAD_TEST_LOG"
    
    log "INFO" "Starting load test: $test_type"
    
    # テスト実行
    case $test_type in
        "basic")
            run_basic_load_test $users $requests_per_user $ramp_up_time
            ;;
        "mixed")
            run_mixed_workload_test
            ;;
        "spike")
            run_spike_test
            ;;
        "endurance")
            run_endurance_test
            ;;
    esac
    
    log "SUCCESS" "Load test completed. Check $LOAD_TEST_LOG for detailed logs."
}

# スクリプト実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
