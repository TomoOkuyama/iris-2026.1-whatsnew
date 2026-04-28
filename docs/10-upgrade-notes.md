# アップグレード時の注意点

## 概要

IRIS 2025.1から2026.1へアップグレードする際に確認すべき変更点をまとめます。破壊的変更や後方互換性のない変更は、アップグレード前に対応を済ませておく必要があります。事前に把握して順に対応すれば、移行は円滑に進みます。

> **参考:** [Upgrade Checklist（公式）](https://docs.intersystems.com/irislatest/csp/docbook/changes/index.html) / [IRISSECURITY Upgrade Impact](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=ASECURITYDB)

## 注意点一覧

| 項目 | 重要度 | 影響範囲 | 詳細 |
|------|-------|---------|------|
| IRISSECURITYへの移行 | **高** | セキュリティ関連コード全体 | グローバル直接アクセスが制限 |
| プライベートWebサーバー廃止 | **高** | Webアプリケーション全体 | 外部Webサーバーの導入が必須 |
| BIキューブ再コンパイル | **高** | BIダッシュボード全体 | 時間次元の再ビルドが必要 |
| PKIパッケージ非推奨 | **中** | PKI/証明書管理 | 2024.1で非推奨、将来バージョンで削除予定 |
| %CSP.REST DispatchRequest final化 | **高** | カスタムRESTディスパッチ | オーバーライド不可に |
| External Language Gateway設定変更 | **中** | Java/.NET Gateway連携 | Server/Port → Gateway Name必須 |
| $INCREMENTジャーナルレコード変更 | **中** | ジャーナル解析ツール | 新拡張タイプへの対応（2025.1〜） |
| 暗号化関数廃止 | **中** | 暗号化処理 | 旧暗号関数が削除 |
| IRISTEMP初期サイズ変更 | **低** | ディスク容量計画 | スパースファイル廃止、初期サイズ240MB→20MB |

## 各項目の詳細

### 1. IRISSECURITYへの移行（セキュリティグローバル直接アクセス不可）

**変更内容**: セキュリティデータが独立した`IRISSECURITY`データベースに分離され、セキュリティグローバルへの直接アクセスはできなくなりました。データへのアクセスはAPI経由に統一されます。

**影響を受けるコード**:
```objectscript
// NG: 2026.1で動作しない可能性あり
set data = ^SYS("Security","Users","_SYSTEM")
```

**対応方法**:
```objectscript
// OK: API経由のアクセス
set sc = ##class(Security.Users).Get("_SYSTEM", .props)
```

**確認手順**:
1. ソースコード内で`^SYS("Security"` を検索
2. 直接アクセスしている箇所をSecurity.*クラスのAPIに置き換え
3. 詳細は [セキュリティ変更](05-security.md#破壊的変更-セキュリティグローバルアクセス制限20261) を参照

---

### 2. プライベートWebサーバー廃止

**変更内容**: IRISに内蔵されていた簡易Webサーバー（Apache httpdのミニマルビルド）が2026.1 EMで完全に削除されます。アップグレード時に既存インスタンスからも自動的に削除されるため、外部Webサーバーへの切り替えを事前に準備しておく必要があります。

**対応方法**:
1. 外部Webサーバー（Apache, Nginx, IIS）を導入
2. Web Gateway（旧CSP Gateway）をインストール・設定
3. ポート番号やURLパスの変更をアプリケーション側に反映

---

### 3. BIキューブ再コンパイル（時間次元の再ビルド必須）

**変更内容**: BI（Business Intelligence）が時間次元の値に`%PosixTime`データ型を使うようになりました。キューブ定義クラスを再コンパイルすると、ファクトテーブル内の時間次元プロパティのデータ型が更新され、その過程で**時間次元が一時的に無効化**されます。再ビルドすれば元どおり利用できます。

**対応手順**:
1. キューブ定義クラスを再コンパイル
2. 時間次元が自動的に無効化される（MDXクエリで使用不可に）
3. **時間次元を再有効化する**には、以下のいずれかを実行:
   - **管理ポータル**: **Analytics → アーキテクト → [キューブ名]** を開き「ビルド」を実行
   - **ObjectScript（完全ビルド）**: `do ##class(%DeepSee.Utils).%BuildCube("キューブ名",0,1)`
4. ダッシュボードの動作確認

> **重要:** 再コンパイルだけでは不十分です。時間次元の**再ビルド**が必須です。

---

### 4. PKIパッケージ非推奨

**変更内容**: IRIS組み込みのPKI（Public Key Infrastructure）パッケージは2024.1で非推奨となりました。`PKI.CAClient`、`PKI.CAServer`、`PKI.Certificate`、`PKI.CSR`クラスは2026.1時点でも引き続き利用できますが、将来のバージョンで削除される予定です。早めに移行先を検討しておきましょう。

**対応方法**:
- PKI機能の使用状況を確認し、移行計画を立てる
- 移行先としてはLet's Encrypt（ACME）、HashiCorp Vault、AWS Certificate Managerなどの外部サービスが候補

---

### 5. %CSP.REST DispatchRequest final化

**変更内容**: `%CSP.REST`クラスの`DispatchRequest()`メソッドが`final`宣言となり、サブクラスでオーバーライドできなくなりました。独自処理は専用のフックメソッドへ移す必要があります。

**影響を受けるコード**:
```objectscript
// NG: 2026.1でコンパイルエラー
Class MyApp.REST Extends %CSP.REST
{
  ClassMethod DispatchRequest(...) { ... }
}
```

**対応方法**:
- `DispatchRequest`をオーバーライドしているカスタムRESTクラスを修正
- `OnPreDispatch`や`OnPostDispatch`などのフックメソッドで代替

---

### 6. External Language Gateway設定変更

**変更内容**: Java Gateway、.NET GatewayでServer/Portプロパティが廃止され、**Gateway Name**による設定に統一されました。設定をGateway Name方式へ変更すれば対応完了です。

**影響を受けるコード**:
- `EnsLib.JavaGateway`のServer/Portプロパティを使用している箇所
- `EnsLib.DotNetGateway.Service`での運用管理
- `%DynamicObject`でServer/Portを指定している箇所

**対応方法**:
- 外部言語サーバー名（Gateway Name）を使用する設定に変更
- SAP Operationでは`pPort=""`、`pAddress=""`を使用

---

### 7. $INCREMENTジャーナルレコード変更（2025.1〜）

**変更内容**: `$INCREMENT`操作のジャーナルレコードに新しい拡張タイプが追加されました（2025.1で導入）。2024.x以前からアップグレードする場合に影響があり、主にジャーナル解析ツールが対象です。

- `SET ($I)`: $INCREMENT操作
- `SET ($I if greater)`: 条件付き$INCREMENT

**対応方法**:
- `SYS.Journal.Record`の`ExtType`/`ExtTypeName`プロパティを使って新しいレコードタイプに対応

---

### 8. 暗号化関数廃止

**変更内容**: 以下の旧暗号化関数が削除されました。使用している場合は新しいメソッドへ置き換える必要があります。
- `AESCRCEncode` / `AESCRCDecode`
- `RijndaelBase64Encode` / `RijndaelBase64Decode`

**対応方法**:
- `$SYSTEM.Encryption`クラスの最新メソッドに移行

---

### 9. その他の変更

| 項目 | 内容 |
|------|------|
| **IRISTEMP** | スパースファイル廃止（2025.2〜）。初期サイズが240MB→20MBに変更 |
| **$QSUBSCRIPT/$QLENGTH** | 予期しない文字検出時にエラーが発生するように |
| **Interoperability KeepInQueues** | デフォルト値が`true`に変更 |
| **ODBC** | BufferLength強制、バイナリデータ処理変更 |
| **Windows** | OSユーザー名にドメイン情報を含む形式に変更（username@domain） |
| **CPFマージ** | ファイル名にコンマを含めると問題が発生（コンマ区切りリスト対応のため） |

## アップグレード前チェックリスト

- [ ] セキュリティグローバルへの直接アクセスがないか確認（`^SYS("Security"` を検索）
- [ ] プライベートWebサーバーに依存しているアクセスがないか確認
- [ ] PKI関連クラスの使用状況を確認し、外部PKIサービスへの移行計画を策定
- [ ] `%CSP.REST`のDispatchRequestをオーバーライドしていないか確認
- [ ] External Language Gatewayの設定をGateway Name方式に移行
- [ ] BIキューブの一覧を取得し、再コンパイル＋再ビルド計画を策定
- [ ] 暗号化関数（AESCRCEncode等）の使用状況を確認
- [ ] フルバックアップの取得
- [ ] ロールバック手順の確認
- [ ] 非推奨機能の使用状況を確認（[09-deprecated.md](09-deprecated.md) 参照）

## アップグレード後チェックリスト

- [ ] IRISSECURITYデータベースの存在を確認
- [ ] セキュリティAPIベースのアクセスが正常に動作するか確認
- [ ] 外部Webサーバー経由でManagement Portalにアクセスできるか確認
- [ ] BIキューブの再コンパイル＋時間次元の再ビルドを実施
- [ ] External Language Gatewayの動作確認
- [ ] RESTディスパッチの動作確認
- [ ] アプリケーションの正常動作確認
- [ ] パフォーマンスベースラインの取得（日次レポートの有効化推奨）

## 関連ドキュメント・リファレンス

**関連ドキュメント:**
- [非推奨・廃止機能](09-deprecated.md) — 廃止・非推奨機能の一覧と移行先
- [セキュリティ変更](05-security.md) — IRISSECURITYデータベースとセキュリティウォレットの詳細
- [パフォーマンス改善](06-performance.md) — 拡張DBサイズ、IRISTEMPスパースファイル廃止の詳細
- [監視・可観測性](07-observability.md) — 日次パフォーマンスレポートの設定

**公式リファレンス:**
- [Upgrade Checklist（公式）](https://docs.intersystems.com/irislatest/csp/docbook/changes/index.html) — 2025.1以降の全互換性変更一覧
- [IRISSECURITY Upgrade Impact](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=ASECURITYDB) — セキュリティDB移行の詳細
- [Access the Management Portal Using Your Web Server](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GCGI_private_web) — プライベートWebサーバー廃止対応
- [Deprecated and Discontinued Features](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GCRN_discontinued_features) — 非推奨・廃止機能の公式一覧
