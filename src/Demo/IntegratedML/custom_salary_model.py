"""
IntegratedMLカスタムモデルの例（2026.1）
GradientBoostingRegressorを使った給与予測モデル

このファイルを iris_automl/Regressors/ に配置すると、
IntegratedMLのAutoMLが自動的にこのモデルを候補として使用します。
"""
from sklearn.ensemble import GradientBoostingRegressor
import math


def time_complexity_fn(N):
    return N * math.log10(N)


class IRISModel:
    def __init__(self, **kwargs):
        self.name = "custom_salary_model"

        self.model = GradientBoostingRegressor(
            n_estimators=200,
            max_depth=4,
            learning_rate=0.1,
            random_state=kwargs.get('random_state', 42),
            verbose=kwargs.get('verbose', 0),
        )

        self.time_complexity_fn = time_complexity_fn
        self.model_type = "Gradient Boosting"
        self.package = "sklearn"

        # hastened version (faster training)
        self.hastened_model = GradientBoostingRegressor(
            n_estimators=50,
            max_depth=3,
            learning_rate=0.2,
            random_state=kwargs.get('random_state', 42),
            verbose=kwargs.get('verbose', 0),
        )

        self.hastened_time_complexity_fn = time_complexity_fn
        self.hastened_model_type = "Gradient Boosting"
        self.hastened_package = "sklearn"
