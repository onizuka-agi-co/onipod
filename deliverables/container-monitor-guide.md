# コンテナ監視ガイド

このガイドでは、Podmanコンテナの監視と管理について説明します。

## 概要

コンテナ監視スクリプトは、Podmanコンテナの状態を定期的に監視し、問題が発生した場合にアラートを出す機能を提供します。

## 主な機能

### 1. 状態監視
- 各コンテナの実行状態をチェック
- 停止しているコンテナを検出
- 再起動回数が多すぎるコンテナを特定

### 2. リソース監視
- メモリ使用量の監視
- CPU使用率の追跡
- ネットワークおよびブロックIOの監視

### 3. アラート機能
- 状態異常時のアラート通知
- 再起動回数超過時の警告

## 設定

### 環境変数

監視スクリプトは以下の環境変数を使用します：

```
# 監視対象のコンテナリスト（空の場合は全コンテナ）
CONTAINERS_TO_MONITOR="web-app db redis"

# アラート受信メールアドレス
ALERT_EMAIL="admin@example.com"

# 最大再起動回数（これ以上多いとアラート）
MAX_RESTART_COUNT=5

# 設定ファイルのパス
CONFIG_FILE="./monitor.env"
```

### 設定ファイル (.env)

監視設定をファイルで管理できます：

```bash
# .envファイルの例
CONTAINERS_TO_MONITOR=web-app,db,redis
ALERT_EMAIL=admin@example.com
MAX_RESTART_COUNT=3
```

## 使用方法

### 1. 手動での実行

```bash
# 全コンテナを監視
./container-monitor.sh

# 特定のコンテナのみを監視
CONTAINERS_TO_MONITOR="web-app db" ./container-monitor.sh
```

### 2. クーロンジョブによる定期実行

```bash
# 5分ごとに監視を実行
*/5 * * * * /path/to/container-monitor.sh >> /var/log/container-monitor.log 2>&1
```

## マネジメント機能

container-helper.sh スクリプトにより、追加の管理機能が提供されます：

```bash
# ログ収集
./container-helper.sh logs my-container

# リソース使用量表示
./container-helper.sh resources my-container

# コンテナのバックアップ
./container-helper.sh backup my-container

# イメージクリーンアップ
./container-helper.sh cleanup-images

# 停止中のコンテナをクリーンアップ
./container-helper.sh cleanup-containers
```

## 最佳実践

1. **監視頻度の調整**
   - 生産環境では過度な監視を避ける
   - 監視頻度はワークロードに応じて調整

2. **アラートのフィルタリング**
   - 不要なアラートを抑制
   - 重要なイベントのみを通知

3. **バックアップ戦略**
   - 重要なコンテナは定期的にバックアップ
   - バックアップの保持期間を設定

4. **ログの保存**
   - ログは長期保存用に外部サービスに転送
   - ログのローテーションを設定

## トラブルシューティング

### エラー「podman command not found」
- Podmanがインストールされていることを確認
- PATHにPodmanの実行ファイルがあることを確認

### エラー「Permission denied」
- スクリプトの実行権限を確認: `chmod +x container-monitor.sh`
- Podmanのアクセス権を確認

### アラートが届かない場合
- ALERT_EMAILの設定を確認
- メールサーバーの設定を確認

## セキュリティ考慮事項

1. **認証情報の保護**
   - 設定ファイルに認証情報を含めない
   - 必要な場合は暗号化して保存

2. **スクリプトの権限管理**
   - 必要最小限の権限で実行
   - 実行権限を制限

3. **ログの機密情報**
   - 機密情報がログに出力されないように注意
   - ログの暗号化を検討

## メンテナンス

### スクリプトの更新
- 定期的に最新版に更新
- 変更履歴を確認し、影響を評価

### パフォーマンスの確認
- 監視によるパフォーマンスへの影響を監視
- 不要なチェックを削除

## FAQ

Q: 監視対象のコンテナを動的に変更したい
A: CONTAINERS_TO_MONITOR環境変数を変更するか、スクリプトの実行時に指定してください。

Q: 複数のアラート先に通知したい
A: 現在は1つのアドレスのみ対応ですが、スクリプトをカスタマイズすることで複数アドレスに対応できます。

Q: 特定のコンテナだけを無視する方法は？
A: フィルタリングロジックをスクリプトに追加する必要があります。
