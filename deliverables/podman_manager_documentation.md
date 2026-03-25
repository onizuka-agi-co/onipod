# Podman Manager スクリプト ドキュメント

## 概要

`podman_manager.sh` は、Podmanコンテナの監視および管理を行うためのスクリプトです。コンテナの起動、停止、状態確認、ログ表示などの基本的な操作に加えて、コンテナの状態を継続的に監視する機能も提供します。最新版では、セキュアなコンテナ作成、リソース監視、詳細な検査など、多くの新機能が追加されました。

## 前提条件

- Podmanがインストールされていること
- Podmanが正しく動作すること
- jqがインストールされていること（詳細なリソース表示のために必要）
- bcがインストールされていること（詳細なリソース統計表示のために推奨）
- sedがインストールされていること（詳細なリソース統計表示のために推奨）

### 前提条件の確認方法

新しいユーザーのために、必要なツールがシステムにインストールされているか確認する方法を紹介します。

```bash
# Podmanがインストールされているか確認
podman --version

# jqがインストールされているか確認
jq --version

# bcがインストールされているか確認
bc --version

# sedがインストールされているか確認
sed --version
```

### 前提条件のインストール方法（Ubuntu/Debianの場合）

```bash
# Podmanのインストール
sudo apt update
sudo apt install -y podman

# jqのインストール
sudo apt install -y jq

# bcのインストール
sudo apt install -y bc

# Trivy（セキュリティスキャン用）のインストール
sudo apt install -y wget apt-transport-https gnupg
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt update
sudo apt install -y trivy
```

## Podman入門ガイド

PodmanはDockerに代わるコンテナランタイムであり、root権限なしでコンテナを実行できます。以下は基本的な概念の説明です：

- **コンテナ**: アプリケーションとその依存関係を含む軽量な仮想環境
- **イメージ**: コンテナを作成するためのテンプレート
- **Podmanデーモンレス**: Dockerとは異なり、常駐プロセス（デーモン）を必要としません
- **Rootless**: 通常のユーザー権限でコンテナを実行可能

### 基本的なPodmanコマンド

| コマンド | 説明 |
|----------|------|
| `podman run` | 新しいコンテナを実行 |
| `podman ps` | 実行中のコンテナをリスト表示 |
| `podman images` | 利用可能なイメージをリスト表示 |
| `podman pull` | レジストリからイメージをダウンロード |
| `podman stop` | 実行中のコンテナを停止 |
| `podman start` | 停止中のコンテナを開始 |
| `podman logs` | コンテナのログを表示 |

このスクリプト(`podman_manager.sh`)はこれらの基本的なPodmanコマンドをより使いやすくラップしたものです。

## 使用方法

### スクリプトの権限設定

まず、スクリプトに実行権限を付与してください。

```bash
chmod +x podman_manager.sh
```

### 基本的な使用手順

新しいユーザー向けに、スクリプトを最初に使用する際の手順を説明します。

1. **権限の設定**: 上記のように実行権限を設定します。
2. **ヘルプの確認**: 使用可能なコマンドを確認します。
   ```bash
   ./podman_manager.sh --help
   ```
3. **コンテナの確認**: 現在のシステムにあるコンテナを確認します。
   ```bash
   ./podman_manager.sh list
   ```

### 操作コマンド

#### すべてのコンテナを一覧表示

```bash
./podman_manager.sh list
```

このコマンドは、実行中・停止中のすべてのコンテナを表示します。表示される情報には、コンテナID、名前、イメージ、状態、ポートが含まれます。

