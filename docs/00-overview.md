# InterSystems IRIS 2026.1 新機能概要

## 概要

InterSystems IRIS 2026.1はExtended Maintenance（EM）リリースです。CD（Continuous Delivery）版である2025.2および2025.3で導入された機能をすべて含み、加えて2026.1で新たに追加された機能があります。

本ドキュメントでは、2025.2/2025.3/2026.1で**新たに追加された機能のみ**を対象としています。2025.1で既に提供されていた機能（LIMIT/OFFSET、APPROX_COUNT_DISTINCT、HASHBYTES、LOAD SQL、ALTER TABLE CONVERT、基本HNSWインデックス、OpenTelemetryトレース等）は対象外です。

> **EM（Extended Maintenance）と CD（Continuous Delivery）の違い**: いずれも production release で、本番利用および InterSystems の正式サポートの対象です。違いは保守提供の形にあります。EMリリース（年1回、春）にはメンテナンスリリース（パッチ）が継続的に提供され、長期安定運用に適しています。CDリリース（2025.2, 2025.3 のように年に複数回）は新機能を先行して提供しますが、メンテナンスリリースは出ず、不具合修正は次のリリース（CDまたは次のEM）に含まれます。最新機能をいち早く使いたい場合はCD、長期運用の安定性を重視する場合はEMを選ぶのが一般的です。

## バージョン対応表

| カテゴリ | 2025.2 (CD) | 2025.3 (CD) | 2026.1 (EM) |
|---------|-------------|-------------|-------------|
| **セキュリティ** | IRISSECURITYデータベース | | セキュリティグローバル制限 |
| | OAuth2認証改善 | | |
| | ECC証明書 | | |
| | セキュリティウォレット | | |
| **SQL・データ管理** | | Foreign Table JOINプッシュダウン | テーブルパーティショニング |
| | | カラムテーブル集計改善 | 新クエリプラン形式 |
| | | SQL Statement統計改善 | |
| **AI・アナリティクス** | | | ACORN-1ベクトル高速化 |
| | | | カスタムPythonモデル |
| | | | BI POSIX時間対応 |
| **パフォーマンス・DB** | IRISTEMPスパースファイル廃止 | | $INCREMENT共有ブロック |
| | | | 40bit拡張DBサイズ |
| | | | 大規模KILL改善 |
| **監視・可観測性** | | プロセスメトリクス | |
| | | ECPメトリクス | |
| | | WDメトリクス | |
| | | 日次レポート | |
| **Interoperability・UI** | | FIFOメッセージグループ | DTL AI Explain |
| | | UIモダナイゼーション | BPLエディタVS Code統合 |
| | | | Mirthマイグレーション |
| **クラウド・連携** | パッケージマネージャ配布 | Azure Blobアーカイブ | |
| **非推奨・廃止** | | ICM削除 | プライベートWebサーバー廃止 |

---

## デモ環境

本リポジトリでは、Docker Composeで2つのIRISバージョン（2025.1と2026.1）を並行起動し、各機能のBefore/After比較デモを実行できます。環境のセットアップは [README.md](../README.md) を参照してください。

### アクセス先

| サービス | URL | 認証 |
|---------|-----|------|
| 2025.1 管理ポータル | <a href="http://localhost:11702/csp/sys/UtilHome.csp" target="_blank">localhost:11702</a> | _SYSTEM/SYS |
| 2026.1 管理ポータル | <a href="http://localhost:11706/csp/sys/UtilHome.csp" target="_blank">localhost:11706</a> | _SYSTEM/SYS |
| 2025.1 SQL画面 | <a href="http://localhost:11702/csp/sys/exp/%25CSP.UI.Portal.SQL.Home.zen?$NAMESPACE=USER" target="_blank">localhost:11702/SQL</a> | _SYSTEM/SYS |
| 2026.1 SQL画面 | <a href="http://localhost:11706/csp/sys/exp/%25CSP.UI.Portal.SQL.Home.zen?$NAMESPACE=USER" target="_blank">localhost:11706/SQL</a> | _SYSTEM/SYS |
| Grafana | <a href="http://localhost:11715" target="_blank">localhost:11715</a> | admin/admin |
| Prometheus | <a href="http://localhost:11712" target="_blank">localhost:11712</a> | なし |
| Keycloak (OAuth2 IdP) | <a href="http://localhost:11718" target="_blank">localhost:11718</a> | admin/admin |

