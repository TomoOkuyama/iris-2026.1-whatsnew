# サードパーティツール連携の強化

## 概要
IRISは単独で完結するシステムではなく、周囲のツールやクラウドサービスとの連携によって価値が広がります。2025.2/2025.3/2026.1では、外部アプリケーション、BIツール、クラウドストレージ、開発エディタとの接続性が大きく改善されました。本ドキュメントでは、その連携機能がどのように進化したかを解説します。

## 変更点の詳細

### 1. JDBC/ODBC OAuth2アクセストークン認証（2025.2）
アプリケーション側にパスワードを保持する方式に代わり、トークンによる認証が利用できるようになりました。JDBC/ODBCの接続もOAuth2に対応し、より安全な認証フローを採用できます。

- JDBC: `IRISDataSource.setAccessToken()` でOAuth2トークン認証
- ODBC: `ACCESSTOKEN` パラメータ
- 外部アプリケーションからの接続でパスワードレス認証が可能に

### 2. クライアントライブラリのパッケージマネージャ配布（2025.2）
ドライバを手動でダウンロードして配置する手間がなくなります。使い慣れたパッケージマネージャから1行の宣言で導入できるようになり、開発環境のセットアップが大幅に簡略化されました。

- Maven (Java), NuGet (.NET), NPM (Node.js), PyPI (Python)
- CI/CDパイプラインでの依存関係管理が簡素化
- GitHub iris-driver-distribution からも取得可能

### 3. Foreign Table JOINプッシュダウン（2025.3）
外部DBのデータをIRISに取り込んでから結合するのではなく、結合処理そのものを外部DB側で実行できるようになりました。ネットワークを経由するデータ量が削減され、外部DB側のオプティマイザも有効に活用できます。

- 同一外部サーバーの複数Foreign TableのJOINを外部DBに一括送信
- ネットワークI/O削減、外部DBのオプティマイザ活用
- PostgreSQL, MySQL, SQL Server等との連携で効果大

### 4. BI POSIX時間対応（2026.1）
日付や時刻の扱いは、BI連携でしばしば問題になるポイントです。IRIS BIのキューブにおける日付/時刻データの格納方法が見直され、外部BIツールに渡した際の日付のずれや解釈の不一致が発生しにくくなりました。

- IRIS BIのキューブで日付/時刻データの格納方法改善
- ファクトテーブル・ディメンションテーブルのSQLプロジェクション改善
- Tableau, Power BI等のサードパーティBIツールとの日付連携精度が向上

### 5. Azure Blob Storageジャーナルアーカイブ（2025.3）
ジャーナルのアーカイブ先として、Amazon S3に加えてAzure Blob Storageが選択できるようになりました。複数クラウドを使い分けたい場合や、特定のクラウドへの依存を避けたい場合の運用方針に対応できます。

- Amazon S3に加え、Azure Blob Storageへのジャーナルアーカイブ対応
- Management Portalまたは^ARCHIVEユーティリティで設定
- マルチクラウド環境でのデータ保持コスト最適化

### 6. DTL AI Explain - OpenAI連携（2026.1）
複雑なDTLの変換内容を読み解く作業を、AIによる解説で補助できるようになりました。DTLエディタからOpenAI GPTを呼び出し、処理内容の説明文を自動生成できます。

- DTLエディタ内でOpenAI GPTを使用した自動説明文生成
- DTLの処理内容をAIが自動解析して記述
- OpenAI APIキーをセキュリティウォレットに登録が必要

### 7. Mirthマイグレーションツール（2026.1）
Mirth Connectで構築された既存の統合をIRISへ移行するための専用ツールが提供されました。ゼロから作り直す必要がなく、既存の資産を引き継いだまま近代化を進められます。

- Mirth Connectからの移行を支援するツール
- レガシー統合エンジンの近代化を加速

### 8. VS Code統合の強化（2025.2/2026.1）
VS Code上でIRIS開発を完結できる範囲が広がりました。エディタからBPLを編集でき、サーバーやSQLテーブルへのアクセスも可能になっています。

- BPLエディタのVS Code組み込み（2026.1）
- InterSystems Server ManagerでMPページ・SQLテーブルに直接アクセス（2026.1）
- Language Server改善: Pythonメソッドフォールディング等（2026.1）
- DTL/ルールエディタUI改善（2025.2）

## 活用シーン

- **マイクロサービス連携**: 外部サービスからの接続をJDBC OAuth2トークンで受け付け、パスワードを保持しないセキュアな構成を実現できる
- **CI/CDパイプライン**: Maven/NuGet/NPM/PyPIからドライバを直接取得し、ビルド工程に組み込んで自動化できる
- **外部DB連携**: Foreign Table JOINプッシュダウンにより、PostgreSQL/MySQL等との結合クエリを外部DB側で処理して高速化できる
- **BIダッシュボード**: POSIX時間対応により、Tableau/Power BIでの日時フィルタが意図したとおりに動作する
- **マルチクラウド運用**: Azure Blob + S3でジャーナルアーカイブを分散配置し、クラウドの使い分けが可能になる
- **開発効率**: VS Code内でBPL/DTL/ルール編集が完結し、AIによる説明支援で内容の把握も容易になる

## 関連クラス
- `Demo.SQL.ForeignTableJoin` — Foreign Table JOINプッシュダウンのデモ
- `Demo.Security.OAuth2` — OAuth2認証改善のデモ

## リファレンス

- [New in InterSystems IRIS 2026.1](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GCRN)
- [New in InterSystems IRIS 2025.3](https://community.intersystems.com/post/intersystems-announces-general-availability-intersystems-iris-intersystems-iris-health-and)
- [New in InterSystems IRIS 2025.2](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GCRN_new20252)
- [IRIS Driver Packages（Maven/NuGet/NPM/PyPI）](https://intersystems-community.github.io/iris-driver-distribution/)
- [JDBC Driver Support（公式ドキュメント）](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=BTPI_jdbc)
- [Configuring the DTL Explainer](https://docs.intersystems.com/iris20261/csp/docbook/Doc.View.cls?KEY=EDTL_configexplainer)