##### 出力例
```
Listing all containers:
CONTAINER ID  NAMES      IMAGE               STATUS                       PORTS
d9b100f2f636  my-nginx   docker.io/library/nginx:latest  Up 2 hours ago              0.0.0.0:8080->80/tcp
abc234def567  my-db      docker.io/library/postgres:13   Exited (0) 3 days ago
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

#### 詳細なリソース使用状況を表示（アラートしきい値付き）

```bash
./podman_manager.sh stats-detail
```

このコマンドは、CPUとメモリの使用率が指定したしきい値を超えたときに警告を表示するリソースモニタリング機能を提供します。

##### オプションとパラメータ

- `CPU_THRESHOLD`: CPU使用率の警告しきい値（デフォルト: 80%）
- `MEM_THRESHOLD`: メモリ使用率の警告しきい値（デフォルト: 90%）
- `INTERVAL`: 更新間隔（秒単位、デフォルト: 2秒）

##### 使用例

```bash
# デフォルトのしきい値（CPU: 80%, メモリ: 90%）で監視
./podman_manager.sh stats-detail

# カスタムしきい値（CPU: 90%, メモリ: 95%）で監視
./podman_manager.sh stats-detail 90 95

# カスタムしきい値と更新間隔（3秒ごとに更新）で監視
./podman_manager.sh stats-detail 85 90 3
```

#### 詳細なリソース使用状況を表示（アラートしきい値付き）

```bash
./podman_manager.sh stats-detail
```

このコマンドは、CPUとメモリの使用率が指定したしきい値を超えたときに警告を表示するリソースモニタリング機能を提供します。拡張版では、ネットワーク使用量とディスク使用量の監視も可能です。

##### オプションとパラメータ

- `CPU_THRESHOLD`: CPU使用率の警告しきい値（デフォルト: 80%）
- `MEM_THRESHOLD`: メモリ使用率の警告しきい値（デフォルト: 90%）
- `INTERVAL`: 更新間隔（秒単位、デフォルト: 2秒）
- `NETWORK_THRESHOLD`: ネットワーク使用量の警告しきい値（MB単位、オプション）
- `DISK_THRESHOLD`: ディスク使用量の警告しきい値（MB単位、オプション）

##### 使用例

```bash
# デフォルトのしきい値（CPU: 80%, メモリ: 90%）で監視
./podman_manager.sh stats-detail

# カスタムしきい値（CPU: 90%, メモリ: 95%）で監視
./podman_manager.sh stats-detail 90 95

# カスタムしきい値と更新間隔（3秒ごとに更新）で監視
./podman_manager.sh stats-detail 85 90 3

# すべてのしきい値を指定（CPU: 85%, メモリ: 90%, ネットワーク: 100MB, ディスク: 50MB）
./podman_manager.sh stats-detail 85 90 3 100 50
```

#### リソース使用状況のレポート生成

```bash
./podman_manager.sh resource-report
```

このコマンドは、指定された期間にわたってリソース使用状況を監視し、最小・最大・平均値を含む詳細なレポートを生成します。

##### オプションとパラメータ

- `DURATION`: データ収集期間（秒単位、デフォルト: 60秒）
- `INTERVAL`: 測定間隔（秒単位、デフォルト: 5秒）

##### 使用例

```bash
# 60秒間、5秒間隔でリソース使用状況を監視しレポートを生成
./podman_manager.sh resource-report

# 120秒間、10秒間隔でリソース使用状況を監視しレポートを生成
./podman_manager.sh resource-report 120 10
```

#### コンテナイメージのセキュリティスキャン

```bash
./podman_manager.sh security-scan <CONTAINER_NAME>
```

このコマンドは、指定したコンテナイメージをスキャンして脆弱性を検出します。TrivyまたはPodmanの内蔵スキャナーを使用します。拡張版では、設定ミスの検出も可能になりました。

##### オプションとパラメータ

- `CONTAINER_NAME`: スキャン対象のコンテナ名
- `OUTPUT_FORMAT`: 結果の出力形式（table, json, sarif、デフォルト: table）
- `SEVERITY_FILTER`: 表示する脆弱性の重大度（LOW, MEDIUM, HIGH, CRITICAL、デフォルト: HIGH,CRITICAL）
- `LOG_FILE`: 結果を保存するログファイルのパス（デフォルト: security_scan_results_YYYYMMDD_HHMMSS.log）
- `CONFIG_ANALYSIS`: 設定分析を含めるかどうか（true/false、デフォルト: false）

##### 使用例

```bash
# 指定したコンテナのイメージをデフォルト設定でスキャン
./podman_manager.sh security-scan mycontainer

