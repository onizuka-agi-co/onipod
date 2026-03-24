# 🧬 Evolutionary Meeting Bot

CTO会議とCEO会議が30分交替で実行され、自己改善して進化するシステム。

## 📁 成果物

| パス | 内容 | 更新タイミング |
|------|------|----------------|
| `company/mission.md` | ミッション | 低頻度 |
| `company/strategy.md` | 戦略・四半期目標 | 中頻度 |
| `company/cto-rules.md` | CTO会議ルール | CEO会議で更新 |
| `company/ceo-rules.md` | CEO会議ルール | CEO会議で更新 |
| `company/focus.md` | 現在のフォーカス | CEO会議で更新 |
| `company/organization.md` | 組織図・役割 | 低頻度 |
| `company/history.md` | 沿革（追記型） | CEO会議で追記 |
| `meetings/cto/*.md` | CTO会議議事録 | 毎時00分 |
| `meetings/ceo/*.md` | CEO会議議事録 | 毎時30分 |
| `deliverables/*.md` | **実際の成果物** | 会議で生成 |
| `deliverables/*.sh` | **スクリプト等** | 会議で生成 |

## 📦 成果物の例

CTO会議/CEO会議で生成される成果物：

- ドキュメント: README.md, GUIDE.md, 設計書
- コード: スクリプト、設定ファイル
- 調査レポート: 技術調査結果、ベストプラクティスまとめ
- 戦略文書: 四半期計画、改善提案

## 🔄 自動コミットフロー

```
毎時00分: CTO会議実行
    ↓
議事録生成 → meetings/cto/YYYYMMDD_HHMM.md
成果物生成 → deliverables/*.md, *.sh 等
    ↓
git add company/ meetings/ deliverables/
    ↓
git commit -m "📄 CTO会議..."
    ↓
git push origin main
    ↓
このリポジトリに反映 ✅

毎時30分: CEO会議実行
    ↓
CTO会議評価 → company/*.md 更新
戦略文書生成 → deliverables/strategy-update.md
    ↓
git add company/ meetings/ deliverables/
    ↓
git commit -m "👔 CEO会議..."
    ↓
git push origin main
    ↓
このリポジトリに反映 ✅
```

## 📅 スケジュール

| 時刻 | 会議 | 内容 | 成果物 |
|------|------|------|--------|
| 00分 | CTO | アジャイルスプリント実行 | コード、ドキュメント等 |
| 30分 | CEO | 評価・ルール改善 | 戦略文書、ルール更新 |

## 🏗️ ディレクトリ構成

```
.
├── company/              # 会社情報（CEO会議が管理）
│   ├── mission.md        # ミッション
│   ├── strategy.md       # 戦略
│   ├── cto-rules.md      # CTO会議ルール
│   ├── ceo-rules.md      # CEO会議ルール
│   ├── focus.md          # 現在のフォーカス
│   ├── organization.md   # 組織図
│   └── history.md        # 沿革
├── meetings/             # 会議議事録
│   ├── cto/              # CTO会議議事録
│   │   └── YYYYMMDD_HHMM.md
│   └── ceo/              # CEO会議議事録
│       └── YYYYMMDD_HHMM.md
├── deliverables/         # 📦 実際の成果物
│   ├── *.md              # ドキュメント
│   ├── *.sh              # スクリプト
│   └── ...               # その他コード・設定
├── .gitignore            # .env, *.log のみ除外
└── README.md             # このファイル
```

## 🔒 除外ファイル

`.gitignore` で以下のみ除外：
- `.env` - 環境変数（シークレット）
- `*.log` - ログファイル

それ以外はすべてGitで追跡されます。
