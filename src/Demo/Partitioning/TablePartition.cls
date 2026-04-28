/// テーブルパーティショニングデモ（2026.1の実験的機能）
/// PARTITION BY RANGE INTERVAL 構文でパーティションを自動生成し、
/// パーティションプルーニングの効果を実演
Class Demo.Partitioning.TablePartition Extends %RegisteredObject
{

/// パーティションテーブルの作成・データ投入・プルーニング効果の実演
ClassMethod Run()
{
    write "============================================================",!
    write " テーブルパーティショニングデモ（2026.1～実験的機能）",!
    write " PARTITION BY RANGE INTERVAL で日付ごとにパーティション自動生成",!
    write "============================================================",!

    // --- 1. パーティションテーブル作成 ---
    write !,"--- 1. パーティションテーブル作成 ---",!
    &sql(DROP TABLE IF EXISTS Demo.PartitionedSales)
    set stmt = ##class(%SQL.Statement).%New()
    set sql = "CREATE TABLE Demo.PartitionedSales ("
        _ "ID INTEGER NOT NULL AUTO_INCREMENT, "
        _ "TransactionDate DATE NOT NULL, "
        _ "CustomerID INTEGER, "
        _ "ProductName VARCHAR(100), "
        _ "Amount DECIMAL(12,2), "
        _ "Region VARCHAR(50), "
        _ "PRIMARY KEY (ID)"
        _ ") PARTITION BY RANGE (TransactionDate) INTERVAL 1 YEAR"
    set sc = stmt.%Prepare(sql)
    if $$$ISERR(sc) {
        write "  ※ パーティショニングは2026.1の実験的機能です",!
        write "  （このバージョンでは利用できません）",!
        return
    }
    set rs = stmt.%Execute()
    if rs.%SQLCODE < 0 {
        write "  テーブル作成エラー: SQLCODE=",rs.%SQLCODE," ",rs.%Message,!
        return
    }
    write "  Demo.PartitionedSales テーブル作成完了",!
    write "  パーティション: INTERVAL 1 YEAR（データ投入に応じて自動生成）",!

    // --- 2. データ投入（10,000件） ---
    write !,"--- 2. データ投入（10,000件: 2023〜2025年） ---",!
    do ..InsertSampleData()
    write "  10,000件のデータ投入完了",!

    // --- 3. パーティション別件数表示 ---
    write !,"--- 3. パーティション別件数 ---",!
    do ..ShowPartitionCounts()

    // --- 4. パーティションプルーニング速度比較 ---
    write !,"--- 4. パーティションプルーニング速度比較 ---",!
    do ..CompareQueryPerformance()

    // --- 5. クエリプラン表示 ---
    write !,"--- 5. クエリプラン（パーティションプルーニングの確認） ---",!
    do ..ShowQueryPlan()

    // クリーンアップ
    write !,"--- クリーンアップ ---",!
    &sql(DROP TABLE IF EXISTS Demo.PartitionedSales)
    write "  Demo.PartitionedSales テーブルを削除しました",!

    write !,"============================================================",!
    write " まとめ:",!
    write "  - PARTITION BY RANGE INTERVAL で日付ごとにパーティション自動生成",!
    write "  - WHERE句の日付条件でパーティションプルーニングが自動適用",!
    write "  - クエリプランに 'This plan utilizes partition pruning.' が表示",!
    write "  - $SYSTEM.SQL.Explain() でプルーニング動作を確認可能",!
    write "============================================================",!
}

/// サンプルデータ投入（10,000件）
ClassMethod InsertSampleData() [ Private ]
{
    set products = $lb("製品A","製品B","製品C","製品D","製品E")
    set regions = $lb("関東","関西","中部","九州","北海道")

    // 2023-01-01 〜 2025-12-31 の $horolog 日付値
    set startDateH = $zdateh("2023-01-01", 3)
    set endDateH = $zdateh("2025-12-31", 3)
    set totalDays = endDateH - startDateH + 1

    set stmt = ##class(%SQL.Statement).%New()
    set sc = stmt.%Prepare("INSERT INTO Demo.PartitionedSales (TransactionDate, CustomerID, ProductName, Amount, Region) VALUES (?,?,?,?,?)")
    if $$$ISERR(sc) {
        write "  INSERT準備エラー",!
        return
    }

    for i=1:1:10000 {
        // $horolog整数値で日付を渡す（文字列不可）
        set dateH = startDateH + $random(totalDays)
        set custId = $random(500) + 1
        set prod = $li(products, ($random(5) + 1))
        set amount = ($random(99901) + 100) + ($random(100) / 100)
        set reg = $li(regions, ($random(5) + 1))

        set rs = stmt.%Execute(dateH, custId, prod, amount, reg)
        if rs.%SQLCODE < 0 {
            write "  INSERT エラー（行 ",i,"）: SQLCODE=",rs.%SQLCODE," ",rs.%Message,!
            return
        }
    }
}

/// パーティション別件数の表示
ClassMethod ShowPartitionCounts() [ Private ]
{
    set stmt = ##class(%SQL.Statement).%New()
    // DATE比較は {d 'yyyy-mm-dd'} ODBC リテラルを使用（文字列リテラルは不可）
    set sql = "SELECT "
        _ "CASE "
        _ "WHEN TransactionDate < {d '2024-01-01'} THEN '2023年' "
        _ "WHEN TransactionDate < {d '2025-01-01'} THEN '2024年' "
        _ "WHEN TransactionDate < {d '2026-01-01'} THEN '2025年' "
        _ "ELSE '2026年以降' "
        _ "END AS PartitionRange, "
        _ "COUNT(*) AS RecordCount, "
        _ "SUM(Amount) AS TotalAmount "
        _ "FROM Demo.PartitionedSales "
        _ "GROUP BY "
        _ "CASE "
        _ "WHEN TransactionDate < {d '2024-01-01'} THEN '2023年' "
        _ "WHEN TransactionDate < {d '2025-01-01'} THEN '2024年' "
        _ "WHEN TransactionDate < {d '2026-01-01'} THEN '2025年' "
        _ "ELSE '2026年以降' "
        _ "END "
        _ "ORDER BY PartitionRange"
    set sc = stmt.%Prepare(sql)
    if $$$ISERR(sc) {
        write "  件数集計クエリ準備エラー",!
        return
    }
    set rs = stmt.%Execute()
    while rs.%Next() {
        write "  ",rs.PartitionRange,": "
        write $justify(rs.RecordCount, 6)," 件"
        write "  合計金額: ",$fnumber(rs.TotalAmount, ",", 0),!
    }
}

/// パーティションプルーニング速度比較
ClassMethod CompareQueryPerformance() [ Private ]
{
    set iterations = 100

    // --- 全テーブルスキャン ---
    write "  [A] 全テーブルスキャン:",!
    set stmt = ##class(%SQL.Statement).%New()
    set sc = stmt.%Prepare("SELECT COUNT(*), SUM(Amount) FROM Demo.PartitionedSales")
    if $$$ISERR(sc) { write "  クエリ準備エラー",! return }

    set rs = stmt.%Execute()
    if rs.%Next() { set fullCount = rs.%GetData(1)  set fullSum = rs.%GetData(2) }
    set t1 = $zh
    for i=1:1:iterations { set rs = stmt.%Execute()  while rs.%Next() { } }
    set fullTime = ($zh - t1) / iterations
    write "      件数: ",fullCount,"  合計金額: ",$fnumber(fullSum, ",", 2),!
    write "      平均実行時間（",iterations,"回平均）: ",$justify(fullTime, 1, 6)," 秒",!

    // --- プルーニング（2024年のみ） ---
    write !,"  [B] パーティションプルーニング（2024年のみ）:",!
    set stmt2 = ##class(%SQL.Statement).%New()
    // DATE比較は {d 'yyyy-mm-dd'} ODBC リテラルを使用
    set sql2 = "SELECT COUNT(*), SUM(Amount) FROM Demo.PartitionedSales "
        _ "WHERE TransactionDate >= {d '2024-01-01'} AND TransactionDate < {d '2025-01-01'}"
    set sc = stmt2.%Prepare(sql2)
    if $$$ISERR(sc) { write "  クエリ準備エラー",! return }

    set rs2 = stmt2.%Execute()
    if rs2.%Next() { set partCount = rs2.%GetData(1)  set partSum = rs2.%GetData(2) }
    set t1 = $zh
    for i=1:1:iterations { set rs2 = stmt2.%Execute()  while rs2.%Next() { } }
    set partTime = ($zh - t1) / iterations
    write "      件数: ",partCount,"  合計金額: ",$fnumber(partSum, ",", 2),!
    write "      平均実行時間（",iterations,"回平均）: ",$justify(partTime, 1, 6)," 秒",!

    // --- 比較結果 ---
    write !,"  [比較結果]",!
    write "    全テーブルスキャン:       ",$justify(fullTime, 1, 6)," 秒",!
    write "    パーティションプルーニング: ",$justify(partTime, 1, 6)," 秒",!
    if (fullTime > 0) && (partTime > 0) {
        set speedup = $justify(fullTime / partTime, 1, 1)
        write "    → プルーニングにより約 ",speedup," 倍高速",!
    }
}

/// クエリプラン表示（パーティションプルーニングの確認）
ClassMethod ShowQueryPlan() [ Private ]
{
    write "  [A] 全テーブルスキャン クエリプラン:",!
    do $SYSTEM.SQL.Explain("SELECT COUNT(*), SUM(Amount) FROM Demo.PartitionedSales")

    write !,"  [B] パーティションプルーニング クエリプラン（2024年のみ）:",!
    do $SYSTEM.SQL.Explain("SELECT COUNT(*), SUM(Amount) FROM Demo.PartitionedSales WHERE TransactionDate >= {d '2024-01-01'} AND TransactionDate < {d '2025-01-01'}")
    write !,"  ↑ 'This plan utilizes partition pruning.' が表示されていればプルーニング有効",!
}

/// 既存テーブルをパーティションテーブルに変換するデモ
/// （注意: ユーザー定義PKなしのテーブルが必要）
ClassMethod ConvertToPartitioned()
{
    write "============================================================",!
    write " 既存テーブルのパーティション変換デモ（2026.1～）",!
    write " ALTER TABLE ... CONVERT PARTITION BY RANGE INTERVAL",!
    write "============================================================",!

    // --- 1. デモ用テーブル作成（PKなし = system-assigned rowid） ---
    write !,"--- 1. デモ用テーブル作成（PKなし、50,000件） ---",!
    &sql(DROP TABLE IF EXISTS Demo.ConvertDemo)
    // カラム名は小文字（EAP制約）
    set rs = ##class(%SQL.Statement).%ExecDirect(,"CREATE TABLE Demo.ConvertDemo (txdate DATE NOT NULL, customerid INTEGER, amount DECIMAL(12,2), region VARCHAR(50))")
    if rs.%SQLCODE < 0 {
        write "  テーブル作成エラー: ",rs.%Message,!
        return
    }
    write "  Demo.ConvertDemo テーブル作成完了（PKなし）",!

    // データ投入
    set ins = ##class(%SQL.Statement).%New()
    set sc = ins.%Prepare("INSERT INTO Demo.ConvertDemo (txdate, customerid, amount, region) VALUES (?,?,?,?)")
    if $$$ISERR(sc) { write "  INSERT準備エラー",! return }
    set regions = $lb("関東","関西","中部","九州","北海道")
    set startH = $zdateh("2022-01-01",3)
    set totalDays = $zdateh("2024-12-31",3) - startH + 1
    for i=1:1:50000 {
        set dh = startH + $random(totalDays)
        do ins.%Execute(dh, $random(500)+1, 1000+$random(99000), $li(regions,$random(5)+1))
    }
    write "  50,000件のデータ投入完了",!

    // --- 2. 変換前の状態確認 ---
    write !,"--- 2. 変換前の状態確認 ---",!
    set rs = ##class(%SQL.Statement).%ExecDirect(,"SELECT COUNT(*) FROM Demo.ConvertDemo")
    if rs.%Next() { write "  Demo.ConvertDemo: ",rs.%GetData(1)," 件",! }

    // --- 3. ALTER TABLE CONVERT ---
    write !,"--- 3. パーティションへの変換実行 ---",!
    write "  ALTER TABLE Demo.ConvertDemo CONVERT",!
    write "  PARTITION BY RANGE (txdate) INTERVAL 1 YEAR",!
    set t1 = $zh
    set rs2 = ##class(%SQL.Statement).%ExecDirect(,"ALTER TABLE Demo.ConvertDemo CONVERT PARTITION BY RANGE (txdate) INTERVAL 1 YEAR")
    set convertTime = $zh - t1
    if rs2.%SQLCODE < 0 {
        write "  変換エラー: SQLCODE=",rs2.%SQLCODE," ",rs2.%Message,!
        &sql(DROP TABLE IF EXISTS Demo.ConvertDemo)
        return
    }
    write "  パーティション変換完了！ 変換時間: ",$justify(convertTime, 1, 3)," 秒",!

    // --- 4. 変換後の確認 ---
    write !,"--- 4. 変換後のパーティション別件数 ---",!
    set stmt = ##class(%SQL.Statement).%New()
    set sql = "SELECT "
        _ "CASE "
        _ "WHEN txdate < {d '2023-01-01'} THEN '2022年' "
        _ "WHEN txdate < {d '2024-01-01'} THEN '2023年' "
        _ "WHEN txdate < {d '2025-01-01'} THEN '2024年' "
        _ "ELSE '2025年以降' "
        _ "END AS PartRange, COUNT(*) AS Cnt "
        _ "FROM Demo.ConvertDemo "
        _ "GROUP BY CASE "
        _ "WHEN txdate < {d '2023-01-01'} THEN '2022年' "
        _ "WHEN txdate < {d '2024-01-01'} THEN '2023年' "
        _ "WHEN txdate < {d '2025-01-01'} THEN '2024年' "
        _ "ELSE '2025年以降' END "
        _ "ORDER BY PartRange"
    set sc = stmt.%Prepare(sql)
    if $$$ISERR(sc) { write "  件数集計エラー",! } else {
        set rs3 = stmt.%Execute()
        while rs3.%Next() { write "  ",rs3.PartRange,": ",$justify(rs3.Cnt, 6)," 件",! }
    }

    &sql(DROP TABLE IF EXISTS Demo.ConvertDemo)
    write !,"============================================================",!
    write " まとめ:",!
    write "  - ALTER TABLE CONVERT で既存テーブルをパーティション化",!
    write "  - データの再配置が自動で実行（テーブル再作成不要）",!
    write "  - 変換後はパーティションプルーニングが有効に",!
    write "============================================================",!
}

}