# JSON形式で結果を出力
./podman_manager.sh security-scan mycontainer json

# 全ての重大度の脆弱性と設定分析を含めてスキャン
./podman_manager.sh security-scan mycontainer json "LOW,MEDIUM,HIGH,CRITICAL" custom_output.log true

# 高～中程度の脆弱性をフィルタリング
./podman_manager.sh security-scan mycontainer table "HIGH,MEDIUM,CRITICAL" custom_output.log false
```

#### バッチ操作

```bash
./podman_manager.sh batch-operation <OPERATION> <REGEX_PATTERN> [CONFIRM]
```

このコマンドは、正規表現パターンに一致する複数のコンテナに対して一度に操作を実行します。バッチ操作機能は強化され、一時停止(pause)/再開(unpause)操作が追加され、確認フラグによる安全な操作が可能になりました。

##### オプションとパラメータ

- `OPERATION`: 実行する操作（start, stop, restart, remove, pause, unpause）
- `REGEX_PATTERN`: コンテナ名に一致させる正規表現パターン
- `CONFIRM`: 確認フラグ（省略可、実行前に確認プロンプトを表示）

##### 使用例

```bash
# 名前が'web'で始まるすべてのコンテナを停止
./podman_manager.sh batch-operation stop '^web.*'

# 名前が'db'を含むすべてのコンテナを再起動
./podman_manager.sh batch-operation restart '.*db.*'

# 名前が'app'で終わるすべてのコンテナを開始
./podman_manager.sh batch-operation start '.*app$'

# 名前が'alpine-'で始まるすべてのコンテナを削除（実行前に確認）
./podman_manager.sh batch-operation remove '^alpine-.*' confirm

# 名前が'cache'を含むすべてのコンテナを一時停止
./podman_manager.sh batch-operation pause '.*cache.*'

# 名前が'cache'を含むすべてのコンテナを再開
./podman_manager.sh batch-operation unpause '.*cache.*'
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

#### 詳細なリソース使用状況を表示（アラートしきい値付き）

```bash
./podman_manager.sh stats-detail
```

このコマンドは、CPUとメモリの使用率が指定したしきい値を超えたときに警告を表示するリソースモニタリング機能を提供します。

##### オプションとパラメータ

- `CPU_THRESHOLD`: CPU使用率の警告しきい値（デフォルト: 80%）
- `MEM_THRESHOLD`: メモリ使用率の警告しきい値（デフォルト: 90%）
- `INTERVAL`: 更新間隔（秒単位、デフォルト: 2秒）

##### 使用例

```bash
# デフォルトのしきい値（CPU: 80%, メモリ: 90%）で監視
./podman_manager.sh stats-detail

# カスタムしきい値（CPU: 90%, メモリ: 95%）で監視
./podman_manager.sh stats-detail 90 95

# カスタムしきい値と更新間隔（3秒ごとに更新）で監視
./podman_manager.sh stats-detail 85 90 3
```

#### 詳細なリソース使用状況を表示（アラートしきい値付き）

```bash
./podman_manager.sh stats-detail
```

このコマンドは、CPUとメモリの使用率が指定したしきい値を超えたときに警告を表示するリソースモニタリング機能を提供します。拡張版では、ネットワーク使用量とディスク使用量の監視も可能です。

##### オプションとパラメータ

- `CPU_THRESHOLD`: CPU使用率の警告しきい値（デフォルト: 80%）
- `MEM_THRESHOLD`: メモリ使用率の警告しきい値（デフォルト: 90%）
- `INTERVAL`: 更新間隔（秒単位、デフォルト: 2秒）
- `NETWORK_THRESHOLD`: ネットワーク使用量の警告しきい値（MB単位、オプション）
- `DISK_THRESHOLD`: ディスク使用量の警告しきい値（MB単位、オプション）

##### 使用例

