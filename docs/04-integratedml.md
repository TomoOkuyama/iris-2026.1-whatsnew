# IntegratedMLカスタムモデル

## 概要

「自分で作ったPythonモデルを、SQLからそのまま呼び出したい」というニーズに、IRIS 2026.1が応えます。IntegratedMLで**カスタムPythonモデルの登録**がサポートされ、scikit-learn互換のモデルを組み込んで、SQLの`PREDICT()`関数から利用できるようになりました。データをIRISの外へ持ち出す必要はなく、訓練も予測も**すべてDB内で完結**します。AutoMLの組み込みモデルを無効化して自作モデルのみを使うことも、両方を候補に並べて自動選択させることも可能です。

> **注:** IntegratedMLの基本機能（CREATE MODEL / TRAIN MODEL / PREDICT()）は以前のバージョンで導入済みです。本ドキュメントでは2025.3以降で追加されたカスタムモデル機能に焦点を当てています。
>
> 公式ドキュメント（[Using IntegratedML — Custom Models](https://docs.intersystems.com/iris20261/csp/docbook/DocBook.UI.Page.cls?KEY=GIML_custom)）は2026.1時点でページは存在するものの内容が未整備で、実装の詳細は [intersystems-community/integratedml-custom-models](https://github.com/intersystems-community/integratedml-custom-models) のリポジトリが一次情報源となっています。

---

### 2025.3までと2026.1以降の違い

| 項目 | 2025.3まで | 2026.1以降 |
|------|----------|----------|
| 使えるモデル | AutoMLの組み込みモデルのみ | 組み込み + **カスタムPythonモデル** |
| アルゴリズム追加 | 不可 | Pythonファイルを配置するだけ |
| ドメイン知識の反映 | パラメータ調整のみ | 専用モデルを自作して投入可能 |
| 組み込みモデルの無効化 | 不可 | `iscmodelsdisabled:1`で無効化可能 |
| SQLワークフロー | CREATE → TRAIN → PREDICT | **同じ**（コード変更不要） |

---

### 基本的なIntegratedMLワークフロー

最初に、IntegratedMLの基本的な流れを確認しておきましょう。CREATE MODEL → TRAIN MODEL → PREDICT という3ステップが、すべてSQLだけで完結します。下のデモクラスを実行すると、一連の動作を確認できます:

```objectscript
do ##class(Demo.IntegratedML.CustomModel).Run()
```

中身は`Demo.Person`テーブルを題材にしたシンプルな予測デモです。次のような標準SQLが順に実行され、予測結果が表示されます。これだけの記述でモデルが動作する点を、まず確認してみてください:

```sql
-- 1. モデル定義
CREATE MODEL DemoSalaryModel PREDICTING (Salary) FROM Demo.Person

-- 2. 訓練
TRAIN MODEL DemoSalaryModel

-- 3. 予測
SELECT Name, Age, Salary AS Actual, PREDICT(DemoSalaryModel) AS Predicted
FROM Demo.Person
```

---

### カスタムモデルの書き方

ここからが本題です。自作モデルは`IRISModel`という名前のクラスとして実装し、Pythonファイルとして配置します。配置先は、後述の`CREATE ML CONFIGURATION`の`pathtoregressors`（回帰）または`pathtoclassifiers`（分類）で指定します。複雑な登録手続きは不要で、決まった形のクラスを決まった場所に置けば、IRIS側で自動的に認識されます。

```python
# DemandPredictor.py — 需要予測用カスタムモデル
from sklearn.ensemble import GradientBoostingRegressor
import math


def time_complexity_fn(N):
    return N * math.log10(N)


class IRISModel:
    def __init__(self, **kwargs):
        self.name = "DemandPredictor"

        self.model = GradientBoostingRegressor(
            n_estimators=300,
            max_depth=5,
            learning_rate=0.05,
            subsample=0.9,
            random_state=kwargs.get('random_state', 42),
            verbose=kwargs.get('verbose', 0),
        )

        self.time_complexity_fn = time_complexity_fn
        self.model_type = "Gradient Boosting Demand"
        self.package = "sklearn"

        # hastened version（時間制約下で使われる高速版）
        self.hastened_model = GradientBoostingRegressor(
            n_estimators=100,
            max_depth=4,
            learning_rate=0.1,
            random_state=kwargs.get('random_state', 42),
            verbose=kwargs.get('verbose', 0),
        )

        self.hastened_time_complexity_fn = time_complexity_fn
        self.hastened_model_type = "Gradient Boosting Demand"
        self.hastened_package = "sklearn"
```

**ポイント:**
- `IRISModel`という固定クラス名を使う
- `self.model` にscikit-learn互換モデルを設定
- `self.name` / `self.model_type` / `self.package` でメタ情報を設定
- `self.hastened_model` は時間制約下で使われる軽量版（必須）
- `fit()` / `predict()` はscikit-learnモデルが持っているのでラッパー不要

---

### カスタムモデルを強制的に使う（CREATE ML CONFIGURATION）

ただし、ファイルを配置しただけでは、自作モデルはあくまで候補のひとつにすぎません。組み込みモデル（`isc_linear_regression`、`isc_xgb`等）と比較対象になり、自動選択で選ばれない場合もあります。自作モデルが採用されない事態を避け、**自作モデルのみを使用する**には、`CREATE ML CONFIGURATION`で専用の設定を用意します。

```sql
-- 1. カスタム設定を作成（AutoML組み込みモデルを無効化）
CREATE ML CONFIGURATION CustomDemandConfig
PROVIDER AutoML
USING {
    "modelname": "DemandPredictor",
    "pathtoregressors": "/opt/iris/custom_models",
    "iscmodelsdisabled": 1
}

-- 2. 設定を切り替え
SET ML CONFIGURATION CustomDemandConfig

-- 3. モデル定義・訓練（カスタム設定で実行される）
CREATE MODEL DemandCustom PREDICTING (TotalAmount) FROM Demo.DailySales
TRAIN MODEL DemandCustom

-- 4. 予測
SELECT ProductName, TotalAmount, PREDICT(DemandCustom) AS Predicted
FROM Demo.DailySales

-- 5. デフォルトに戻す
SET ML CONFIGURATION %AutoML
```

**USING句の主なパラメータ:**

| パラメータ | 説明 |
|-----------|------|
| `modelname` | カスタムモデルのモジュール名（ファイル名からpyを除いたもの） |
| `pathtoregressors` | 回帰カスタムモデルの配置ディレクトリ |
| `pathtoclassifiers` | 分類カスタムモデルの配置ディレクトリ |
| `iscmodelsdisabled` | 1で組み込みモデル（`isc_*`）を除外 |
| `user_params` | カスタムモデルに渡す追加パラメータ（JSON） |

> **参考:** 公式リポジトリ（[intersystems-community/integratedml-custom-models](https://github.com/intersystems-community/integratedml-custom-models)）のデモではアンダースコアあり形式（`model_name`、`path_to_classifiers`）を使用しています。本デモはアンダースコアなし形式で動作確認済みです。

---

### 需要予測デモ: AutoMLデフォルト vs カスタムモデル

ここからは実践的なシナリオです。販売実績データ（Demo.SalesTransaction 50,000件）を日次集計し、商品別の売上を予測します。AutoMLにすべて任せたデフォルト設定と、自作のカスタムモデル（GradientBoosting）を用いた設定の両方を訓練し、結果を並べて比較してみましょう。

> **事前準備:** AutoMLパッケージとカスタムモデルファイルのセットアップが必要です。デモ環境では初回起動時に `/opt/iris/setup-automl.sh` を実行してください。

#### 実行コマンド

```objectscript
do ##class(Demo.IntegratedML.DemandForecast).Run()
```

#### 実行結果

```
--- 2. デフォルト設定（%AutoML）で訓練 ---
  Configuration: %AutoML
  MAE: 342254

--- 5. カスタム設定で訓練 ---
  Configuration: CustomDemandConfig
  Settings: modelname:DemandPredictor, pathtoregressors:/opt/iris/custom_models, iscmodelsdisabled:1
  MAE: 341779

--- 6. 比較結果 ---
  デフォルト（%AutoML）:           MAE = 342254
  カスタム（CustomDemandConfig）:  MAE = 341779
```

> **MAEの差について:** この規模のデータセットでは、両者の精度差はごくわずかです。ただし、このデモで確認したいのは**精度の優劣ではありません**。重要なのは、`iscmodelsdisabled:1`という指定どおりにカスタムモデルが確実に選択されているという点です。

#### 訓練ログで「カスタムモデルが使われた」ことを確認

設定が反映されているかは、訓練ログから確認できます。`INFORMATION_SCHEMA.ML_TRAINING_RUNS`のLOGカラムを参照してみましょう。組み込みモデルが除外され、カスタムモデルのみが使用された経緯がそのまま記録されています:

```sql
SELECT LOG FROM INFORMATION_SCHEMA.ML_TRAINING_RUNS
WHERE MODEL_NAME = 'DemandCustom'
```

```
Evaluating as a Regression model
Imported module isc_xgb.
Not creating an instance of isc-xgb as isc_models_disabled is set to True
Imported module isc_linear_regression.
Not creating an instance of isc_linear_regression as isc_models_disabled is set to True
Imported module DemandPredictor.
Created an instance of IRISModel from DemandPredictor
  trying DemandPredictor
classifier: DemandPredictor scored a mean squared error of ...
```

→ `isc_*`モデルは`isc_models_disabled is set to True`の行とともに順に除外され、最後に残った`DemandPredictor`のみが評価されています。設定が指定どおりに反映されていることが、ログから読み取れます。

---

### 活用シーン

- **需要予測**: 蓄積された販売実績から、SKU単位の翌週の売上をSQLだけで算出できます。発注担当者は通常のクエリと同じ感覚で予測値を取得できます
- **顧客離反予測**: CRMに蓄積されたデータから、解約の可能性が高い顧客を抽出できます。離反者が少なく偏ったデータでも、不均衡データに対応した自作モデルを用いることで取りこぼしを抑えられます
- **不正検知**: 不審な取引が発生したタイミングで、トランザクション内でリアルタイムにスコアリングし、アラートにつなげられます
- **ドメイン固有のモデル**: 自社や業界に特化した独自アルゴリズムを、既存のSQLワークフローへそのまま組み込めます。アプリケーション側のコードを変更する必要はありません
