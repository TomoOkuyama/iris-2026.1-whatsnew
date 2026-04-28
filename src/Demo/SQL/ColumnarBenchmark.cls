/// カラムテーブル低カーディナリティ集計改善のベンチマーク
/// 行ストレージとカラムナーストレージでGROUP BY集計の速度を比較
/// 多カラムテーブルで少数カラムのみ集計するパターンでカラムナーの効果を実証
Class Demo.SQL.ColumnarBenchmark Extends %RegisteredObject
{

ClassMethod Run()
{
    write "============================================================",!
    write " カラムテーブル低カーディナリティ集計ベンチマーク",!
    write " 行ストレージ vs カラムナーストレージ（20カラム・100万行）",!
    write "============================================================",!!

    set rowCount = 1000000
    set regions = $lb("East","West","North","South","Central")
    set statuses = $lb("Active","Closed","Pending")

    // --- 1. 行ストレージテーブル作成（20カラム） ---
    write "--- 1. 行ストレージテーブル作成（20カラム、",rowCount,"行） ---",!
    do ##class(%SQL.Statement).%ExecDirect(,"DROP TABLE IF EXISTS Demo.BenchRow")
    set ddl = "CREATE TABLE Demo.BenchRow ("
            _ "ID INT AUTO_INCREMENT PRIMARY KEY,"
            _ "Region VARCHAR(10), Status VARCHAR(10), Amount DECIMAL(10,2),"
            _ "Col01 VARCHAR(100), Col02 VARCHAR(100), Col03 VARCHAR(100), Col04 VARCHAR(100),"
            _ "Col05 VARCHAR(100), Col06 VARCHAR(100), Col07 VARCHAR(100), Col08 VARCHAR(100),"
            _ "Col09 VARCHAR(100), Col10 VARCHAR(100), Col11 VARCHAR(100), Col12 VARCHAR(100),"
            _ "Col13 DECIMAL(10,2), Col14 DECIMAL(10,2), Col15 DECIMAL(10,2), Col16 DECIMAL(10,2)"
            _ ")"
    do ##class(%SQL.Statement).%ExecDirect(,ddl)
    set ins = ##class(%SQL.Statement).%New()
    set sc = ins.%Prepare("INSERT INTO Demo.BenchRow (Region, Status, Amount, Col01, Col02, Col03, Col04, Col05, Col06, Col07, Col08, Col09, Col10, Col11, Col12, Col13, Col14, Col15, Col16) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)")
    set t1 = $zh
    for i=1:1:rowCount {
        set pad = "PADDING-DATA-"_$justify(i,10)
        do ins.%Execute($li(regions,$random(5)+1), $li(statuses,$random(3)+1), $random(100000)/100, pad, pad, pad, pad, pad, pad, pad, pad, pad, pad, pad, pad, $random(99999)/100, $random(99999)/100, $random(99999)/100, $random(99999)/100)
    }
    set rowInsert = $zh - t1
    write "  完了（",$fn(rowInsert,"",1),"秒）",!

    // --- 2. カラムナーストレージテーブル作成（同一スキーマ） ---
    write !,"--- 2. カラムナーストレージテーブル作成（20カラム、",rowCount,"行） ---",!
    do ##class(%SQL.Statement).%ExecDirect(,"DROP TABLE IF EXISTS Demo.BenchCol")
    set ddlCol = "CREATE TABLE Demo.BenchCol ("
            _ "ID INT AUTO_INCREMENT PRIMARY KEY,"
            _ "Region VARCHAR(10), Status VARCHAR(10), Amount DECIMAL(10,2),"
            _ "Col01 VARCHAR(100), Col02 VARCHAR(100), Col03 VARCHAR(100), Col04 VARCHAR(100),"
            _ "Col05 VARCHAR(100), Col06 VARCHAR(100), Col07 VARCHAR(100), Col08 VARCHAR(100),"
            _ "Col09 VARCHAR(100), Col10 VARCHAR(100), Col11 VARCHAR(100), Col12 VARCHAR(100),"
            _ "Col13 DECIMAL(10,2), Col14 DECIMAL(10,2), Col15 DECIMAL(10,2), Col16 DECIMAL(10,2)"
            _ ") WITH STORAGETYPE = COLUMNAR"
    set rs = ##class(%SQL.Statement).%ExecDirect(,ddlCol)
    if rs.%SQLCODE < 0 {
        write "  [エラー] カラムナーテーブル作成失敗: ",rs.%Message,!
        do ##class(%SQL.Statement).%ExecDirect(,"DROP TABLE IF EXISTS Demo.BenchRow")
        return
    }
    set sc = ins.%Prepare("INSERT INTO Demo.BenchCol (Region, Status, Amount, Col01, Col02, Col03, Col04, Col05, Col06, Col07, Col08, Col09, Col10, Col11, Col12, Col13, Col14, Col15, Col16) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)")
    set t2 = $zh
    for i=1:1:rowCount {
        set pad = "PADDING-DATA-"_$justify(i,10)
        do ins.%Execute($li(regions,$random(5)+1), $li(statuses,$random(3)+1), $random(100000)/100, pad, pad, pad, pad, pad, pad, pad, pad, pad, pad, pad, pad, $random(99999)/100, $random(99999)/100, $random(99999)/100, $random(99999)/100)
    }
    set colInsert = $zh - t2
    write "  完了（",$fn(colInsert,"",1),"秒）",!

    // --- 3. ベンチマーク: 低カーディナリティGROUP BY（2カラムのみ使用） ---
    set iterations = 100
    write !,"--- 3. GROUP BY集計ベンチマーク（",iterations,"回実行） ---",!
    write "  クエリ: SELECT Region, Status, COUNT(*), SUM(Amount)",!
    write "          GROUP BY Region, Status",!
    write "  ※ 20カラム中3カラムのみ使用 → カラムナーは17カラム分の読み取りをスキップ",!!

    // 行ストレージ
    set grp = ##class(%SQL.Statement).%New()
    set sc = grp.%Prepare("SELECT Region, Status, COUNT(*) cnt, SUM(Amount) total FROM Demo.BenchRow GROUP BY Region, Status")
    set t3 = $zh
    for j=1:1:iterations {
        set rs = grp.%Execute()
        while rs.%Next() { set x = 1 }
    }
    set rowTime = $zh - t3
    write "  行ストレージ:        ",$fn(rowTime,"",4)," 秒（",iterations,"回）",!

    // カラムナーストレージ
    set sc = grp.%Prepare("SELECT Region, Status, COUNT(*) cnt, SUM(Amount) total FROM Demo.BenchCol GROUP BY Region, Status")
    set t4 = $zh
    for j=1:1:iterations {
        set rs = grp.%Execute()
        while rs.%Next() { set x = 1 }
    }
    set colTime = $zh - t4
    write "  カラムナーストレージ: ",$fn(colTime,"",4)," 秒（",iterations,"回）",!

    // 比較
    if colTime > 0 {
        set ratio = rowTime / colTime
        write !,"  → カラムナーは行ストレージの約 ",$fn(ratio,"",1)," 倍高速",!
    }

    // --- 4. 結果サンプル ---
    write !,"--- 4. 集計結果サンプル ---",!
    set sc = grp.%Prepare("SELECT Region, Status, COUNT(*) cnt, SUM(Amount) total FROM Demo.BenchCol GROUP BY Region, Status ORDER BY Region, Status")
    set rs = grp.%Execute()
    write "  Region  Status   件数      合計金額",!
    write "  ------- -------- -------- ------------",!
    while rs.%Next() {
        write "  ",$justify(rs.Region,-7)," ",$justify(rs.Status,-8)," ",$justify(rs.cnt,8)," ",$fnumber(rs.total,",",2),!
    }

    // --- クリーンアップ ---
    write !,"--- クリーンアップ ---",!
    do ##class(%SQL.Statement).%ExecDirect(,"DROP TABLE IF EXISTS Demo.BenchRow")
    do ##class(%SQL.Statement).%ExecDirect(,"DROP TABLE IF EXISTS Demo.BenchCol")
    write "  完了",!
}

}