### コマンドの実行方法

```bash
# スクリプトファイル経由（推奨）
echo 'zn "%SYS" write ##class(Config.Databases).Exists("IRISSECURITY") halt' > /tmp/run.script
docker cp /tmp/run.script iris-2026:/tmp/run.script
docker exec -i iris-2026 iris session IRIS < /tmp/run.script
```

> **注意:** `docker exec ... '...'` 形式では長いコマンドや `{}` ブロック構文を利用できません。スクリプトファイル経由での実行を推奨します。

### Interoperabilityプロダクションの起動

UI比較デモのため、両バージョンでプロダクションを起動します。
```bash
echo 'zn "USER" do ##class(Demo.Interoperability.SampleProduction).Setup() do ##class(Ens.Director).StartProduction("Demo.Interoperability.SampleProduction") halt' > /tmp/start-prod.script
docker cp /tmp/start-prod.script iris-2025:/tmp/start-prod.script
docker cp /tmp/start-prod.script iris-2026:/tmp/start-prod.script
docker exec -i iris-2025 iris session IRIS < /tmp/start-prod.script
docker exec -i iris-2026 iris session IRIS < /tmp/start-prod.script
```

### Grafanaダッシュボード

| ダッシュボード | 内容 |
|-------------|------|
| IRIS 2025.1 メトリクス（ベースライン） | システム全体の集計値のみ（100種） |
| IRIS 2026.1 メトリクス | 🔶NEW🔶 プロセス別/WD/リソースSeize（+17種） |
| IRIS 2025.1 Metrics - Baseline (EN) | 英語版 |
| IRIS 2026.1 Metrics (EN) | 英語版 |

---

## 機能別ドキュメント

各機能の詳細（実行コマンド、出力結果、比較、考察）はそれぞれのドキュメントに記載しています。

### 2026.1 固有の新機能

