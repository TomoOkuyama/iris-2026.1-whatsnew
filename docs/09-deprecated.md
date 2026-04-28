# 非推奨・廃止機能

## 概要

2026.1へのアップグレードで影響を受ける可能性のある非推奨（Deprecated）・廃止（Discontinued）機能をまとめます。2025.1〜2026.1で新たに加わった変更に加え、以前から続く非推奨機能も含みます。いずれも移行先が示されているので、アップグレード前にこの一覧で該当箇所を確認し、順次移行を進めてください。

> **参考:** [Deprecated and Discontinued Features（公式ドキュメント）](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GCRN_discontinued_features)

## 非推奨・廃止機能一覧

| 機能 | ステータス | バージョン | 移行先・代替手段 |
|------|----------|-----------|----------------|
| プライベートWebサーバー | **廃止** | 2023.2〜段階的廃止、2026.1 EMで完全削除 | Apache HTTP Server、Nginx、IIS等の外部Webサーバー |
| Studio | **削除** | 2024.2でWindowsキットから削除 | VS Code + ObjectScript Extension |
| ICM（InterSystems Cloud Manager） | **削除** | 2025.3 | Kubernetes + IKO、Terraform、Ansible |
| Mac Intel（x86_64） | **終了** | 2026.1 | Mac ARM（Apple Silicon）版を使用 |
| MultiValue | **非推奨** | 2025.1 | 標準ObjectScript/SQLへの移行を推奨 |
| PKI（Public Key Infrastructure） | **非推奨** | 2024.1（将来バージョンで削除予定） | 外部のPKI/証明書管理ソリューション |
| iKnow（IRIS NLP） | **非推奨** | 2023.3 | 外部のNLP/テキスト分析サービス、LLM API |
| Zen | **非推奨** | 継続 | Angular/React等 + REST API |
| CSP（Cache Server Pages） | **非推奨** | 継続 | REST API + モダンフロントエンド |
| DeepSee | **非推奨** | 継続 | Adaptive Analytics、外部BIツール |
| Ensemble | **非推奨** | 継続 | IRIS Interoperabilityへの移行 |

## 各機能の詳細と移行ガイド

### プライベートWebサーバー（廃止 - 2026.1 EM）

IRISに内蔵されていた簡易Webサーバー（Apache httpdのミニマルビルド）が段階的に廃止されました。2023.2以降の新規インストールには含まれず、2026.1 EMへのアップグレードでは既存インスタンスからも削除されます。もともと本番運用では外部Webサーバーを別途用意するのが一般的なため、その構成への切り替え作業となります。

**影響**:
- 管理ポータルへのアクセスに外部Webサーバーが必須になる
- CSP/RESTアプリケーションの配信構成を見直す必要がある

**移行方法**:
- Apache HTTP Server + Web Gatewayの構成に移行する
- コンテナ環境ではNginxリバースプロキシ構成が一般的
- Docker Composeなら別コンテナとしてWebサーバーを構成する

> **参考:** [Access the Management Portal Using Your Web Server（公式ドキュメント）](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GCGI_private_web)

---

### Studio（削除 - 2024.2）

統合開発環境のStudioは2023.2で非推奨となり、2024.2のWindowsキットから削除されました。Studioを同梱する最後のバージョンは2024.1です。後継となるVS Code環境では、デバッグやソース管理など開発に必要な機能が一通り利用できます。

**移行方法**:
- VS Code + InterSystems ObjectScript Extension Packを導入する
- Server Managerで接続を設定する
- デバッグ、ソース管理、IntelliSense等の機能はVS Codeで利用できる

