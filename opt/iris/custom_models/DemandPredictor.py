"""
カスタムモデル: 需要予測
GradientBoostingRegressorで非線形パターンを学習
"""
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
            min_samples_split=4,
            random_state=kwargs.get('random_state', 42),
            verbose=kwargs.get('verbose', 0),
        )

        self.time_complexity_fn = time_complexity_fn
        self.model_type = "Gradient Boosting Demand"
        self.package = "sklearn"

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
