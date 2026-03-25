#!/bin/bash
# Podmanコンテナ管理補助スクリプト
# コンテナの操作を簡略化するためのヘルパー関数群

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
    export $(cat "$CONFIG_FILE" | xargs)
    log "設定ファイルを読み込みました: $CONFIG_FILE"
else
    log "警告: 設定ファイルが見つかりません: $CONFIG_FILE"
fi

# コンテナのバックアップを作成
backup_container() {
    local container_name="$1"
    local backup_dir="${BACKUP_DIR:-./backups}"
    
    if [[ ! -d "$backup_dir" ]]; then
        mkdir -p "$backup_dir"
    fi
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_dir/${container_name}_backup_$timestamp.tar.gz"
    
    log "コンテナ $container_name をバックアップ中: $backup_file"
    
    # コンテナの変更されたファイルをアーカイブ
    podman export "$container_name" | gzip > "$backup_file"
    
    log "バックアップ完了: $backup_file"
}

# コンテナのリストア
restore_container() {
    local container_name="$1"
    local backup_file="$2"
    
    if [[ ! -f "$backup_file" ]]; then
        error_exit "バックアップファイルが存在しません: $backup_file"
    fi
    
    log "バックアップからコンテナを復元: $container_name"
    
    # バックアップからコンテナをインポート
    gunzip -c "$backup_file" | podman import - "$container_name:restored"
    
    log "復元完了: $container_name"
}

# ログ収集
collect_logs() {
    local container_name="$1"
    local log_dir="${LOG_DIR:-./logs}"
    
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir"
    fi
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local log_file="$log_dir/${container_name}_logs_$timestamp.txt"
    
    log "コンテナ $container_name のログを収集: $log_file"
    
    # ログをファイルに保存
    podman logs "$container_name" > "$log_file"
    
    # 最新のエラーログも別途保存
    local error_log_file="$log_dir/${container_name}_errors_$timestamp.txt"
    podman logs "$container_name" 2>&1 | grep -i "error\|warn\|exception\|critical" > "$error_log_file" || true
    
    log "ログ収集完了"
}

# リソース使用量の表示
show_resources() {
    local container_name="$1"
    
    echo "コンテナ: $container_name"
    echo "------------------------"
    
    # CPU使用率
    local cpu_usage
    cpu_usage=$(podman stats --no-stream --format "table {{.CPUPerc}}" "$container_name" 2>/dev/null | tail -n +2)
    echo "CPU使用率: $cpu_usage"
    
    # メモリ使用量
    local mem_usage
    mem_usage=$(podman stats --no-stream --format "table {{.MemUsage}}" "$container_name" 2>/dev/null | tail -n +2)
    echo "メモリ使用量: $mem_usage"
    
    # ネットワークIO
    local net_io
    net_io=$(podman stats --no-stream --format "table {{.NetIO}}" "$container_name" 2>/dev/null | tail -n +2)
    echo "ネットワークIO: $net_io"
    
    # ブロックIO
    local block_io
    block_io=$(podman stats --no-stream --format "table {{.BlockIO}}" "$container_name" 2>/dev/null | tail -n +2)
    echo "ブロックIO: $block_io"
    
    echo ""
}

# イメージのクリーンアップ
cleanup_images() {
    local keep_last_n="${CLEANUP_KEEP_LAST_N:-5}"
    
    log "古いイメージを削除中 (最新$keep_last_n個を保持)"
    
    # 使用されていないイメージを削除
    podman image prune -f
    
    # タグなしの浮遊イメージを削除
    podman images -f "dangling=true" -q | xargs -r podman rmi
    
    log "イメージクリーンアップ完了"
}

# コンテナのクリーンアップ
cleanup_containers() {
    local keep_containers="${CLEANUP_KEEP_CONTAINERS:-}"
    
    log "停止中のコンテナを削除中"
    
    # 除外リストに含まれていない停止中のコンテナを削除
    podman ps -a -f "status=exited" -q | while read -r container_id; do
        local container_name
        container_name=$(podman inspect --format "{{.Name}}" "$container_id" 2>/dev/null || echo "")
        
        # 除外リストに含まれているか確認
        if [[ -n "$keep_containers" && "$keep_containers" =~ (^|,)"$container_name"(|,)$ ]]; then
            log "コンテナ $container_name はクリーンアップから除外されました"
            continue
        fi
        
        podman rm "$container_id"
        log "コンテナを削除: $container_id ($container_name)"
    done
    
    log "コンテナクリーンアップ完了"
}

# ヘルプ表示
show_help() {
    cat << 'EOF'
Podmanコンテナ管理補助スクリプト

使用方法:
  container-helper.sh [オプション] [引数]

オプション:
  backup <container_name>    - コンテナのバックアップを作成
  restore <container_name> <backup_file> - バックアップからコンテナを復元
  logs <container_name>      - コンテナのログを収集
  resources <container_name> - リソース使用量を表示
  cleanup-images           - 古いイメージをクリーンアップ
  cleanup-containers       - 停止中のコンテナをクリーンアップ
  help                     - このヘルプを表示

環境変数:
  BACKUP_DIR               - バックアップファイルの保存ディレクトリ (デフォルト: ./backups)
  LOG_DIR                  - ログファイルの保存ディレクトリ (デフォルト: ./logs)
  CLEANUP_KEEP_LAST_N      - クリーンアップ時に保持するイメージ数 (デフォルト: 5)
  CLEANUP_KEEP_CONTAINERS  - クリーンアップから除外するコンテナ名 (カンマ区切り)
EOF
}

# メイン処理
case "${1:-help}" in
    backup)
        if [[ $# -ne 2 ]]; then
            error_exit "コンテナ名を指定してください"
        fi
        backup_container "$2"
        ;;
    restore)
        if [[ $# -ne 3 ]]; then
            error_exit "コンテナ名とバックアップファイルを指定してください"
        fi
        restore_container "$2" "$3"
        ;;
    logs)
        if [[ $# -ne 2 ]]; then
            error_exit "コンテナ名を指定してください"
        fi
        collect_logs "$2"
        ;;
    resources)
        if [[ $# -ne 2 ]]; then
            error_exit "コンテナ名を指定してください"
        fi
        show_resources "$2"
        ;;
    cleanup-images)
        cleanup_images
        ;;
    cleanup-containers)
        cleanup_containers
        ;;
    help|"--help"|"-h")
        show_help
        ;;
    *)
        error_exit "不明なオプション: $1"
        show_help
        exit 1
        ;;
esac
