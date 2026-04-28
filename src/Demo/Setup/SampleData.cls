Class Demo.Setup.SampleData
{

/// テーブル作成とサンプルデータ投入
ClassMethod Setup() As %Status
{
    set sc = $$$OK
    try {
        write "=== サンプルデータセットアップ開始 ===",!

        // 既存テーブルを削除
        do ..DropTables()

        // テーブル作成
        set sc = ..CreateTables()
        if $$$ISERR(sc) { write "テーブル作成エラー",! quit }

        // データ投入
        set sc = ..InsertPersonData()
        if $$$ISERR(sc) { write "Personデータ投入エラー",! quit }

        set sc = ..InsertSalesData()
        if $$$ISERR(sc) { write "SalesTransactionデータ投入エラー",! quit }

        do ..Check()
        write "=== サンプルデータセットアップ完了 ===",!
    } catch ex {
        set sc = ex.AsStatus()
        write "エラー発生: ",ex.DisplayString(),!
    }
    return sc
}

/// テーブルの件数確認表示
ClassMethod Check()
{
    write !,"--- テーブル件数確認 ---",!

    &sql(SELECT COUNT(*) INTO :cnt FROM Demo.Person)
    write "Demo.Person: ",cnt," 件",!

    &sql(SELECT COUNT(*) INTO :cnt FROM Demo.SalesTransaction)
    write "Demo.SalesTransaction: ",cnt," 件",!

    write "------------------------",!
}

/// 既存テーブルを削除
ClassMethod DropTables() [ Private ]
{
    &sql(DROP TABLE IF EXISTS Demo.SalesTransaction)
    &sql(DROP TABLE IF EXISTS Demo.Person)
    return
}

/// テーブル作成
ClassMethod CreateTables() As %Status [ Private ]
{
    &sql(
        CREATE TABLE Demo.Person (
            ID INTEGER IDENTITY PRIMARY KEY,
            Name VARCHAR(100),
            Age INTEGER,
            City VARCHAR(50),
            Department VARCHAR(50),
            Salary DECIMAL(10,2),
            HireDate DATE,
            Email VARCHAR(100)
        )
    )
    if SQLCODE'=0,SQLCODE'=-201 {
        write "Demo.Person作成エラー SQLCODE=",SQLCODE,!
        return $$$ERROR($$$GeneralError,"Demo.Person作成失敗: SQLCODE="_SQLCODE)
    }
    write "Demo.Person テーブル作成完了",!

    &sql(
        CREATE TABLE Demo.SalesTransaction (
            ID INTEGER IDENTITY PRIMARY KEY,
            TransactionDate DATE,
            CustomerID INTEGER,
            ProductName VARCHAR(100),
            Amount DECIMAL(12,2),
            Region VARCHAR(50)
        )
    )
    if SQLCODE'=0,SQLCODE'=-201 {
        write "Demo.SalesTransaction作成エラー SQLCODE=",SQLCODE,!
        return $$$ERROR($$$GeneralError,"Demo.SalesTransaction作成失敗: SQLCODE="_SQLCODE)
    }
    write "Demo.SalesTransaction テーブル作成完了",!

    return $$$OK
}

/// Demo.Person データ投入 (10,000件)
ClassMethod InsertPersonData() As %Status [ Private ]
{
    set lastNames = $lb("田中","鈴木","佐藤","山田","渡辺","伊藤","中村","小林","加藤","吉田")
    set firstNames = $lb("太郎","花子","一郎","美咲","健太","由美","翔太","愛","大輔","真由")
    set cities = $lb("東京","大阪","名古屋","福岡","札幌","仙台","横浜","京都","神戸","広島")
    set departments = $lb("営業","開発","人事","経理","企画","総務","品質","製造","物流","サポート")

    set total = 10000
    write "Demo.Person データ投入中 (",total,"件)...",!

    for i=1:1:total {
        // ランダムに各フィールドを生成
        set lastName = $li(lastNames, ($random(10) + 1))
        set firstName = $li(firstNames, ($random(10) + 1))
        set name = lastName _ " " _ firstName

        set age = 22 + $random(43)
        set city = $li(cities, ($random(10) + 1))
        set dept = $li(departments, ($random(10) + 1))

        // 給与: 300,000 〜 1,200,000 (100円単位)
        set salary = 300000 + ($random(9001) * 100)

        // 入社日: 過去20年以内（$horolog整数値で渡す）
        set daysAgo = $random(7300)
        set hireDate = $piece($horolog, ",", 1) - daysAgo

        // メール
        set email = "user" _ i _ "@example.com"

        &sql(
            INSERT INTO Demo.Person (Name, Age, City, Department, Salary, HireDate, Email)
            VALUES (:name, :age, :city, :dept, :salary, :hireDate, :email)
        )
        if SQLCODE'=0 {
            write "Person INSERT エラー i=",i," SQLCODE=",SQLCODE,!
            return $$$ERROR($$$GeneralError,"Person INSERT失敗: SQLCODE="_SQLCODE)
        }

        // 進捗表示
        if (i # 2000 = 0) {
            write "  ",i," 件完了",!
        }
    }

    write "Demo.Person データ投入完了",!
    return $$$OK
}

/// Demo.SalesTransaction データ投入 (50,000件)
ClassMethod InsertSalesData() As %Status [ Private ]
{
    set products = $lb("製品A","製品B","製品C","製品D","製品E")
    set regions = $lb("関東","関西","中部","九州","北海道")

    set total = 50000
    write "Demo.SalesTransaction データ投入中 (",total,"件)...",!

    // 過去3年分の日付範囲
    set baseDateH = $piece($horolog, ",", 1)

    for i=1:1:total {
        // 過去3年（約1095日）のランダムな日付（$horolog整数値で渡す）
        set daysAgo = $random(1095)
        set txDate = baseDateH - daysAgo

        // 顧客ID: 1〜500
        set custID = $random(500) + 1

        set product = $li(products, ($random(5) + 1))

        // 金額: 1,000 〜 500,000 (10円単位)
        set amount = 1000 + ($random(49900) * 10)

        set region = $li(regions, ($random(5) + 1))

        &sql(
            INSERT INTO Demo.SalesTransaction (TransactionDate, CustomerID, ProductName, Amount, Region)
            VALUES (:txDate, :custID, :product, :amount, :region)
        )
        if SQLCODE'=0 {
            write "SalesTransaction INSERT エラー i=",i," SQLCODE=",SQLCODE,!
            return $$$ERROR($$$GeneralError,"SalesTransaction INSERT失敗: SQLCODE="_SQLCODE)
        }

        // 進捗表示
        if (i # 10000 = 0) {
            write "  ",i," 件完了",!
        }
    }

    write "Demo.SalesTransaction データ投入完了",!
    return $$$OK
}

}
