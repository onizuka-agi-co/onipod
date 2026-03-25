# Podman Manager スクリプト ドキュメント

## 概要

`podman_manager.sh` は、Podmanコンテナの監視および管理を行うためのスクリプトです。コンテナの起動、停止、状態確認、ログ表示などの基本的な操作に加えて、コンテナの状態を継続的に監視する機能も提供します。最新版では、セキュアなコンテナ作成、リソース監視、詳細な検査など、多くの新機能が追加されました。

## 前提条件

- Podmanがインストールされていること
- Podmanが正しく動作すること
- jqがインストールされていること（詳細なリソース表示のために必要）

## 使用方法

### スクリプトの権限設定

まず、スクリプトに実行権限を付与してください。

```bash
chmod +x podman_manager.sh
```

### 操作コマンド

#### すべてのコンテナを一覧表示

```bash
./podman_manager.sh list
```

#### 特定のコンテナの状態を確認

```bash
./podman_manager.sh status <CONTAINER_ID>
```

#### コンテナを起動

```bash
./podman_manager.sh start <CONTAINER_ID>
```

#### コンテナを停止

```bash
./podman_manager.sh stop <CONTAINER_ID>
```

#### コンテナを再起動

```bash
./podman_manager.sh restart <CONTAINER_ID>
```

#### コンテナのログを表示

```bash
./podman_manager.sh logs <CONTAINER_ID>
```

#### コンテナのログをリアルタイムで表示

```bash
./podman_manager.sh logs <CONTAINER_ID> follow
```

#### すべてのコンテナを継続的に監視

```bash
./podman_manager.sh monitor
```

#### すべてのコンテナのヘルスチェックを実行

```bash
./podman_manager.sh health-check
```

#### 特定のコンテナのヘルスチェックを実行

```bash
./podman_manager.sh health-check <CONTAINER_ID>
```

#### 新しいセキュアなコンテナを作成

```bash
./podman_manager.sh create <IMAGE> <NAME> [OPTIONS]
```

#### 実行中のコンテナでコマンドを実行

```bash
./podman_manager.sh exec <CONTAINER_ID> <COMMAND>
```

#### 停止したコンテナを削除

```bash
./podman_manager.sh remove <CONTAINER_ID>
```

#### コンテナの詳細情報を表示

```bash
./podman_manager.sh inspect <CONTAINER_ID>
```

#### すべてのコンテナのリソース使用状況を表示

```bash
./podman_manager.sh stats
```

#### 詳細なリソース使用状況を表示

```bash
./podman_manager.sh resources
```

#### 未使用のリソースをクリーンアップ

```bash
./podman_manager.sh prune
```

#### ヘルプを表示

```bash
./podman_manager.sh -h
```

または

```bash
./podman_manager.sh --help
```

## 出力

スクリプトの実行結果はコンソールに出力されると同時に、`/tmp/podman_manager.sh.log` にもログとして保存されます。

## 例

### nginxコンテナを安全に作成して起動する例

1. nginxコンテナを安全な設定で作成

```bash
./podman_manager.sh create nginx my-nginx -p 8080:80
```

2. コンテナの状態を確認

```bash
./podman_manager.sh status my-nginx
```

3. コンテナのログを表示

```bash
./podman_manager.sh logs my-nginx
```

4. コンテナを停止

```bash
./podman_manager.sh stop my-nginx
```

5. コンテナを削除

```bash
./podman_manager.sh remove my-nginx
```

### リソース使用状況を監視する例

1. すべてのコンテナのリソース使用状況を表示

```bash
./podman_manager.sh stats
```

2. 詳細なリソース情報を取得

```bash
./podman_manager.sh resources
```

3. 実行中のコンテナでシェルを開く

```bash
./podman_manager.sh exec my-nginx sh
```

## 注意事項

- このスクリプトはPodmanがシステムに正しくインストールされていることを前提としています。
- 一部の操作にはroot権限が必要になる場合があります（rootless Podmanの場合は不要）。
- 実行時のエラー情報はログファイルに保存されます。
- セキュアなコンテナ作成では、読み取り専用ルートファイルシステム、ユーザー名前空間、権限昇格禁止などのセキュリティ設定がデフォルトで適用されます。

## エラー処理

- 存在しないコマンドが指定された場合、ヘルプメッセージが表示されます。
- 必須パラメータが指定されていない場合は、エラーメッセージが表示されます。
- Podmanがインストールされていない場合は、エラーで終了します。
- コンテナが存在しない場合は適切なエラーメッセージが表示されます。