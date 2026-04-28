/// ベクトルサーチ・ACORN-1デモ
/// インデックスなし / インデックスあり（フィルタなし・フィルタ付き）の
/// 3パターンを計測し、両バージョンで比較する
///
/// 注意: データ生成に1〜2分かかります。
Class Demo.Vector.VectorSearch Extends %RegisteredObject
{

ClassMethod Run()
{
    write "============================================================",!
    write " ベクトルサーチ ACORN-1 デモ",!
    write " インデックスなし / あり（フィルタなし・あり）の3パターン比較",!
    write "============================================================",!
    write !,"  IRISバージョン: ", $zversion,!
    write "  ※ データ生成に1〜2分かかります。",!!

    set stmt = ##class(%SQL.Statement).%New()
    do ##class(%SQL.Statement).%ExecDirect(,"DROP TABLE IF EXISTS Demo.VectorDoc")

    // --- 1. テーブル作成（インデックスなし） ---
    write "--- 1. テーブル作成 ---",!
    set sql = "CREATE TABLE Demo.VectorDoc ("
        _"ID INTEGER NOT NULL AUTO_INCREMENT, "
        _"Title VARCHAR(200), "
        _"Category VARCHAR(50), "
        _"Embedding VECTOR(DOUBLE, 128), "
        _"PRIMARY KEY (ID))"
    set sc = stmt.%Prepare(sql)
    if $$$ISERR(sc) {
        write "  エラー: ",$system.Status.GetErrorText(sc),!
        quit
    }
    do stmt.%Execute()
    write "  テーブル作成: OK",!

    // --- 2. データ投入（100,000件、1,000カテゴリ → 選択率約0.1%） ---
    write !,"--- 2. データ投入（100,000件、1,000カテゴリ、選択率約0.1%） ---",!
    write "  ※ データ生成に数分かかります。",!
    set sc = stmt.%Prepare("INSERT INTO Demo.VectorDoc (Title, Category, Embedding) VALUES (?, ?, TO_VECTOR(?, DOUBLE, 128))")
    set t1 = $zh
    for i = 1:1:100000 {
        set cat = "Category"_($random(1000)+1)
        do stmt.%Execute("Doc"_i, cat, ..GenerateRandomVectorString(128))
        if (i#20000)=0 write "  ",i,"件...",!
    }
    write "  100,000件投入: ",$fn($zh-t1,"",1),"秒",!

    set queryVec = ..GenerateRandomVectorString(128)
    set iterations = 20

    // === 計測A: インデックスなし（全件スキャン） ===
    write !,"--- 3. 計測A: インデックスなし・フィルタ付き検索（",iterations,"回平均） ---",!
    write "  ※ HNSWインデックスなし → 全100,000件をスキャン",!
    set sc = stmt.%Prepare(
        "SELECT TOP 5 ID, Title, Category, VECTOR_COSINE(Embedding, TO_VECTOR(?, DOUBLE, 128)) AS Score "
        _"FROM Demo.VectorDoc WHERE Category = ? ORDER BY Score DESC")
    set tA = $zh
    for j=1:1:iterations {
        set rs = stmt.%Execute(queryVec, "Category1")
        while rs.%Next() { set x = 1 }
    }
    set timeNoIndex = ($zh - tA) / iterations
    write "  1回平均: ",$fn(timeNoIndex,"",6),"秒",!

    // === HNSWインデックス作成 ===
    write !,"--- 4. HNSWインデックス作成 ---",!
    set sc = stmt.%Prepare("CREATE INDEX HnswIdx ON Demo.VectorDoc (Embedding) AS %SQL.Index.HNSW")
    if $$$ISERR(sc) {
        write "  HNSWインデックス非対応",!
        do ##class(%SQL.Statement).%ExecDirect(,"DROP TABLE IF EXISTS Demo.VectorDoc")
        quit
    }
    set rs = stmt.%Execute()
    if rs.%SQLCODE < 0 {
        write "  エラー: ",rs.%SQLCODE," ",rs.%Message,!
        do ##class(%SQL.Statement).%ExecDirect(,"DROP TABLE IF EXISTS Demo.VectorDoc")
        quit
    }
    write "  HNSWインデックス作成: OK",!

    // === 計測B: インデックスあり・フィルタなし ===
    write !,"--- 5. 計測B: インデックスあり・フィルタなし検索（",iterations,"回平均） ---",!
    set sc = stmt.%Prepare(
        "SELECT TOP 5 ID, Title, Category, VECTOR_COSINE(Embedding, TO_VECTOR(?, DOUBLE, 128)) AS Score "
        _"FROM Demo.VectorDoc ORDER BY Score DESC")
    set tB = $zh
    for j=1:1:iterations {
        set rs = stmt.%Execute(queryVec)
        while rs.%Next() { set x = 1 }
    }
    set timeIndexNoFilter = ($zh - tB) / iterations
    write "  1回平均: ",$fn(timeIndexNoFilter,"",6),"秒",!

    // === 計測C: インデックスあり・フィルタ付き（ACORN-1） ===
    write !,"--- 6. 計測C: インデックスあり・フィルタ付き検索（",iterations,"回平均） ---",!
    write "  WHERE Category='Category1'（選択率約0.1%、100,000件中約100件）",!
    write "  ※ 2026.1: ACORN-1がグラフ走査中にフィルタ適用",!
    write "  ※ 2025.1: 検索後フィルタ（候補取得→フィルタ適用）",!
    set sc = stmt.%Prepare(
        "SELECT TOP 5 ID, Title, Category, VECTOR_COSINE(Embedding, TO_VECTOR(?, DOUBLE, 128)) AS Score "
        _"FROM Demo.VectorDoc WHERE Category = ? ORDER BY Score DESC")
    set tC = $zh
    for j=1:1:iterations {
        set rs = stmt.%Execute(queryVec, "Category1")
        while rs.%Next() { set x = 1 }
    }
    set timeIndexFilter = ($zh - tC) / iterations
    write "  1回平均: ",$fn(timeIndexFilter,"",6),"秒",!

    // === まとめ ===
    write !,"============================================================",!
    write " 結果まとめ（1回あたり平均、",iterations,"回実行）:",!
    write !
    write "  A. インデックスなし・フィルタ付き: ",$fn(timeNoIndex,"",6),"秒",!
    write "  B. インデックスあり・フィルタなし: ",$fn(timeIndexNoFilter,"",6),"秒",!
    write "  C. インデックスあり・フィルタ付き: ",$fn(timeIndexFilter,"",6),"秒",!
    write !
    if timeIndexFilter > 0 {
        write "  A vs C（インデックス効果）: ",$fn(timeNoIndex/timeIndexFilter,"",1),"倍高速",!
    }
    write !
    write " 両バージョンで実行し、特に C の時間を比較してください。",!
    write " 2026.1のACORN-1はCのフィルタ付き検索を高速化します。",!
    write "============================================================",!

    // クリーンアップ
    write !,"--- クリーンアップ ---",!
    do ##class(%SQL.Statement).%ExecDirect(,"DROP TABLE IF EXISTS Demo.VectorDoc")
    write "  完了",!
}

/// 指定次元数のランダムベクトル文字列を生成
ClassMethod GenerateRandomVectorString(dims As %Integer) As %String
{
    set str = "["
    for i = 1:1:dims {
        set:i>1 str = str_","
        set str = str_$fn(($random(20001)-10000)/10000,"",4)
    }
    quit str_"]"
}

}