```bash
# デフォルトのしきい値（CPU: 80%, メモリ: 90%）で監視
./podman_manager.sh stats-detail

# カスタムしきい値（CPU: 90%, メモリ: 95%）で監視
./podman_manager.sh stats-detail 90 95

# カスタムしきい値と更新間隔（3秒ごとに更新）で監視
./podman_manager.sh stats-detail 85 90 3

# すべてのしきい値を指定（CPU: 85%, メモリ: 90%, ネットワーク: 100MB, ディスク: 50MB）
./podman_manager.sh stats-detail 85 90 3 100 50
```

#### リソース使用状況のレポート生成

```bash
./podman_manager.sh resource-report
```

このコマンドは、指定された期間にわたってリソース使用状況を監視し、最小・最大・平均値を含む詳細なレポートを生成します。

##### オプションとパラメータ

- `DURATION`: データ収集期間（秒単位、デフォルト: 60秒）
- `INTERVAL`: 測定間隔（秒単位、デフォルト: 5秒）

##### 使用例

```bash
# 60秒間、5秒間隔でリソース使用状況を監視しレポートを生成
./podman_manager.sh resource-report

# 120秒間、10秒間隔でリソース使用状況を監視しレポートを生成
./podman_manager.sh resource-report 120 10
```

#### コンテナイメージのセキュリティスキャン

```bash
./podman_manager.sh security-scan <CONTAINER_NAME>
```

このコマンドは、指定したコンテナイメージをスキャンして脆弱性を検出します。TrivyまたはPodmanの内蔵スキャナーを使用します。拡張版では、設定ミスの検出も可能になりました。

##### オプションとパラメータ

- `CONTAINER_NAME`: スキャン対象のコンテナ名
- `OUTPUT_FORMAT`: 結果の出力形式（table, json, sarif、デフォルト: table）
- `SEVERITY_FILTER`: 表示する脆弱性の重大度（LOW, MEDIUM, HIGH, CRITICAL、デフォルト: HIGH,CRITICAL）
- `LOG_FILE`: 結果を保存するログファイルのパス（デフォルト: security_scan_results_YYYYMMDD_HHMMSS.log）
- `CONFIG_ANALYSIS`: 設定分析を含めるかどうか（true/false、デフォルト: false）

##### 使用例

```bash
# 指定したコンテナのイメージをデフォルト設定でスキャン
./podman_manager.sh security-scan mycontainer

# JSON形式で結果を出力
./podman_manager.sh security-scan mycontainer json

# 全ての重大度の脆弱性と設定分析を含めてスキャン
./podman_manager.sh security-scan mycontainer json "LOW,MEDIUM,HIGH,CRITICAL" custom_output.log true

# 高～中程度の脆弱性をフィルタリング
./podman_manager.sh security-scan mycontainer table "HIGH,MEDIUM,CRITICAL" custom_output.log false
```

#### バッチ操作

```bash
./podman_manager.sh batch-operation <OPERATION> <REGEX_PATTERN> [CONFIRM]
```

このコマンドは、正規表現パターンに一致する複数のコンテナに対して一度に操作を実行します。バッチ操作機能は強化され、一時停止(pause)/再開(unpause)操作が追加され、確認フラグによる安全な操作が可能になりました。

##### オプションとパラメータ

- `OPERATION`: 実行する操作（start, stop, restart, remove, pause, unpause）
- `REGEX_PATTERN`: コンテナ名に一致させる正規表現パターン
- `CONFIRM`: 確認フラグ（省略可、実行前に確認プロンプトを表示）

##### 使用例

