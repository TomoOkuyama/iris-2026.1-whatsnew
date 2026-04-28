/// IntegratedMLカスタムモデルデモ（2026.1で追加）
/// SQLだけで機械学習。データサイエンティストでなくても、SQLを知っていればMLモデルが作れる。
/// 2026.1ではカスタムPythonモデルも登録可能に。
Class Demo.IntegratedML.CustomModel Extends %RegisteredObject
{

ClassMethod Run()
{
    write "============================================================",!
    write " IntegratedML カスタムモデルデモ（2026.1～）",!
    write " SQLだけで機械学習 — カスタムPythonモデルも登録可能に",!
    write "============================================================",!

    try {
        // --- 1. CREATE MODEL でモデル定義 ---
        write !,"--- 1. CREATE MODEL: 給与予測モデルの定義 ---",!
        write "  Demo.Personテーブルから給与(Salary)を予測するモデルを作成",!

        set stmt = ##class(%SQL.Statement).%New()
        set sql = "CREATE MODEL DemoSalaryModel PREDICTING (Salary) FROM Demo.Person"
        set sc = stmt.%Prepare(sql)
        if $$$ISERR(sc) {
            write !,"  ※ IntegratedMLはこのバージョン/環境では非対応です",!
            write "  （IRIS 2026.1以降 + IntegratedMLライセンスが必要）",!
            do ..ShowConcept()
            return
        }

        set rs = stmt.%Execute()
        if rs.%SQLCODE < 0 {
            write "  ※ CREATE MODELの実行でエラー: SQLCODE=",rs.%SQLCODE,!
            write "  メッセージ: ",rs.%Message,!
            write !,"  ※ IntegratedMLはこのバージョン/環境では非対応です",!
            do ..ShowConcept()
            return
        }
        write "  → モデル DemoSalaryModel を作成しました",!

        // --- 2. TRAIN MODEL で訓練 ---
        write !,"--- 2. TRAIN MODEL: モデルの訓練 ---",!
        write "  Demo.Personのデータを使ってモデルを訓練します",!

        set stmtTrain = ##class(%SQL.Statement).%New()
        set sqlTrain = "TRAIN MODEL DemoSalaryModel"
        set sc = stmtTrain.%Prepare(sqlTrain)
        if $$$ISERR(sc) {
            write "  ※ TRAIN MODELの準備でエラーが発生しました",!
            do $system.Status.DisplayError(sc)
            do ..Cleanup()
            return
        }

        set rs = stmtTrain.%Execute()
        if rs.%SQLCODE < 0 {
            write "  ※ TRAIN MODELの実行でエラー: SQLCODE=",rs.%SQLCODE,!
            write "  メッセージ: ",rs.%Message,!
            do ..Cleanup()
            return
        }
        write "  → モデルの訓練が完了しました",!

        // --- 3. PREDICT() で予測実行 ---
        write !,"--- 3. PREDICT(): 実際の給与 vs 予測給与（TOP 10）---",!

        set stmtPredict = ##class(%SQL.Statement).%New()
        set sqlPredict = "SELECT TOP 10 Name, Age, City, Department, "
                         _"Salary AS ActualSalary, "
                         _"PREDICT(DemoSalaryModel) AS PredictedSalary "
                         _"FROM Demo.Person"
        set sc = stmtPredict.%Prepare(sqlPredict)
        if $$$ISERR(sc) {
            write "  ※ PREDICTの準備でエラーが発生しました",!
            do $system.Status.DisplayError(sc)
            do ..Cleanup()
            return
        }

        set rs = stmtPredict.%Execute()
        if rs.%SQLCODE < 0 {
            write "  ※ PREDICTの実行でエラー: SQLCODE=",rs.%SQLCODE,!
            write "  メッセージ: ",rs.%Message,!
            do ..Cleanup()
            return
        }

        // ヘッダー行
        write "  ",$$PadRight("名前", 20),$$PadRight("年齢", 6),$$PadRight("都市", 12),$$PadRight("部署", 12),$$PadRight("実際給与", 12),"予測給与",!
        write "  ",$$Repeat("-", 74),!

        set count = 0
        while rs.%Next() {
            set count = count + 1
            write "  "
            write $$PadRight(rs.Name, 20)
            write $$PadRight(rs.Age, 6)
            write $$PadRight(rs.City, 12)
            write $$PadRight(rs.Department, 12)
            write $$PadRight($justify(rs.ActualSalary, 1, 0), 12)
            write $justify(rs.PredictedSalary, 1, 0),!
        }
        write "  → ",count,"件の予測結果を表示",!

        // --- 4. モデル情報の表示 ---
        write !,"--- 4. モデル情報の確認 ---",!
        do ..ShowModelInfo()

        // --- 5. クリーンアップ ---
        write !,"--- 5. クリーンアップ ---",!
        do ..Cleanup()
        write "  → DROP MODEL DemoSalaryModel 完了",!

    } catch ex {
        write !,"  ※ 予期しないエラーが発生しました: ",ex.DisplayString(),!
        // エラー発生時もクリーンアップを試みる
        do ..Cleanup()
    }

    write !,"============================================================",!
    write " まとめ:",!
    write "  - CREATE MODEL / TRAIN MODEL / PREDICT() — すべてSQL",!
    write "  - データサイエンティストでなくてもMLモデルが構築可能",!
    write "  - 2026.1ではカスタムPythonモデルの登録にも対応",!
    write "  - 既存のSQLスキルだけで機械学習をビジネスに活用",!
    write "============================================================",!

    quit

    // --- ローカル関数 ---
PadRight(str, width)
    set len = $length(str)
    if len >= width quit str
    quit str_$justify("", width - len)

Repeat(char, count)
    set result = ""
    for i=1:1:count set result = result_char
    quit result
}

/// モデル情報を INFORMATION_SCHEMA から表示
ClassMethod ShowModelInfo() [ Private ]
{
    set stmt = ##class(%SQL.Statement).%New()
    set sql = "SELECT * FROM INFORMATION_SCHEMA.ML_MODELS WHERE MODEL_NAME = 'DemoSalaryModel'"
    set sc = stmt.%Prepare(sql)
    if $$$ISERR(sc) {
        write "  ※ モデル情報の取得でエラーが発生しました",!
        return
    }

    set rs = stmt.%Execute()
    if rs.%SQLCODE < 0 {
        write "  ※ モデル情報クエリのエラー: SQLCODE=",rs.%SQLCODE,!
        return
    }

    if rs.%Next() {
        set md = rs.%GetMetadata()
        set colCount = md.columns.Count()
        for i=1:1:colCount {
            set colName = md.columns.GetAt(i).colName
            set colValue = rs.%GetData(i)
            write "  ",colName,": ",colValue,!
        }
    } else {
        write "  ※ モデル情報が見つかりませんでした",!
    }
}

/// モデルのクリーンアップ（DROP MODEL）
ClassMethod Cleanup() [ Private ]
{
    try {
        set stmt = ##class(%SQL.Statement).%New()
        set sql = "DROP MODEL DemoSalaryModel"
        set sc = stmt.%Prepare(sql)
        if $$$ISOK(sc) {
            set rs = stmt.%Execute()
        }
    } catch ex {
        // クリーンアップ中のエラーは無視
    }
}

/// IntegratedML非対応環境向けのコンセプト説明
ClassMethod ShowConcept() [ Private ]
{
    write !,"  === IntegratedML コンセプト紹介 ===",!
    write !,"  IntegratedMLを使えば、SQLだけで機械学習が可能です:",!
    write !,"  1. モデル定義:",!
    write "     CREATE MODEL SalaryModel PREDICTING (Salary) FROM Demo.Person",!
    write !,"  2. モデル訓練:",!
    write "     TRAIN MODEL SalaryModel",!
    write !,"  3. 予測実行:",!
    write "     SELECT Name, Salary, PREDICT(SalaryModel) AS Predicted",!
    write "     FROM Demo.Person",!
    write !,"  4. 2026.1の新機能 — カスタムPythonモデル登録:",!
    write "     CREATE MODEL MyModel PREDICTING (Target)",!
    write "       USING {""model"": ""my_custom_sklearn_model""}",!
    write "     → scikit-learn等のPythonモデルをSQLから直接利用可能",!
    write !,"  ※ IntegratedMLの利用にはライセンスと環境設定が必要です",!
}

}
