# Evolutionary Meeting Bot

定例会議が自己改善して進化するシステム。

## 構成

```
company/
├── role.md        # ロール定義
├── agenda.md      # 実行タスク
├── mission.md     # ミッション
├── strategy.md    # 戦略
├── focus.md       # 現在のフォーカス
├── history.md     # 履歴（追記）
└── organization.md

meetings/          # 議事録
deliverables/      # 成果物
```

## サイクル

```
毎時00分
   ↓
1. company/ を読んで状況把握
2. やることを決める
3. 実装（ファイル作成・編集）
4. 振り返り（必要なら company/ を更新）
5. history.md に成果追記
   ↓
プッシュ
   ↓
1時間後 繰り返し
```
