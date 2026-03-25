#!/bin/bash
# Podmanコンテナ監視スクリプト
# 各コンテナの状態を監視し、異常があれば通知する

set -euo pipefail

# ログ出力関数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

# エラー処理関数
error_exit() {
    log "エラー: $1"
    exit 1
}

# 設定読み込み
CONFIG_FILE="${CONFIG_FILE:-./.env}"
if [[ -f "$CONFIG_FILE" ]]; then
    # 設定ファイルが存在する場合は読み込む
    export $(cat "$CONFIG_FILE" | xargs)
    log "設定ファイルを読み込みました: $CONFIG_FILE"
else
    log "警告: 設定ファイルが見つかりません: $CONFIG_FILE"
fi

# 監視対象コンテナリスト
CONTAINERS_TO_MONITOR="${CONTAINERS_TO_MONITOR:-$(podman ps -q)}"
ALERT_EMAIL="${ALERT_EMAIL:-admin@example.com}"

# ヘルスチェック関数
health_check() {
    local container_id="$1"
    local container_name="$2"
    
    # コンテナの詳細情報を取得
    local status
    status=$(podman inspect --format "{{.State.Status}}" "$container_id" 2>/dev/null || echo "error")
    
    # 再起動回数を確認
    local restart_count
    restart_count=$(podman inspect --format "{{.RestartCount}}" "$container_id" 2>/dev/null || echo "0")
    
    # メモリ使用量を取得
    local memory_usage
    memory_usage=$(podman stats --no-stream --format "table {{.MemUsage}}" "$container_id" 2>/dev/null | tail -n +2 || echo "N/A")
    
    # 結果出力
    echo "コンテナ: $container_name ($container_id)"
    echo "  状態: $status"
    echo "  再起動回数: $restart_count"
    echo "  メモリ使用量: $memory_usage"
    
    # アラート条件をチェック
    if [[ "$status" != "running" ]]; then
        log "アラート: コンテナ $container_name が停止しています"
        send_alert "Container Down" "$container_name is not running. Current status: $status"
    fi
    
    if [[ "$restart_count" -gt "${MAX_RESTART_COUNT:-5}" ]]; then
        log "アラート: コンテナ $container_name の再起動回数が多すぎます: $restart_count"
        send_alert "High Restart Count" "$container_name has restarted $restart_count times"
    fi
}

# アラート送信関数
send_alert() {
    local alert_type="$1"
    local message="$2"
    
    # シンプルなログ出力（実際にはメールやSlackなどに送る）
    log "ALERT [${alert_type}]: ${message}"
    
    # メールアラート（コメントアウトされていますが、必要に応じて有効化）
    # echo "Subject: Podman Monitor Alert - $alert_type" | \
    #     sendmail -f "$ALERT_EMAIL" "$ALERT_EMAIL"
}

# メイン処理
main() {
    log "コンテナ監視を開始します"
    
    if [[ -z "$CONTAINERS_TO_MONITOR" ]]; then
        log "監視対象のコンテナがありません"
        exit 0
    fi
    
    for container_id in $CONTAINERS_TO_MONITOR; do
        container_name=$(podman inspect --format "{{.Name}}" "$container_id" 2>/dev/null || echo "unknown")
        health_check "$container_id" "$container_name"
        echo ""
    done
    
    log "コンテナ監視が完了しました"
}

# スクリプト実行
main "$@"
