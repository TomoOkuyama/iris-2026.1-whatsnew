# テーブルパーティショニング

## 概要

大規模なテーブルを、日付などのキーで物理的に複数の「区画（パーティション）」へ分割できます。IRIS 2026.1で実験的機能（Experimental Feature）として登場したテーブルパーティショニングを使うと、クエリで必要な区画だけを読み込み、古いデータを区画単位で別ストレージへ移し、稼働中のテーブルもパーティション化できます。具体的には、`PARTITION BY RANGE ... INTERVAL`構文でテーブルを物理分割し、パーティションプルーニングでクエリを最適化、`MOVE PARTITION`でデータをティアリングし、`ALTER TABLE CONVERT`で既存テーブルをパーティション化するといった一連の操作が、シンプルなSQL構文で実現できるようになりました。

> **注意**: テーブルパーティショニングは2026.1時点では**実験的機能（Early Access Program）**です。将来のリリースで仕様が変更される可能性があります。本番環境での使用前にリリースノートを確認してください。

---

### PARTITION BY RANGE 構文

テーブル作成時に `PARTITION BY RANGE (...) INTERVAL n UNIT` を指定するだけで、INSERTされたデータに応じてパーティションが自動的に生成されます。INTERVAL に指定した単位（YEAR / MONTH など）ごとに区画が分かれ、クエリの対象外となる区画は**ディスクから読み込まれません**。さらに、オプティマイザがプルーニングを自動的に適用するため、アプリケーション側のコードを変更する必要はありません。

```sql
-- 年単位でパーティション自動生成
CREATE TABLE Demo.PartitionedSales (
    ID INTEGER NOT NULL AUTO_INCREMENT,
    TransactionDate DATE NOT NULL,
    CustomerID INTEGER,
    ProductName VARCHAR(100),
    Amount DECIMAL(12,2),
    Region VARCHAR(50),
    PRIMARY KEY (ID)
) PARTITION BY RANGE (TransactionDate) INTERVAL 1 YEAR
```

```sql
-- 月単位の場合
CREATE TABLE Demo.LogData (
    ID INTEGER NOT NULL AUTO_INCREMENT,
    LogDate DATE NOT NULL,
    Message VARCHAR(500),
    PRIMARY KEY (ID)
) PARTITION BY RANGE (LogDate) INTERVAL 1 MONTH
```

区画は INSERT のたびに必要に応じて自動的に作成されます。2023年・2024年・2025年のデータを投入すると、年ごとに3つのパーティションが生成されます。

#### 活用シーン

- 日々蓄積されるログ・取引履歴・センサーデータを、日付単位の区画に整理して管理したい場合
- 数億行規模のテーブルから「先月分だけ」「今四半期だけ」を効率的に取り出したい場合

---

### パーティションプルーニング

「2024年のデータだけを取得したい」というクエリでは、全区画を走査する必要はありません。WHERE句の条件がパーティションキーと一致すれば、対象外の区画はスキャンの対象から外されます。スキャン対象とスキップ対象の判定はクエリオプティマイザが自動的に行うため、アプリケーション側で特別な対応をする必要はありません。

```sql
-- 2024年データのみスキャン（他の年のパーティションはスキップ）
-- IRIS の DATE 比較には {d 'yyyy-mm-dd'} ODBC リテラルを使用
SELECT COUNT(*), SUM(Amount)
FROM Demo.PartitionedSales
WHERE TransactionDate >= {d '2024-01-01'} AND TransactionDate < {d '2025-01-01'}
```

#### 実行コマンドと結果

事前の準備は最小限で構いません。デモクラス `Demo.Partitioning.TablePartition` を実行すれば、パーティションテーブルの作成からデータ投入、速度比較、クエリプラン表示までを一通り確認できます:

```objectscript
do ##class(Demo.Partitioning.TablePartition).Run()
```

実行すると、次の処理が順次自動で進みます:
1. パーティションテーブル（Demo.PartitionedSales）を作成（INTERVAL 1 YEAR）
2. 2023〜2025年のサンプルデータ10,000件を投入
3. 全テーブルスキャンとプルーニングの速度比較（各100回平均）
4. クエリプランを表示してプルーニング動作を確認

#### 速度比較の期待値

| クエリパターン | スキャン範囲 | 期待される速度 |
|-------------|-----------|-------------|
| 全テーブルスキャン | 全パーティション | 1x（ベースライン） |
| 2024年のみ（プルーニング） | 2024年パーティションのみ（1/3） | **約2〜3倍高速** |