| # | 機能 | ドキュメント | 確認方法 |
|---|------|-------------|---------|
| 1 | 拡張データベースサイズ（40bit） | [拡張データベースサイズ](06-performance.md#拡張データベースサイズ20261) | デモクラス |
| 2 | IntegratedMLカスタムモデル | [カスタムPythonモデル](04-integratedml.md) | SQL（管理ポータル） |
| 3 | ベクトルサーチ ACORN-1 | [ACORN-1アルゴリズム](03-vector-search.md#acorn-1アルゴリズム20261) | デモクラス |
| 4 | テーブルパーティショニング | [PARTITION BY RANGE](02-table-partitioning.md#partition-by-range-構文) | SQL（管理ポータル） |
| 5 | 新クエリプラン形式 | [新クエリプラン形式](01-sql-enhancements.md#新クエリプラン形式20261) | `$SYSTEM.SQL.Explain()` / 管理ポータル |
| 6 | $INCREMENT共有ブロック | [$INCREMENT](06-performance.md#increment共有ブロック所有権20261) | デモクラス |
| 7 | UIモダナイゼーション | [UI刷新](08-interoperability.md#uiモダナイゼーション2025320261) | 管理ポータル 2025.1 vs 2026.1 |

### 2025.3 CDリリースの機能

| # | 機能 | ドキュメント | 確認方法 |
|---|------|-------------|---------|
| 8 | FIFOメッセージグループ | [FIFO](08-interoperability.md#fifoメッセージグループ2025320261) | 設定ベース |
| 9 | Foreign Table JOINプッシュダウン | [Foreign Table](01-sql-enhancements.md#foreign-table-joinプッシュダウン20253) | デモクラス（PostgreSQL連携） |
| 10 | メトリクス強化 | [プロセスメトリクス](07-observability.md#プロセスメトリクス追加20253) | Grafana / Prometheus |
| 11 | ProcessQuery新プロパティ | [ProcessQuery](07-observability.md#sysprocessquery新プロパティ20253) | SQLクエリ |

### 2025.2 CDリリースの機能

| # | 機能 | ドキュメント | 確認方法 |
|---|------|-------------|---------|
| 12 | IRISSECURITYデータベース | [IRISSECURITY](05-security.md#irissecurityデータベース20252) | デモクラス（2025.1 vs 2026.1） |
| 13 | OAuth2認証改善 | [OAuth2](05-security.md#oauth2認証改善20252) | デモクラス |
| 14 | ECC証明書サポート | [ECC証明書](05-security.md#ecc証明書サポート20252) | 管理ポータル |
| 15 | セキュリティウォレット | [ウォレット](05-security.md#セキュリティウォレット20252) | スクリプト |
| 16 | パッケージマネージャ配布 | [パッケージマネージャ](11-third-party-integration.md#2-クライアントライブラリのパッケージマネージャ配布20252) | ドキュメント参照 |

### その他

| ドキュメント | 内容 |
|-------------|------|
| [非推奨・廃止機能](09-deprecated.md) | 廃止・非推奨機能一覧と移行先 |
| [アップグレード注意点](10-upgrade-notes.md) | バージョンアップ時の確認事項 |
| [サードパーティ連携](11-third-party-integration.md) | JDBC OAuth2、VS Code統合、Mirth等 |

---

## デモクラス一覧

| クラス | 導入ver | 内容 |
|--------|---------|------|
| `Demo.SQL.ForeignTableJoin` | 2025.3 | Foreign Table JOINプッシュダウン（PostgreSQL連携） |
| `Demo.SQL.ColumnarBenchmark` | 2025.3 | カラムテーブル低カーディナリティ集計改善のベンチマーク |
| `Demo.SQL.StatementIndex` | 2025.3 | SQL Statement Index実行時統計改善のベンチマーク |
| `Demo.Partitioning.TablePartition` | 2026.1 | テーブルパーティショニング |
| `Demo.Vector.VectorSearch` | 2026.1 | ベクトルサーチ ACORN-1高速化 |
| `Demo.IntegratedML.CustomModel` | 2026.1 | IntegratedML基本ワークフロー（CREATE/TRAIN/PREDICT） |
| `Demo.IntegratedML.DemandForecast` | 2026.1 | IntegratedMLカスタムモデル（需要予測: AutoML vs カスタム） |
| `Demo.IntegratedML.ChurnDemo` | 2026.1 | IntegratedMLカスタムモデル（顧客離反予測の精度比較） |
| *(直接コマンド)* | 2025.2 | IRISSECURITYデータベース確認（`##class(Config.Databases).Exists("IRISSECURITY")`） |
| `opt/iris/wallet-demo.os` | 2025.2 | セキュリティウォレット（%Wallet.Collection / %Wallet.KeyValue） |
| `Demo.Security.OAuth2` | 2025.2 | OAuth2認証改善 |
| `Demo.Performance.IncrementShared` | 2026.1 | $INCREMENT共有ブロック所有権 |
| *(ドキュメント参照)* | 2026.1 | 拡張DBサイズ（最大8PB、フルライセンス版のみ） |
| *(SQLクエリ)* | 2025.3 | ProcessQuery新プロパティ（ParentPid / StartTimeUTC） |
| `Demo.Setup.SampleData` | - | サンプルデータ生成 |
| `Demo.Interoperability.SampleProduction` | - | UIモダナイゼーション確認用 |
| `Demo.Interoperability.SampleBPL` | - | BPLエディタ確認用 |
| `Demo.Interoperability.SampleDTL` | - | DTLエディタ確認用 |
| `Demo.Interoperability.UIGuide` | - | UI総合ガイド |
