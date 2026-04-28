/// 外部テーブルJOINプッシュダウンデモ（IRIS 2025.3で追加、2026.1に含まれる）
/// PostgreSQLコンテナに接続し、Foreign TableのJOINプッシュダウンを実演。
/// 同一外部サーバー上の複数外部テーブルをJOINする際、JOIN操作全体が
/// 外部サーバーにプッシュダウンされ、ネットワークI/Oと処理時間を大幅に削減。
Class Demo.SQL.ForeignTableJoin Extends %RegisteredObject
{

/// メインデモ実行
ClassMethod Run()
{
    write "============================================================",!
    write " 外部テーブルJOINプッシュダウン デモ（IRIS 2025.3~/2026.1）",!
    write " PostgreSQLコンテナとのライブ連携デモ",!
    write "============================================================",!

    write !,"  IRISバージョン: ", $zversion,!
    write "  ※ JOINプッシュダウンは2025.3以降で有効。",!
    write "    2025.1でもForeign Tableの作成・JOINクエリは実行可能ですが、",!
    write "    プッシュダウンされません。クエリプランで違いを確認してください。",!

    // 外部テーブルが存在しなければセットアップ
    if '..ForeignTablesExist() {
        write !,"外部テーブルが未作成です。セットアップを実行します...",!
        set sc = ..Setup()
        if $$$ISERR(sc) {
            write !,"[エラー] セットアップに失敗しました。",!
            write "  PostgreSQLコンテナが起動しているか確認してください。",!
            write "  docker compose up -d postgres",!
            return
        }
    }

    write !,"--- JOINクエリ実行 ---",!
    write !

    // タイミング計測
    set startTime = $zh

    set stmt = ##class(%SQL.Statement).%New()
    set sql = "SELECT c.name, c.city, COUNT(o.id) AS order_count, SUM(o.amount) AS total_amount "
             _"FROM Demo.FT_Customers c "
             _"JOIN Demo.FT_Orders o ON c.id = o.customer_id "
             _"GROUP BY c.name, c.city "
             _"ORDER BY total_amount DESC"

    set sc = stmt.%Prepare(sql)
    if $$$ISERR(sc) {
        write "[エラー] クエリの準備に失敗しました。",!
        do $system.OBJ.DisplayError(sc)
        return
    }

    set rs = stmt.%Execute()
    if rs.%SQLCODE < 0 {
        write "[エラー] クエリ実行失敗: SQLCODE=",rs.%SQLCODE," ",rs.%Message,!
        return
    }

    // 結果表示
    write "  顧客名        | 都市   | 注文数 | 合計金額",!
    write "  ──────────────┼────────┼────────┼──────────────",!
    set rowCount = 0
    while rs.%Next() {
        set rowCount = rowCount + 1
        write "  ",$justify(rs.%GetData(1),14)," | "
        write $justify(rs.%GetData(2),6)," | "
        write $justify(rs.%GetData(3),6)," | "
        write $fnumber(rs.%GetData(4),",",2),!
    }

    set elapsed = $zh - startTime
    write !,"  取得行数: ",rowCount,!
    write "  実行時間: ",$fnumber(elapsed,"",4)," 秒",!

    // クエリプラン表示
    write !,"--- クエリプラン（EXPLAIN） ---",!
    write !
    try {
        set plan = $SYSTEM.SQL.Explain(sql)
        write plan,!
    } catch ex {
        write "  ※ クエリプランの取得中にエラーが発生しました。",!
        write "    エラー: ",ex.DisplayString(),!
    }

    write !,"--- 解説 ---",!
    write "  2025.3以降ではJOIN全体がPostgreSQLに送信され、",!
    write "  結果のみがIRISに返されます（JOINプッシュダウン）。",!
    write !
    write "  クエリプランに「Foreign Pushed Join」と表示されていれば、",!
    write "  プッシュダウンが有効に機能しています。",!
    write !
    write "  これにより以下の効果が得られます:",!
    write "    - ネットワーク転送量の大幅削減",!
    write "    - PostgreSQL側のインデックスとオプティマイザの活用",!
    write "    - IRIS側のメモリ消費削減",!
    write !,"============================================================",!
}

