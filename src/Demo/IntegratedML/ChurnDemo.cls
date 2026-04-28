/// IntegratedML カスタムモデルデモ: 顧客離反予測（2026.1）
/// カスタムモデルなし/ありの精度比較
Class Demo.IntegratedML.ChurnDemo Extends %RegisteredObject
{

ClassMethod Run()
{
    write "============================================================",!
    write " IntegratedML カスタムモデルデモ: 顧客離反予測",!
    write " カスタムモデルなし vs ありの精度比較",!
    write "============================================================",!
    write !,"  IRISバージョン: ", $zversion,!!

    // --- 1. デモデータ作成 ---
    write "--- 1. デモデータ作成（顧客1,000件） ---",!
    do ..CreateChurnData()

    // --- 2. カスタムモデルなしで訓練・予測 ---
    write !,"--- 2. カスタムモデルなし（AutoMLデフォルトのみ） ---",!
    do ..RemoveCustomModel()
    set acc1 = ..TrainAndPredict("ChurnDefault")
    write "  精度: ", $fn(acc1,"",1), "%",!

    // --- 3. カスタムモデルありで訓練・予測 ---
    write !,"--- 3. カスタムモデルあり（GradientBoosting追加） ---",!
    do ..InstallCustomModel()
    set acc2 = ..TrainAndPredict("ChurnCustom")
    write "  精度: ", $fn(acc2,"",1), "%",!

    // --- 4. 比較 ---
    write !,"--- 4. 比較結果 ---",!
    write "  AutoMLデフォルトのみ: ", $fn(acc1,"",1), "%",!
    write "  カスタムモデル追加:   ", $fn(acc2,"",1), "%",!
    if acc2 > acc1 {
        write "  → カスタムモデル追加で ", $fn(acc2-acc1,"",1), "ポイント改善",!
    } elseif acc1 > acc2 {
        write "  → AutoMLデフォルトが上回りました（", $fn(acc1-acc2,"",1), "ポイント差）",!
    } else {
        write "  → 同等の精度",!
    }

    // --- 5. クリーンアップ ---
    write !,"--- 5. クリーンアップ ---",!
    do ##class(%SQL.Statement).%ExecDirect(,"DROP MODEL IF EXISTS ChurnDefault")
    do ##class(%SQL.Statement).%ExecDirect(,"DROP MODEL IF EXISTS ChurnCustom")
    do ..Cleanup()
    write "  完了",!

    write !,"============================================================",!
    write " ポイント:",!
    write "  - カスタムモデル（.pyファイル）を配置するだけで",!
    write "    AutoMLの候補に自動追加される",!
    write "  - TRAIN MODELが全候補から最適なものを自動選択",!
    write "  - ドメイン知識に基づくモデルを投入して精度改善が可能",!
    write "============================================================",!
}

/// モデルを訓練して精度を返す
ClassMethod TrainAndPredict(modelName As %String) As %Double
{
    set stmt = ##class(%SQL.Statement).%New()
    do ##class(%SQL.Statement).%ExecDirect(,"DROP MODEL IF EXISTS "_modelName)

    // CREATE MODEL
    set sc = stmt.%Prepare("CREATE MODEL "_modelName_" PREDICTING (Churned) FROM Demo.Customer")
    if $$$ISERR(sc) write "  CREATE MODEL エラー",! return 0
    do stmt.%Execute()
    write "  CREATE MODEL: OK",!

    // TRAIN MODEL
    set sc = stmt.%Prepare("TRAIN MODEL "_modelName)
    set rs = stmt.%Execute()
    if rs.%SQLCODE < 0 write "  TRAIN MODEL エラー: ",rs.%Message,! return 0
    write "  TRAIN MODEL: OK",!

    // 選択されたモデル
    set sc = stmt.%Prepare("SELECT TRAINED_MODEL_NAME FROM INFORMATION_SCHEMA.ML_TRAINED_MODELS WHERE MODEL_NAME = '"_modelName_"'")
    set rs = stmt.%Execute()
    if rs.%Next() write "  選択モデル: ", rs.%GetData(1),!

    // 精度計算
    set sc = stmt.%Prepare("SELECT COUNT(*) Total, SUM(CASE WHEN Churned = PREDICT("_modelName_") THEN 1 ELSE 0 END) Correct FROM Demo.Customer")
    set rs = stmt.%Execute()
    if rs.%Next() {
        set total = rs.%GetData(1)
        set correct = rs.%GetData(2)
        if total > 0 return correct / total * 100
    }
    return 0
}

/// カスタムモデルを一時的に除外
ClassMethod RemoveCustomModel()
{
    set path = "/home/irisowner/irisdata/mgr/python/iris_automl/Classifiers/custom_churn_model.py"
    if ##class(%File).Exists(path) do $zf(-1,"mv "_path_" "_path_".bak")
}

/// カスタムモデルを戻す
ClassMethod InstallCustomModel()
{
    set path = "/home/irisowner/irisdata/mgr/python/iris_automl/Classifiers/custom_churn_model.py"
    set bak = path_".bak"
    if ##class(%File).Exists(bak) do $zf(-1,"mv "_bak_" "_path)
    if '##class(%File).Exists(path) do $zf(-1,"cp /home/irisowner/src/Demo/IntegratedML/custom_churn_model.py "_path)
}

/// 顧客離反デモデータ作成
ClassMethod CreateChurnData()
{
    do ##class(%SQL.Statement).%ExecDirect(,"DROP TABLE IF EXISTS Demo.Customer")
    do ##class(%SQL.Statement).%ExecDirect(,
        "CREATE TABLE Demo.Customer ("
        _"ID INT AUTO_INCREMENT PRIMARY KEY, "
        _"CustomerName VARCHAR(100), "
        _"ContractMonths INT, "
        _"MonthlyCharge INT, "
        _"SupportCalls INT, "
        _"Churned INT)")
    set stmt = ##class(%SQL.Statement).%New()
    set sc = stmt.%Prepare("INSERT INTO Demo.Customer (CustomerName, ContractMonths, MonthlyCharge, SupportCalls, Churned) VALUES (?,?,?,?,?)")
    for i=1:1:1000 {
        set months = $random(48) + 1
        set charge = 3000 + $random(12000)
        set calls = $random(10)
        set score = (48 - months) / 48 * 30 + calls / 10 * 50 + charge / 15000 * 20
        set churned = $select(($random(100) < score):1, 1:0)
        do stmt.%Execute("Cust"_$translate($justify(i,4)," ","0"), months, charge, calls, churned)
    }
    set sc2 = ##class(%SQL.Statement).%New()
    set sc = sc2.%Prepare("SELECT COUNT(*) Total, SUM(Churned) Churned FROM Demo.Customer")
    set rs = sc2.%Execute()
    if rs.%Next() write "  ",rs.%GetData(1),"件（離反: ",rs.%GetData(2),"件 = ",$fn(rs.%GetData(2)/rs.%GetData(1)*100,"",1),"%）",!
}

/// テーブル削除
ClassMethod Cleanup()
{
    do ##class(%SQL.Statement).%ExecDirect(,"DROP TABLE IF EXISTS Demo.Customer")
}

}