```bash
# 名前が'web'で始まるすべてのコンテナを停止
./podman_manager.sh batch-operation stop '^web.*'

# 名前が'db'を含むすべてのコンテナを再起動
./podman_manager.sh batch-operation restart '.*db.*'

# 名前が'app'で終わるすべてのコンテナを開始
./podman_manager.sh batch-operation start '.*app$'

# 名前が'alpine-'で始まるすべてのコンテナを削除（実行前に確認）
./podman_manager.sh batch-operation remove '^alpine-.*' confirm

# 名前が'cache'を含むすべてのコンテナを一時停止
./podman_manager.sh batch-operation pause '.*cache.*'

# 名前が'cache'を含むすべてのコンテナを再開
./podman_manager.sh batch-operation unpause '.*cache.*'
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

### 初心者向けチュートリアル：WordPressサイトをセットアップする

このセクションでは、初心者が実際にPodman Managerを使用してWordPressサイトをセットアップする手順を説明します。

1. **MySQLデータベースコンテナを作成**

   まず、WordPress用のデータベースコンテナを作成します。

   ```bash
   # MySQL 8を実行するコンテナを作成
   podman run -d \
     --name wordpress-mysql \
     -e MYSQL_ROOT_PASSWORD=rootpassword \
     -e MYSQL_DATABASE=wordpress \
     -e MYSQL_USER=wp_user \
     -e MYSQL_PASSWORD=wp_password \
     -p 3306:3306 \
     mysql:8
   ```

2. **WordPressコンテナを作成**

   次に、上で作成したデータベースに接続するWordPressコンテナを作成します。

   ```bash
   # WordPressコンテナを作成
   podman run -d \
     --name my-wordpress \
     -e WORDPRESS_DB_HOST=wordpress-mysql \
     -e WORDPRESS_DB_USER=wp_user \
     -e WORDPRESS_DB_PASSWORD=wp_password \
     -e WORDPRESS_DB_NAME=wordpress \
     -p 8080:80 \
     --link wordpress-mysql:mysql \
     wordpress:latest
   ```

3. **コンテナの状態を確認**

   作成したコンテナの状態を確認します。

   ```bash
   # すべてのコンテナをリスト表示
   ./podman_manager.sh list

   # 各コンテナの詳細ステータスを確認
   ./podman_manager.sh status wordpress-mysql
   ./podman_manager.sh status my-wordpress
   ```

4. **リソース使用状況を監視**

   リソース使用状況を監視して、コンテナが正常に動作していることを確認します。

   ```bash
   # 簡易リソース監視
   ./podman_manager.sh stats

   # 詳細リソース監視（しきい値を低めに設定して警告を確認）
   ./podman_manager.sh stats-detail 50 60 5
   ```

5. **ログを確認**

   問題がないかログを確認します。

   ```bash
   # WordPressコンテナのログを確認
   ./podman_manager.sh logs my-wordpress

   # リアルタイムでログを監視
   ./podman_manager.sh logs my-wordpress follow
   ```

6. **サービスへのアクセス**

   WordPressサイトは http://localhost:8080 でアクセスできます。

7. **コンテナの管理**

   必要に応じてコンテナを停止・再開・削除できます。

   ```bash
   # コンテナを停止
   ./podman_manager.sh stop my-wordpress
   ./podman_manager.sh stop wordpress-mysql

   # コンテナを再開
   ./podman_manager.sh start wordpress-mysql
   ./podman_manager.sh start my-wordpress

   # コンテナを削除（注意：データが失われます）
   ./podman_manager.sh remove my-wordpress
   ./podman_manager.sh remove wordpress-mysql
   ```

### 拡張機能の活用例

1. **高度なリソース監視**

```bash
# カスタマイズされたしきい値でリソース使用状況を監視
./podman_manager.sh stats-detail 85 90 3 100 50

# 一定時間のリソース使用状況を記録してレポートを生成
./podman_manager.sh resource-report 300 10
```

2. **セキュリティスキャンの活用**

```bash
# イメージの詳細なセキュリティスキャン（設定ミスも検出）
./podman_manager.sh security-scan mycontainer json "LOW,MEDIUM,HIGH,CRITICAL" my_scan.log true

# セキュリティレポートに基づくアクション
./podman_manager.sh security-scan mycontainer table "CRITICAL,HIGH" --severity-filter="CRITICAL,HIGH"
```

3. **高度なバッチ操作**

```bash
# 一時停止/再開機能の使用
./podman_manager.sh batch-operation pause '^dev-.*'  # 開発環境のコンテナを一時停止

