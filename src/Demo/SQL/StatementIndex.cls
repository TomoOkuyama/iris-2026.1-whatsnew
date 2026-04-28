/// SQL Statement Index 軽量ランタイム統計改善のデモ
/// 大量のユニークSQLを生成・実行し、ステートメントの
/// コンパイル・キャッシュ登録のパフォーマンスを比較する
///
/// 注意: 500テーブルの作成・削除を行うため、実行に数十秒〜数分かかります。
Class Demo.SQL.StatementIndex Extends %RegisteredObject
{

ClassMethod Run()
{
    write "============================================================",!
    write " SQL Statement Index パフォーマンスデモ",!
    write " ステートメントのコンパイル・キャッシュ登録の速度比較",!
    write "============================================================",!!

    write "  IRISバージョン: ", $zversion,!!
    write "  ※ 500テーブルの作成・削除を行います。完了まで数十秒〜数分かかります。",!!

    // --- 1. 大量のユニークSQLを生成 ---
    write "--- 1. 500個のユニークテーブル作成 + 500個のSELECT実行 ---",!

    set t1 = $zh

    for i=1:1:500 {
        do ##class(%SQL.Statement).%ExecDirect(,"CREATE TABLE IF NOT EXISTS Demo.StmtTest"_i_" (ID INT, Val"_i_" INT)")
    }

    for i=1:1:500 {
        do ##class(%SQL.Statement).%ExecDirect(,"SELECT * FROM Demo.StmtTest"_i_" WHERE ID = 1")
    }

    set genTime = $zh - t1
    write "  1,000ステートメント生成時間: ", $fn(genTime,"",2), " 秒",!!

    // --- 2. キャッシュ件数確認 ---
    write "--- 2. キャッシュされたステートメント数 ---",!
    set stmt = ##class(%SQL.Statement).%New()
    set sc = stmt.%Prepare("SELECT COUNT(*) cnt FROM INFORMATION_SCHEMA.STATEMENTS")
    set rs = stmt.%Execute()
    if rs.%Next() {
        write "  登録済み: ", rs.cnt, " 件",!
    }

    // --- 3. INFORMATION_SCHEMAクエリ速度 ---
    write !,"--- 3. INFORMATION_SCHEMA.STATEMENTS クエリ速度（10回全件スキャン） ---",!
    set sc = stmt.%Prepare("SELECT Hash, Statement, Timestamp FROM INFORMATION_SCHEMA.STATEMENTS ORDER BY Timestamp DESC")
    set t2 = $zh
    for j=1:1:10 {
        set rs = stmt.%Execute()
        while rs.%Next() { set x = 1 }
    }
    set queryTime = $zh - t2
    write "  10回合計: ", $fn(queryTime,"",4), " 秒",!
    write "  1回平均:  ", $fn(queryTime/10,"",4), " 秒",!

    // --- 4. クリーンアップ ---
    write !,"--- 4. クリーンアップ ---",!
    for i=1:1:500 {
        do ##class(%SQL.Statement).%ExecDirect(,"DROP TABLE IF EXISTS Demo.StmtTest"_i)
    }
    write "  完了",!

    // --- 5. 結果の見方 ---
    write !,"--- 5. 結果の見方 ---",!
    write !
    write "  「1,000ステートメント生成時間」を2025.1と2026.1で比較してください。",!
    write "  2025.3以降ではSQLステートメントのコンパイル・キャッシュ登録・",!
    write "  ランタイム統計処理が軽量化されており、大量のユニークSQLを",!
    write "  処理する環境でスループットが向上します。",!
    write !
    write "  参考値（Docker Desktop Apple Silicon での実測）:",!
    write "    2025.1: 約120秒",!
    write "    2026.1: 約 50秒（約2.4倍高速）",!

    write !,"============================================================",!
}

}
