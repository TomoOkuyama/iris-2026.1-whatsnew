# InterSystems IRIS 2026.1 What's New

InterSystems IRIS **2026.1** の新機能を、実際に手元で動かして体験できるデモリポジトリです。
2026.1 は EM (Extended Maintenance) リリースであり、CD版 2025.2 / 2025.3 の機能も含みます。
Docker Composeで 2025.1（前回EM）と 2026.1 を同時に起動し、同じコードを両バージョンで走らせて「何がどう変わったか」を自分の目で確かめられます。

**新機能の一覧・デモ手順・各機能の詳細は [docs/00-overview.md](docs/00-overview.md) を参照してください。**

## セットアップ

### 前提条件

- Docker / Docker Compose がインストール済みであること

### 起動

```bash
docker compose build && docker compose up -d
```

初回起動後の設定:
```bash
# Keycloak SSL無効化（初回のみ、起動後約1分待ってから実行）
docker exec demo-keycloak /opt/keycloak/data/import/disable-ssl.sh

# ECC/RSA証明書の生成（ECC証明書デモ用）
docker exec iris-2026 /opt/iris/generate-certs.sh

# IntegratedML AutoMLセットアップ
docker exec iris-2026 /opt/iris/setup-automl.sh

# SystemPerformanceレポート生成（5分かかります）
docker exec iris-2026 /opt/iris/generate-sysperf.sh
```

> **ポート番号について:** デフォルトでは11701〜11720を使用します。既存のサービスとポートが競合する場合は、`docker-compose.yml` 内のポート番号を環境に合わせて変更してください。

### 停止

```bash
docker compose down
```

## コンテナ一覧

| コンテナ | ポート | 用途 |
|---------|-------|------|
| iris-2025 | 11701(SuperServer), 11702(Web) | IRIS 2025.1 ベースライン |
| iris-2026 | 11705(SuperServer), 11706(Web) | IRIS 2026.1 新機能 |
| demo-postgres | 11709 | Foreign Table JOINプッシュダウン用 |
| demo-prometheus | 11712 | メトリクス収集 |
| demo-grafana | 11715 | メトリクス可視化 |
| demo-keycloak | 11718 | OAuth2 IdP（Keycloak） |

## ディレクトリ構成

```
├── docker-compose.yml        # 全コンテナ定義
├── iris-2025/                # IRIS 2025.1 Dockerfile・設定
├── iris-2026/                # IRIS 2026.1 Dockerfile・設定
├── postgres/                 # PostgreSQL初期化SQL
├── prometheus/               # Prometheus設定
├── grafana/                  # Grafanaダッシュボード・データソース
├── src/Demo/                 # デモ用ObjectScriptクラス
└── docs/                     # 機能紹介・比較ドキュメント
    ├── 00-overview.md        # ← 新機能一覧・デモ手順・ナビゲーション
    ├── 01〜11-*.md           # 各機能の詳細
    └── ...
```

## iris-community イメージの制限事項

本リポジトリは `intersystems/iris-community` イメージを使用しています。
Community Editionの[公式制限](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=ACLOUD)は以下の4機能のみです:

- Mirroring
- ECP（Enterprise Cache Protocol）/ 分散キャッシュ
- Sharding
- InterSystems API Manager

上記以外の新機能は、本リポジトリのデモでそのまま動作確認できます。
