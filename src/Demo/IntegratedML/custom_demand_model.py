"""
カスタムモデル: 需要予測（売上予測）
季節性とトレンドを考慮したGradientBoostingRegressor

AutoMLのデフォルト（Linear Regression等）では捉えにくい
非線形パターンや月別の季節性を学習する。
"""
from sklearn.ensemble import GradientBoostingRegressor
import math


def time_complexity_fn(N):
    return N * math.log10(N)


class IRISModel:
    def __init__(self, **kwargs):
        self.name = "custom_demand_model"

        self.model = GradientBoostingRegressor(
            n_estimators=200,
            max_depth=5,
            learning_rate=0.1,
            subsample=0.8,
            min_samples_split=5,
            random_state=kwargs.get('random_state', 42),
            verbose=kwargs.get('verbose', 0),
        )

        self.time_complexity_fn = time_complexity_fn
        self.model_type = "Gradient Boosting Demand"
        self.package = "sklearn"

        self.hastened_model = GradientBoostingRegressor(
            n_estimators=50,
            max_depth=3,
            learning_rate=0.2,
            random_state=kwargs.get('random_state', 42),
            verbose=kwargs.get('verbose', 0),
        )

        self.hastened_time_complexity_fn = time_complexity_fn
        self.hastened_model_type = "Gradient Boosting Demand"
        self.hastened_package = "sklearn"