> **注:** Studio 2024.1は前方互換性があり、2026.1以降のIRISにも接続できます。必要な場合は[WRCのコンポーネントダウンロード](https://wrc.intersystems.com)から入手可能です。

---

### ICM（InterSystems Cloud Manager）（削除 - 2025.3）

クラウド環境へのデプロイを担っていたICMが2025.3で削除され、2026.1以降もサポートされません。代替として、汎用的なツールチェーンを組み合わせる構成に移行します。

**移行方法**:
- Kubernetes + IKO（InterSystems Kubernetes Operator）: Kubernetes上でのIRIS管理
- Terraform: インフラのプロビジョニング
- Ansible: 構成管理とアプリケーションデプロイ

---

### Mac Intel（x86_64）（終了 - 2026.1）

Intel CPUベースのMacでのIRIS実行はサポートが終了しました。開発機はApple Silicon機への切り替え、サーバーは従来どおりLinux/Windowsでの運用が対応策となります。

**移行方法**:
- Apple Silicon（M1/M2/M3/M4）搭載のMacに移行する
- またはLinux/Windows環境を使用する

---

### MultiValue（非推奨 - 2025.1）

MultiValue（旧Pick/Universe互換）機能が非推奨となりました。既存顧客向けのサポートは継続されるため即時の停止は不要ですが、新規開発での利用は避けてください。移行は段階的に進めることができます。

**移行方法**:
- MultiValue構造を標準的なオブジェクト/SQLモデルに変換する
- MVBasicプログラムをObjectScriptへ移行する
- 段階的な移行を推奨

> **参考:** [Deprecation of MultiValue in InterSystems IRIS 2025.1](https://community.intersystems.com/post/deprecation-multivalue-intersystems-iris-20251)

---

### PKI（非推奨 - 2024.1）

IRIS組み込みのPKI（Public Key Infrastructure）パッケージが2024.1で非推奨となりました。`PKI.CAClient`、`PKI.CAServer`、`PKI.Certificate`、`PKI.CSR`クラスは2026.1時点でも残っていますが、将来バージョンで削除される予定です。今後は証明書管理を外部のソリューションに委ねる方針となります。

**移行方法**:
- Let's Encrypt（ACME）: 自動証明書管理
- HashiCorp Vault: 企業向けシークレット/証明書管理
- AWS Certificate Manager、Azure Key Vault等のクラウドサービス

> **注意:** 削除が予告されているため、新規開発での利用は避け、既存システムも早めに移行計画を立ててください。

---

### iKnow / IRIS NLP（非推奨 - 2023.3）

テキスト分析エンジンのiKnow（IRIS NLP）が非推奨となりました。InterSystemsによる積極的な開発は行われておらず、新規開発での利用は避けてください。NLP分野は外部サービスやLLMの選択肢が豊富になっており、移行先の候補も多くあります。

**移行方法**:
- クラウドNLPサービス（AWS Comprehend、Google NLP等）
- オープンソースNLPライブラリ（spaCy、NLTK等）とEmbedded Pythonの連携
- LLM API（OpenAI等）との連携

> **参考:** [Advisory: Deprecation of InterSystems IRIS NLP](https://www.intersystems.com/support/product-alerts-advisories/advisory-deprecation-of-intersystems-iris-nlp-formerly-known-as-iknow/)

---

### Zen / CSP / DeepSee / Ensemble（非推奨 - 継続）

これらは以前のバージョンから引き続き非推奨となっている機能です。当面は動作しますが、新規開発では下記の移行先を選んでください。

| 機能 | 推奨移行先 |
|------|-----------|
| **Zen** | Angular/React/Vue.js + REST API |
| **CSP** | REST API + モダンフロントエンド |
| **DeepSee** | Adaptive Analytics、Tableau等の外部BIツール |
| **Ensemble** | IRIS Interoperabilityへの移行 |

## 関連ドキュメント・リファレンス

**関連ドキュメント:**
- [アップグレード注意点](10-upgrade-notes.md) — バージョンアップ時の具体的な対応手順
- [セキュリティ変更](05-security.md) — セキュリティグローバル直接アクセス制限の詳細

**公式リファレンス:**
- [Deprecated and Discontinued Features（公式）](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GCRN_discontinued_features) — 非推奨・廃止機能の公式一覧
- [Discontinued Platforms and Technologies](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=ISP_discontinued) — サポート終了プラットフォーム
- [Discontinue Apache web server installations (FAQ)](https://community.intersystems.com/post/discontinue-apache-web-server-installations-faq) — プライベートWebサーバー廃止FAQ
- [Deprecation of MultiValue in InterSystems IRIS 2025.1](https://community.intersystems.com/post/deprecation-multivalue-intersystems-iris-20251)
- [Advisory: Deprecation of InterSystems IRIS NLP (iKnow)](https://www.intersystems.com/support/product-alerts-advisories/advisory-deprecation-of-intersystems-iris-nlp-formerly-known-as-iknow/)
- [Windows upgrade removes Studio in 2024.2](https://community.intersystems.com/post/windows-upgrade-removes-studio-20242)