./podman_manager.sh batch-operation unpause '^dev-.*'  # 開発環境のコンテナを再開

# 危険な操作に対する確認付き実行
./podman_manager.sh batch-operation remove '^temp-.*' confirm
```

## 注意事項

- このスクリプトはPodmanがシステムに正しくインストールされていることを前提としています。
- 一部の操作にはroot権限が必要になる場合があります（rootless Podmanの場合は不要）。
- 実行時のエラー情報はログファイルに保存されます。
- セキュアなコンテナ作成では、読み取り専用ルートファイルシステム、ユーザー名前空間、権限昇格禁止などのセキュリティ設定がデフォルトで適用されます。

## トラブルシューティング

### 一般的な問題

- **コマンドが見つからないエラー**: スクリプトに実行権限が付与されているか確認してください (`chmod +x podman_manager.sh`)
- **Podmanが見つかりません**: Podmanがシステムに正しくインストールされており、PATHに含まれているか確認してください
- **リソース統計が表示されない**: コンテナが実行中であるか確認してください
- **色付けが正しく表示されない**: ターミナルがANSIカラーをサポートしているか確認してください

### 解決策付きトラブルシューティング

以下は一般的な問題とその解決策です：

#### Podmanが動作しない問題

1. **問題**: "Error: Podman is not installed or not in PATH"というエラーが出る
2. **原因**: Podmanがインストールされていない、またはPATHが通っていない
3. **解決策**:
   - Podmanが正しくインストールされているか確認: `podman --version`
   - インストールされていない場合は、上記の「前提条件のインストール方法」を参照してインストール
   - Podmanが実行可能か確認: `which podman`

#### 実行権限に関する問題

1. **問題**: "Permission denied"エラー
2. **原因**: スクリプトに実行権限が設定されていない
3. **解決策**:
   ```bash
   chmod +x podman_manager.sh
   ```

#### コンテナが起動しない問題

1. **問題**: `./podman_manager.sh start <CONTAINER_ID>` を実行してもコンテナが起動しない
2. **原因**:
   - コンテナが破損している
   - ポート競合が発生している
   - 必要なリソースが不足している
3. **解決策**:
   - コンテナの詳細を確認: `./podman_manager.sh status <CONTAINER_ID>`
   - コンテナのログを確認: `./podman_manager.sh logs <CONTAINER_ID>`
   - システムのリソース使用状況を確認: `./podman_manager.sh stats`

#### リソース統計が正しく表示されない問題

1. **問題**: `stats`または`stats-detail`コマンドが正しく動作しない
2. **原因**:
   - 実行中にコンテナがない
   - 必要なツール（bc, sed, jq）がインストールされていない
3. **解決策**:
   - コンテナが実行中であることを確認: `./podman_manager.sh ps`
   - 必要なツールをインストール: `sudo apt install bc sed jq`

#### セキュリティスキャン機能が動作しない問題

1. **問題**: `security-scan`コマンドが失敗する
2. **原因**:
   - Trivyがインストールされていない
   - コンテナが存在しない
3. **解決策**:
   - Trivyをインストール: `sudo apt install trivy`（上記インストール方法を参照）
   - コンテナが存在するか確認: `./podman_manager.sh list`
   - コンテナ名を正確に入力しているか確認

### 詳細リソースモニタリング (stats-detail) の問題

- **bcが見つかりません**: 詳細な数値比較機能が正しく動作しない場合があります。`bc`コマンドをインストールしてください (`sudo apt install bc` または同等のコマンド)
- **sedが見つかりません**: 詳細統計が正しく動作しない場合があります。`sed`をインストールしてください
- **しきい値アラートが正しく動作しない**: 数値比較の際、小数点以下の扱いで問題が発生する可能性があります。`bc`コマンドのインストールを確認してください

### セキュリティスキャン (security-scan) の問題

- **Trivyが見つかりません**: セキュリティスキャンが失敗する場合はTrivyがインストールされているか確認してください
  - Trivyのインストール: https://aquasecurity.github.io/trivy/
  - Trivyがインストールされていない場合、スクリプトは代替手段を試みます
- **スキャン結果が表示されない**: 出力形式や重大度フィルターが適切に設定されているか確認してください
- **スキャンが失敗する**: コンテナが存在するか、およびコンテナイメージにアクセス可能であるか確認してください

### バッチ操作 (batch-operation) の問題

- **パターンに一致するコンテナが見つからない**: 正規表現パターンが正しいか確認してください
- **操作が一部のコンテナで失敗する**: 個々のコンテナが他の操作によって変更されている可能性があります
- **不正な操作コマンド**: 使用できる操作は start, stop, restart, remove のいずれかのみです

### リソースレポート (resource-report) の問題

- **データが収集されない**: 監視対象のコンテナが実行中であるか確認してください
- **統計情報が表示されない**: Podmanの統計機能が利用可能であるか確認してください
- **レポートの生成に時間がかかる**: 収集期間が長すぎる場合、短めの期間で試してください

### 拡張されたバッチ操作 (batch-operation) の問題

- **パターンに一致するコンテナが見つからない**: 正規表現パターンが正しいか確認してください
- **操作が一部のコンテナで失敗する**: 個々のコンテナが他の操作によって変更されている可能性があります
- **新しい操作タイプ (pause/unpause) が使えない**: 使用できる操作は start, stop, restart, remove, pause, unpause のいずれかのみです
- **確認フラグが機能しない**: コマンドライン引数が正しく渡されているか確認してください

### 拡張されたセキュリティスキャン (security-scan) の問題

- **設定分析が有効にならない**: 5番目のパラメータとして "true" を指定しているか確認してください
- **JSON出力が正しくない**: jqコマンドがインストールされているか確認してください
- **カスタムログファイル名が認識されない**: ファイルパスが有効であるか確認してください

### その他の問題

- **権限エラー**: 一部の操作にはroot権限が必要になる場合があります（rootless Podmanを使用していない場合）
- **ログファイルが生成されない**: ログの出力先ディレクトリに書き込み権限があるか確認してください

### デバッグ手順

1. **基本情報の確認**:
   ```bash
   # Podmanのバージョン確認
   podman --version

   # スクリプトの実行権限確認
   ls -la podman_manager.sh

   # 現在のコンテナ状態確認
   ./podman_manager.sh list
   ```

2. **問題のあるコンテナの調査**:
   ```bash
   # 特定のコンテナの詳細状態
   ./podman_manager.sh status <CONTAINER_ID>

   # コンテナのログ確認
   ./podman_manager.sh logs <CONTAINER_ID>
   ```

3. **詳細な診断**:
   ```bash
   # システム全体の状態
   ./podman_manager.sh stats

   # 実行中のプロセス確認
   ./podman_manager.sh ps
   ```

### 問題報告の際の情報

問題を報告する際は、以下の情報を含めてください：
- 使用しているオペレーティングシステム
- Podmanのバージョン (`podman --version`)
- 実行したコマンド
- 発生したエラーメッセージの全文
- ログファイル (`/tmp/podman_manager.sh.log`) の関連部分

## よくある質問 (FAQ)

### Q1: Podman Managerと直接Podmanコマンドを使う違いは何ですか？

A: Podman ManagerはPodmanの機能をラップして使いやすくするためのスクリプトです。以下の利点があります：
- より分かりやすいコマンド構造
- 便利なショートカット機能（例：詳細なリソース監視、バッチ操作、セキュリティスキャン）
- 色付きの出力による視認性の向上
- エラーハンドリングの簡略化

### Q2: コンテナIDではなく名前で操作できますか？

A: はい、ほとんどのコマンドでコンテナIDのかわりにコンテナ名を使用できます。例えば：
```bash
./podman_manager.sh stop my-container-name
./podman_manager.sh logs my-container-name
./podman_manager.sh status my-container-name
```

### Q3: ポートフォワーディングを指定してコンテナを作成するにはどうすればいいですか？

A: 現在のバージョンでは、コンテナを作成するには直接Podmanコマンドを使用してください：
```bash
podman run -d --name my-container -p 8080:80 nginx
```
その後、Podman Managerを使用して管理できます：
```bash
./podman_manager.sh status my-container
./podman_manager.sh logs my-container
```

### Q4: statsとstats-detailの違いは何ですか？

A:
- `stats`コマンド: 基本的なリソース使用状況（CPU、メモリ、ネットワークI/O）を一度だけ表示
- `stats-detail`コマンド: 詳細なリソース情報をリアルタイムに監視し、設定したしきい値を超えた場合に警告を表示

### Q5: セキュリティスキャンで検出された脆弱性の対処方法を教えてください

A: 高または重大度の脆弱性が検出された場合は、以下の対応を検討してください：
1. イメージの更新: 最新のセキュリティパッチが適用されたイメージに更新
2. イメージの選択: よりセキュリティに配慮したベースイメージの使用
3. 最小限の権限: コンテナ内で必要最小限の権限でプロセスを実行

### Q6: ログファイルの場所を変更できますか？

A: 現在のバージョンでは、すべてのログは `/tmp/podman_manager.sh.log` に出力されます。ファイル名の変更は現時点ではサポートしていません。

### Q7: バッチ操作で使える正規表現の例を教えてください

A:
- `^web.*`: 'web'で始まる名前のコンテナ（例：web-server, web-app）
- `.*database.*`: 名前に'database'を含むコンテナ（例：mysql-database, postgres-database）
- `.*-[0-9]+$`: 数字で終わる名前のコンテナ（例：app-01, app-02）
- `^prod-.*`: 'prod-'で始まる運用環境のコンテナ

### Q8: ルートユーザー以外でも使用できますか？

A: はい、Podmanはrootless（非root）モードに対応しているので、通常のユーザー権限でも使用できます。ただし、一部のネットワーク設定や特定のシステムレベルの操作には特別な設定が必要になる場合があります。

### Q9: statsとstats-detail、resource-reportの違いは何ですか？

A:
- `stats`コマンド: 基本的なリソース使用状況（CPU、メモリ、ネットワークI/O）を一度だけ表示
- `stats-detail`コマンド: 詳細なリソース情報をリアルタイムに監視し、設定したしきい値を超えた場合に警告を表示
- `resource-report`コマンド: 指定された期間にわたってリソース使用状況を監視し、最小・最大・平均値を含む詳細なレポートを生成

### Q10: バッチ操作に追加されたpause/unpauseとは何ですか？

A: `pause`と`unpause`はコンテナの実行状態を一時停止/再開するための操作です。これにより、コンテナを完全に停止することなくリソース消費を一時的に止めることができます。バッチ操作では、複数のコンテナを一度に一時停止または再開できます。

### Q11: セキュリティスキャンの設定分析とは何ですか？

A: セキュリティスキャンでの設定分析は、コンテナイメージ内のセキュリティ上の誤った設定や脆弱な構成を検出する機能です。例えば、管理者権限で実行されるべきではないプロセスがrootで実行されていること、公開すべきでないポートが開放されていることなどを検出します。

### Q12: 確認付きバッチ操作の使用方法を教えてください

A: 確認付きバッチ操作は、危険な操作（特に削除操作）を実行する前に確認を求めます。使用方法は次の通りです：
```bash
# 確認付きでバッチ操作を実行
./podman_manager.sh batch-operation remove '^temp-.*' confirm
```
実行すると、指定されたパターンに一致するコンテナの一覧が表示され、操作を実行するか確認されます。

## エラー処理

- 存在しないコマンドが指定された場合、ヘルプメッセージが表示されます。
- 必須パラメータが指定されていない場合は、エラーメッセージが表示されます。
- Podmanがインストールされていない場合は、エラーで終了します。
- コンテナが存在しない場合は適切なエラーメッセージが表示されます。