> 区画が3つあり、2024年データはそのうちの約1/3にあたります。そのため、ディスクI/Oも約1/3に削減されます。データ量が大きく、ディスクI/Oがボトルネックになっている環境ほど、この差は顕著に現れます。

#### クエリプランでのプルーニング確認

区画が実際にスキップされているかどうかは、`$SYSTEM.SQL.Explain()` でクエリプランを表示して確認できます:

```objectscript
do $SYSTEM.SQL.Explain("SELECT COUNT(*), SUM(Amount) FROM Demo.PartitionedSales WHERE TransactionDate >= {d '2024-01-01'} AND TransactionDate < {d '2025-01-01'}")
```

プルーニングが有効に動作している場合、クエリプランの `Info:` セクションに次の一文が出力されます:

```
Info:
This plan utilizes partition pruning.
```

あわせて、マップ読み取りの行に `(with a range condition)` という注記が付与されます:

```
Read master map Demo.PartitionedSales.%%PartitionIdKey1,
    looping on partition id 1 (with a range condition), bucket, and partition row id.
```

なお、プルーニングが働かず全スキャンとなる場合は、`Info:` にこの記述は出力されず、`(with a range condition)` も付与されません。両者のプランを比較すれば、プルーニングが効いているかどうかを明確に判別できます。

---

### MOVE PARTITION

利用頻度の低くなった古いデータを、区画単位でまとめて別のデータベースへ移動できます。特定期間のパーティションを一括で移動できるため、保持期間の長いデータを低コストストレージへ退避させるティアリング運用が現実的な選択肢となります。また、区画単位のDROPは、行ごとに削除するDELETEと比べて**処理時間が大幅に短縮されます**。

```sql
-- 日付範囲でパーティションを移動（ARCHIVEデータベースへ）
ALTER TABLE Demo.PartitionedSales MOVE PARTITION BETWEEN '2023-01-01' AND '2023-12-31' TO "ARCHIVE"

-- 不要なパーティションをDROP（日付範囲指定）
ALTER TABLE Demo.PartitionedSales DROP PARTITION BETWEEN '2023-01-01' AND '2023-12-31'
```

> **MOVE PARTITIONを使う前に**: 移動先のデータベース（`ARCHIVE`）を事前に作成しておく必要があります。さらに、IRISインスタンスで「Journal freeze on error」設定が有効になっていることが前提条件です（管理ポータル → システム管理 → 構成 → ジャーナル設定）。なお、`DROP PARTITION` についてはこれらの制約なしで実行できます。

#### 活用シーン

- 前年度分のデータを、通常運用のストレージから安価なアーカイブ領域へ移行したい場合
- 保持期限を過ぎた大量データを、区画単位でまとめて削除したい場合（`DROP PARTITION` は行単位DELETEと比べて高速に処理できます）

---

### ALTER TABLE CONVERTによる既存テーブルのパーティション化

運用中の非パーティションテーブルを、再作成せずにパーティションテーブルへ変換できます。**テーブルを作り直さず、データを保持したまま区画化**できるため、本番環境でも移行の手間とリスクを抑えながらパーティショニングを導入できます。

```sql
-- INTERVAL形式（自動で年次パーティションを生成）
ALTER TABLE Demo.LogData CONVERT
PARTITION BY RANGE (logdate) INTERVAL 1 YEAR

-- 月次パーティションの場合
ALTER TABLE Demo.LogData CONVERT
PARTITION BY RANGE (logdate) INTERVAL 1 MONTH
```

> **CONVERT を実行する前に確認しておきたい制約（2026.1 EAP）:**
> - テーブルに**ユーザー定義のPRIMARY KEY**が存在する場合は変換できません（システムが割り当てるRowIDが必要です）
> - PARTITION BY RANGE のカラム名は**小文字**で指定します（例: `logdate`、`transactiondate`）

#### 実行コマンド

デモクラスには変換専用のテーブルが用意されているため、簡単に動作を確認できます:

```objectscript
do ##class(Demo.Partitioning.TablePartition).ConvertToPartitioned()
```

変換が完了すると、区画ごとの件数と変換に要した時間が出力されます。元のデータが正しく区画へ振り分けられていることを確認できます。

#### 活用シーン

- 停止できない大規模テーブルを、稼働中のままパーティション化したい場合（既存アプリは変更不要）
- 今後増加していくデータを見越して、段階的にアーキテクチャを拡張したい場合
- 長期間運用しているテーブルに対して、新たにティアリング戦略を導入したい場合
