/// IntegratedML 需要予測デモ（2026.1）
/// 販売実績データから日次売上を予測
/// AutoMLデフォルト vs カスタムML Configuration の比較
Class Demo.IntegratedML.DemandForecast Extends %RegisteredObject
{

ClassMethod Run()
{
    write "============================================================",!
    write " IntegratedML 需要予測デモ",!
    write " AutoMLデフォルト vs カスタムML Configurationの比較",!
    write "============================================================",!
    write !,"  IRISバージョン: ", $zversion,!!

    // --- 1. 日次集計テーブル作成 ---
    write "--- 1. 日次集計テーブル作成 ---",!
    do ..CreateDailySummary()

    // --- 2. デフォルト設定（%AutoML）でモデル訓練 ---
    write !,"--- 2. デフォルト設定（%AutoML）で訓練 ---",!
    do ##class(%SQL.Statement).%ExecDirect(,"SET ML CONFIGURATION %AutoML")
    do ##class(%SQL.Statement).%ExecDirect(,"DROP MODEL IF EXISTS DemandDefault")
    set stmt = ##class(%SQL.Statement).%New()
    set sc = stmt.%Prepare("CREATE MODEL DemandDefault PREDICTING (TotalAmount) FROM Demo.DailySales")
    do stmt.%Execute()
    set sc = stmt.%Prepare("TRAIN MODEL DemandDefault")
    set rs = stmt.%Execute()
    write "  TRAIN: SQLCODE=",rs.%SQLCODE,!
    set mae1 = ..CalcMAE("DemandDefault")
    do ..ShowSettings("DemandDefault")
    write "  MAE: ", $fn(mae1,"",0),!

    // --- 3. カスタムML Configurationを作成 ---
    write !,"--- 3. カスタムML Configurationの作成 ---",!
    write "  SQL: CREATE ML CONFIGURATION CustomDemandConfig",!
    write "         PROVIDER AutoML",!
    write "         USING {""modelname"":""DemandPredictor"",",!
    write "                ""pathtoregressors"":""/opt/iris/custom_models"",",!
    write "                ""iscmodelsdisabled"":1}",!
    do ##class(%SQL.Statement).%ExecDirect(,"DROP ML CONFIGURATION IF EXISTS CustomDemandConfig")
    set sc = stmt.%Prepare(
        "CREATE ML CONFIGURATION CustomDemandConfig PROVIDER AutoML "
        _"USING {""modelname"": ""DemandPredictor"", "
        _"""pathtoregressors"": ""/opt/iris/custom_models"", "
        _"""iscmodelsdisabled"": 1}")
    if 'sc write "  Prepareエラー: ",$system.Status.GetErrorText(sc),! quit
    set rs = stmt.%Execute()
    write "  CREATE ML CONFIGURATION: SQLCODE=",rs.%SQLCODE,!

    // --- 4. SET ML CONFIGURATION でカスタム設定に切り替え ---
    write !,"--- 4. SET ML CONFIGURATION CustomDemandConfig ---",!
    set sc = stmt.%Prepare("SET ML CONFIGURATION CustomDemandConfig")
    set rs = stmt.%Execute()
    write "  SET: SQLCODE=",rs.%SQLCODE,!

    // --- 5. カスタム設定で訓練 ---
    write !,"--- 5. カスタム設定で訓練 ---",!
    do ##class(%SQL.Statement).%ExecDirect(,"DROP MODEL IF EXISTS DemandCustom")
    set sc = stmt.%Prepare("CREATE MODEL DemandCustom PREDICTING (TotalAmount) FROM Demo.DailySales")
    do stmt.%Execute()
    set sc = stmt.%Prepare("TRAIN MODEL DemandCustom")
    set rs = stmt.%Execute()
    write "  TRAIN: SQLCODE=",rs.%SQLCODE,!
    set mae2 = ..CalcMAE("DemandCustom")
    do ..ShowSettings("DemandCustom")
    write "  MAE: ", $fn(mae2,"",0),!

    // --- 6. 比較 ---
    write !,"--- 6. 比較結果 ---",!
    write "  デフォルト（%AutoML）:           MAE = ", $fn(mae1,"",0),!
    write "  カスタム（CustomDemandConfig）:  MAE = ", $fn(mae2,"",0),!

    // --- 7. 予測サンプル ---
    write !,"--- 7. 予測サンプル（カスタム設定モデル） ---",!
    do ..ShowPredictions("DemandCustom")

    // --- 8. クリーンアップ ---
    write !,"--- 8. クリーンアップ ---",!
    do ##class(%SQL.Statement).%ExecDirect(,"SET ML CONFIGURATION %AutoML")
    do ##class(%SQL.Statement).%ExecDirect(,"DROP MODEL IF EXISTS DemandDefault")
    do ##class(%SQL.Statement).%ExecDirect(,"DROP MODEL IF EXISTS DemandCustom")
    do ##class(%SQL.Statement).%ExecDirect(,"DROP ML CONFIGURATION IF EXISTS CustomDemandConfig")
    do ##class(%SQL.Statement).%ExecDirect(,"DROP TABLE IF EXISTS Demo.DailySales")
    write "  完了",!

    write !,"============================================================",!
    write " ポイント:",!
    write "  - CREATE ML CONFIGURATION でカスタム設定を定義",!
    write "  - SET ML CONFIGURATION で設定を切り替え",!
    write "  - USING句のパラメータがTRAIN時にAutoMLに渡される",!
    write "  - SETTINGSカラムでパラメータの伝達を確認可能",!
    write "============================================================",!
}

ClassMethod CreateDailySummary()
{
    do ##class(%SQL.Statement).%ExecDirect(,"DROP TABLE IF EXISTS Demo.DailySales")
    do ##class(%SQL.Statement).%ExecDirect(,
        "CREATE TABLE Demo.DailySales ("
        _"ID INT AUTO_INCREMENT PRIMARY KEY, "
        _"SalesYear INT, SalesMonth INT, SalesDay INT, "
        _"DayOfWeek INT, ProductName VARCHAR(100), "
        _"TotalAmount DECIMAL(15,2), TransactionCount INT)")
    do ##class(%SQL.Statement).%ExecDirect(,
        "INSERT INTO Demo.DailySales "
        _"(SalesYear, SalesMonth, SalesDay, DayOfWeek, ProductName, TotalAmount, TransactionCount) "
        _"SELECT YEAR(TransactionDate), MONTH(TransactionDate), DAY(TransactionDate), "
        _"DAYOFWEEK(TransactionDate), ProductName, SUM(Amount), COUNT(*) "
        _"FROM Demo.SalesTransaction "
        _"GROUP BY YEAR(TransactionDate), MONTH(TransactionDate), "
        _"DAY(TransactionDate), DAYOFWEEK(TransactionDate), ProductName")
    set stmt = ##class(%SQL.Statement).%New()
    set sc = stmt.%Prepare("SELECT COUNT(*) FROM Demo.DailySales")
    set rs = stmt.%Execute()
    if rs.%Next() write "  ",rs.%GetData(1),"件の日次集計レコード",!
}

