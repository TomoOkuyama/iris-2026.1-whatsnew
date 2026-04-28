"""
カスタムモデル例: 顧客離反予測（チャーン予測）
不均衡データに強いGradientBoostingClassifierを使用

AutoMLのデフォルトモデルでは不均衡データへの対応が不十分な場合に、
ドメイン知識に基づいてカスタムモデルを投入するケース。
"""
from sklearn.ensemble import GradientBoostingClassifier
import math


def time_complexity_fn(N):
    return N * math.log10(N)


class IRISModel:
    def __init__(self, **kwargs):
        self.name = "custom_churn_model"

        self.model = GradientBoostingClassifier(
            n_estimators=150,
            max_depth=4,
            learning_rate=0.1,
            min_samples_split=10,
            random_state=kwargs.get('random_state', 42),
            verbose=kwargs.get('verbose', 0),
        )

        self.time_complexity_fn = time_complexity_fn
        self.model_type = "Gradient Boosting Churn"
        self.package = "sklearn"

        self.hastened_model = GradientBoostingClassifier(
            n_estimators=50,
            max_depth=3,
            learning_rate=0.2,
            random_state=kwargs.get('random_state', 42),
            verbose=kwargs.get('verbose', 0),
        )

        self.hastened_time_complexity_fn = time_complexity_fn
        self.hastened_model_type = "Gradient Boosting Churn"
        self.hastened_package = "sklearn"
