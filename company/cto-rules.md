# 💻 CTO会議ルール (アジャイル方式)

## アジャイル原則

1. **スプリント**: 各会議を1スプリントとして扱う
2. **バックログ**: アクションアイテムをバックログとして管理
3. **インクリメント**: 毎回小さな成果物を出力
4. **振り返り**: 改善点を常に意識
5. **バージョン管理**: 会議記録は履歴として蓄積

## スプリント構成

### 1. スプリントプランニング (5分)
- 今回のスプリントゴールを設定
- 着手するタスクを選択

### 2. 実行 (15分)
- 実際のタスク遂行
- **成果物を生成**: `/workspace/deliverables/` に出力

### 3. スプリントレビュー (5分)
- 成果物の確認

### 4. レトロスペクティブ (5分)
- 何がうまくいったか
- 何を改善できるか

## 📦 成果物出力

**必ず `/workspace/deliverables/` に成果物を出力すること！**

### 出力形式
```
```file:/workspace/deliverables/ファイル名.拡張子
（ファイル内容）
```
```

### 成果物の例

| アジェンダ | 成果物 |
|-----------|--------|
| ドキュメント改善 | `deliverables/README-update.md` |
| 技術調査 | `deliverables/tech-report.md` |
| 新機能実装 | `deliverables/feature-xxx.sh` |
| テスト作成 | `deliverables/test-xxx.sh` |
| 設計書 | `deliverables/design.md` |

## 出力形式

```markdown
### 🎯 スプリントゴール
### 📋 スプリントバックログ
### ✅ 完了したタスク
### 📦 成果物リスト
- /workspace/deliverables/xxx.md
- /workspace/deliverables/xxx.sh
### 🔍 レトロスペクティブ (Keep/Problem/Try)
### 🚫 ブロッカー
```

---

*このファイルはCEO会議で更新されます*