ClassMethod CalcMAE(modelName As %String) As %Double
{
    set stmt = ##class(%SQL.Statement).%New()
    set sc = stmt.%Prepare("SELECT AVG(ABS(TotalAmount - PREDICT("_modelName_"))) FROM Demo.DailySales")
    set rs = stmt.%Execute()
    if rs.%Next() return +rs.%GetData(1)
    return 0
}

ClassMethod ShowSettings(modelName As %String)
{
    set stmt = ##class(%SQL.Statement).%New()
    set sc = stmt.%Prepare("SELECT ML_CONFIGURATION_NAME, SETTINGS FROM INFORMATION_SCHEMA.ML_TRAINING_RUNS WHERE MODEL_NAME = '"_modelName_"'")
    set rs = stmt.%Execute()
    if rs.%Next() write "  Configuration: ",rs.%GetData(1),!,"  Settings: ",rs.%GetData(2),!
}

ClassMethod ShowPredictions(modelName As %String)
{
    set stmt = ##class(%SQL.Statement).%New()
    set sc = stmt.%Prepare(
        "SELECT TOP 10 ProductName, SalesYear, SalesMonth, SalesDay, "
        _"TotalAmount, PREDICT("_modelName_") AS Predicted "
        _"FROM Demo.DailySales ORDER BY SalesYear DESC, SalesMonth DESC, SalesDay DESC")
    set rs = stmt.%Execute()
    write "  商品    日付        実績        予測",!
    write "  -----  ----------  ----------  ----------",!
    for  quit:'rs.%Next()  write "  ",rs.%GetData(1),"  ",rs.%GetData(2),"/",rs.%GetData(3),"/",rs.%GetData(4),"  ",rs.%GetData(5),"  ",$fn(rs.%GetData(6),"",0),!
}

}
