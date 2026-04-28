# スクリーンショット TODO

各ドキュメントで「あると伝わりやすい」スクリーンショットの一覧。

---

## 必須（テキストだけでは説明しにくい）

### 01-sql-enhancements.md — クエリプラン新旧比較（ターミナル出力）
- **場所:** IRISターミナル（2025.1と2026.1の両コンテナ）
- **撮影内容:** `write $SYSTEM.SQL.Explain("SELECT ...", 1)` の出力。旧形式（インデントなし・1行）vs 新形式（インデント付き・モジュール構造）を並べる
- **ファイル名:** `images/sql-explain-2025.png` / `images/sql-explain-2026.png`
- **参照箇所:** `### クエリプラン出力改善（2026.1）` — ドキュメントに「ターミナルで確認を」と注記あるが実例なし

### 02-table-partitioning.md — Community版でのエラー画面
- **場所:** 管理ポータル → SQLエディタ（2026.1 Communityコンテナ）
- **撮影内容:** `CREATE TABLE ... PARTITION BY RANGE` を実行してエラーが返る状態
- **ファイル名:** `images/partitioning-community-error.png`
- **参照箇所:** 概要の「Community Editionでは利用不可」 — 注記のみで根拠がない

### 02-table-partitioning.md — プルーニングのクエリプラン確認
- **場所:** IRISターミナル（2026.1 フルライセンス版）
- **撮影内容:** `$SYSTEM.SQL.Explain()` の出力に `"This plan utilizes partition pruning."` が含まれている状態
- **ファイル名:** `images/partitioning-query-plan.png`
- **参照箇所:** `### パーティションプルーニング` → 確認方法

---

## あると説得力が増す

### 04-integratedml.md — 訓練完了後のモデル一覧
- **場所:** 管理ポータル → Analytics → IntegratedML
- **撮影内容:** AutoMLとカスタムモデル（DemandCustom）が両方登録されている状態
- **ファイル名:** `images/integratedml-model-list.png`
- **参照箇所:** `### 需要予測デモ` セクション

### 04-integratedml.md — PREDICT()の実行結果
- **場所:** 管理ポータル → システムエクスプローラー → SQL
- **撮影内容:** `SELECT PREDICT(DemandCustom) ...` の結果が表示されている状態
- **ファイル名:** `images/integratedml-predict-result.png`
- **参照箇所:** `### 需要予測デモ` → 実行結果

### 04-integratedml.md — トレーニングログ（カスタムモデル使用確認）
- **場所:** 管理ポータル → SQLエディタ
- **撮影内容:** `SELECT LOG FROM INFORMATION_SCHEMA.ML_TRAINING_RUNS` の結果。`isc_models_disabled is set to True` / `Created an instance of IRISModel from DemandPredictor` の行が見えている状態
- **ファイル名:** `images/integratedml-training-log.png`
- **参照箇所:** `### 需要予測デモ` → 訓練ログで「カスタムモデルが使われた」ことを確認

### 02-table-partitioning.md — パーティション構造の確認画面
- **場所:** 管理ポータル → システムエクスプローラー → SQL
- **撮影内容:** `SELECT * FROM INFORMATION_SCHEMA.TABLE_PARTITIONS WHERE TABLE_NAME = 'SalesLog'` の結果
- **ファイル名:** `images/table-partitioning-info.png`
- **参照箇所:** `### PARTITION BY RANGE構文` または `### パーティションプルーニング`

### 08-interoperability.md — BPLエディタ新旧UI比較
- **場所:** 管理ポータル → Interoperability > 構成 > BPLプロセス（2025.1 vs 2026.1）
- **撮影内容:** 旧UI（2025.1）と新UI（2026.1、「新しいUIを試す」クリック後）を並べて比較
- **ファイル名:** `images/bpl-editor-2025.png` / `images/bpl-editor-2026.png`
- **参照箇所:** `### UIモダナイゼーション → BPLエディタの改善（2026.1）`

### 08-interoperability.md — プロダクション構成UI新旧比較
- **場所:** 管理ポータル → Interoperability > 構成 > プロダクション（2025.1 vs 2026.1）
- **撮影内容:** `SampleProduction` を開いた状態で、旧UIと新UIの外観差（検索バー・PoolSize表示など）
- **ファイル名:** `images/production-config-2025.png` / `images/production-config-2026.png`
- **参照箇所:** `### UIモダナイゼーション → プロダクション構成UIの改善`

### 08-interoperability.md — Mirthマイグレーションツール画面
- **場所:** 管理ポータル → 管理 → HL7生産性ツール → HL7マイグレーションツール
- **撮影内容:** ツールのメイン画面（入力フォームが見えている状態）
- **ファイル名:** `images/mirth-migration-tool.png`
- **参照箇所:** `### Mirthマイグレーションツール（2026.1）` → アクセス方法

---

## 既存（撮影済み・ドキュメントに組み込み済み）

| ファイル | 内容 | ドキュメント |
|---------|------|-----------|
| `images/otel-monitor-settings.png` | OTelモニタ設定画面 | 07-observability.md |
| `images/otel-service-monitor.png` | %Service_Monitor編集画面 | 07-observability.md |
| `images/grafana-2026.png` | GrafanaダッシュボードIRIS 2026.1 | 07-observability.md |
| `images/process-query-2025.png` | %SYS.ProcessQuery（2025.1） | 07-observability.md |
| `images/process-query-2026.png` | %SYS.ProcessQuery（2026.1） | 07-observability.md |
| `images/sysperf-report.png` | SystemPerformanceレポート | 07-observability.md |
| `images/extended-db-size-2025.png` | 拡張DBサイズ設定（2025.1） | 06-performance.md |
| `images/extended-db-size-2026.png` | 拡張DBサイズ設定（2026.1） | 06-performance.md |
| `images/extended-db-size-2026-edit.png` | 拡張DBサイズ編集画面 | 06-performance.md |
| `images/keycloak-events.png` | Keycloak Eventsログ | 05-security.md |
| `images/ssl-tls-2025-no-ecdsa.png` | TLS設定 ECDSA非対応（2025.1） | 05-security.md |
| `images/ssl-tls-ecc-config.png` | ECC証明書設定画面 | 05-security.md |
| `images/dtl-ai-2026.png` | DTL AI Explain動作画面 | 08-interoperability.md |
