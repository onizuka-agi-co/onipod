# Podman Manager スクリプト ドキュメント

## 概要

`podman_manager.sh` は、Podmanコンテナの監視および管理を行うためのスクリプトです。コンテナの起動、停止、状態確認、ログ表示などの基本的な操作に加えて、コンテナの状態を継続的に監視する機能も提供します。

## 前提条件

- Podmanがインストールされていること
- Podmanが正しく動作すること

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

#### すべてのコンテナを継続的に監視

```bash
./podman_manager.sh monitor
```

#### すべてのコンテナのヘルスチェックを実行

```bash
./podman_manager.sh health-check
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

### nginxコンテナを起動する例

1. nginxコンテナを作成（または存在確認）

```bash
podman run -d --name my-nginx -p 8080:80 nginx
```

2. スクリプトで起動

```bash
./podman_manager.sh start my-nginx
```

3. 状態を確認

```bash
./podman_manager.sh status my-nginx
```

## 注意事項

- このスクリプトはPodmanがシステムに正しくインストールされていることを前提としています。
- 一部の操作にはroot権限が必要になる場合があります。
- 実行時のエラー情報はログファイルに保存されます。

## エラー処理

- 存在しないコマンドが指定された場合、ヘルプメッセージが表示されます。
- 必須パラメータが指定されていない場合は、エラーメッセージが表示されます。
- Podmanがインストールされていない場合は、エラーで終了します。