/// 外部サーバーと外部テーブルのセットアップ
ClassMethod Setup() As %Status
{
    set sc = $$$OK
    write !,"--- Foreign Server / Foreign Table セットアップ ---",!

    set stmt = ##class(%SQL.Statement).%New()

    // 0. SQL Gateway Connection作成（JDBCドライバ経由）
    write "  (0) SQL Gateway Connection 'PGDemo' を作成中...",!
    if '##class(%Library.SQLConnection).%ExistsId("PGDemo") {
        set conn = ##class(%Library.SQLConnection).%New()
        set conn.Name = "PGDemo"
        set conn.URL = "jdbc:postgresql://postgres:5432/demodb"
        set conn.Usr = "demo"
        set conn.pwd = "demo"
        set conn.isJDBC = 1
        set conn.driver = "org.postgresql.Driver"
        set conn.classpath = "/usr/irissys/dev/java/lib/1.8/postgresql-42.7.5.jar"
        set sc = conn.%Save()
        if $$$ISERR(sc) {
            write "    [エラー] SQL Gateway Connection作成失敗: ",$system.Status.GetErrorText(sc),!
            return sc
        }
        write "    PGDemo を作成しました。",!
    } else {
        write "    ※ PGDemoは既に存在します。スキップします。",!
    }

    // 1. 外部サーバー作成
    write "  (1) FOREIGN SERVER 'PGServer' を作成中...",!
    set sql = "CREATE FOREIGN SERVER PGServer "
             _"FOREIGN DATA WRAPPER JDBC "
             _"CONNECTION 'PGDemo'"
    set sc = stmt.%Prepare(sql)
    if $$$ISERR(sc) {
        write "    [エラー] FOREIGN SERVER作成の準備に失敗: ",$system.Status.GetErrorText(sc),!
        return sc
    }
    set rs = stmt.%Execute()
    if rs.%SQLCODE < 0 {
        if rs.%SQLCODE = -201 {
            write "    ※ PGServerは既に存在します。スキップします。",!
        } else {
            write "    [エラー] SQLCODE=",rs.%SQLCODE," ",rs.%Message,!
            return $$$ERROR($$$GeneralError, "FOREIGN SERVER作成失敗: "_rs.%Message)
        }
    } else {
        write "    PGServer を作成しました。",!
    }

    // 2. 外部テーブル作成: FT_Customers（カラム定義を明示）
    write "  (2) FOREIGN TABLE 'Demo.FT_Customers' を作成中...",!
    set sql = "CREATE FOREIGN TABLE Demo.FT_Customers "
             _"(id INT, name VARCHAR(100), email VARCHAR(100), city VARCHAR(50), country VARCHAR(50)) "
             _"SERVER PGServer TABLE 'customers'"
    set sc = stmt.%Prepare(sql)
    if $$$ISERR(sc) {
        write "    [エラー] FT_Customers作成の準備に失敗: ",$system.Status.GetErrorText(sc),!
        return sc
    }
    set rs = stmt.%Execute()
    if rs.%SQLCODE < 0 {
        if rs.%SQLCODE = -201 {
            write "    ※ Demo.FT_Customersは既に存在します。スキップします。",!
        } else {
            write "    [エラー] SQLCODE=",rs.%SQLCODE," ",rs.%Message,!
            return $$$ERROR($$$GeneralError, "FT_Customers作成失敗: "_rs.%Message)
        }
    } else {
        write "    Demo.FT_Customers を作成しました。",!
    }

    // 3. 外部テーブル作成: FT_Orders
    write "  (3) FOREIGN TABLE 'Demo.FT_Orders' を作成中...",!
    set sql = "CREATE FOREIGN TABLE Demo.FT_Orders "
             _"(id INT, customer_id INT, order_date DATE, amount DECIMAL(12,2), status VARCHAR(20)) "
             _"SERVER PGServer TABLE 'orders'"
    set sc = stmt.%Prepare(sql)
    if $$$ISERR(sc) {
        write "    [エラー] FT_Orders作成の準備に失敗: ",$system.Status.GetErrorText(sc),!
        return sc
    }
    set rs = stmt.%Execute()
    if rs.%SQLCODE < 0 {
        if rs.%SQLCODE = -201 {
            write "    ※ Demo.FT_Ordersは既に存在します。スキップします。",!
        } else {
            write "    [エラー] SQLCODE=",rs.%SQLCODE," ",rs.%Message,!
            return $$$ERROR($$$GeneralError, "FT_Orders作成失敗: "_rs.%Message)
        }
    } else {
        write "    Demo.FT_Orders を作成しました。",!
    }

    write !,"  セットアップ完了。",!
    return sc
}

/// 外部テーブルが存在するか確認
ClassMethod ForeignTablesExist() As %Boolean
{
    try {
        set stmt = ##class(%SQL.Statement).%New()
        set sc = stmt.%Prepare("SELECT COUNT(*) FROM Demo.FT_Customers")
        if $$$ISERR(sc) return 0
        set rs = stmt.%Execute()
        if rs.%SQLCODE < 0 return 0
        return 1
    } catch ex {
        return 0
    }
}

/// クリーンアップ（外部テーブルとサーバーを削除）
ClassMethod Cleanup()
{
    write !,"--- クリーンアップ ---",!

    set stmt = ##class(%SQL.Statement).%New()

    // 外部テーブル削除
    for tbl = "Demo.FT_Orders", "Demo.FT_Customers" {
        write "  DROP FOREIGN TABLE ",tbl,"...",!
        set sc = stmt.%Prepare("DROP FOREIGN TABLE "_tbl)
        if $$$ISOK(sc) {
            set rs = stmt.%Execute()
            if rs.%SQLCODE < 0 {
                write "    ※ SQLCODE=",rs.%SQLCODE," ",rs.%Message,!
            } else {
                write "    削除しました。",!
            }
        } else {
            write "    ※ 準備エラー（テーブルが存在しない可能性があります）",!
        }
    }

    // 外部サーバー削除
    write "  DROP FOREIGN SERVER PGServer...",!
    set sc = stmt.%Prepare("DROP FOREIGN SERVER PGServer")
    if $$$ISOK(sc) {
        set rs = stmt.%Execute()
        if rs.%SQLCODE < 0 {
            write "    ※ SQLCODE=",rs.%SQLCODE," ",rs.%Message,!
        } else {
            write "    削除しました。",!
        }
    } else {
        write "    ※ 準備エラー（サーバーが存在しない可能性があります）",!
    }

    // SQL Gateway Connection削除
    write "  SQL Gateway Connection 'PGDemo' を削除...",!
    if ##class(%Library.SQLConnection).%ExistsId("PGDemo") {
        set sc = ##class(%Library.SQLConnection).%DeleteId("PGDemo")
        write "    削除しました。",!
    }

    write !,"  クリーンアップ完了。",!
}

}
