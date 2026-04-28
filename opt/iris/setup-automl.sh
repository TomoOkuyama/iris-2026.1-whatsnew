#!/bin/bash
# IntegratedML AutoMLパッケージとカスタムモデルをdurable directoryにセットアップ
# docker compose up後に実行:
#   docker exec iris-2026 /opt/iris/setup-automl.sh

SRC=/usr/irissys/mgr/python
DST=/home/irisowner/irisdata/mgr/python

# AutoMLパッケージをコピー
if [ -d "$SRC/iris_automl" ]; then
    mkdir -p "$DST"
    cp -r "$SRC"/* "$DST"/
    echo "AutoML packages copied to $DST"
else
    echo "AutoML packages not found in $SRC"
    exit 1
fi

# カスタムモデルをコピー
CUSTOM_SRC=/home/irisowner/src/Demo/IntegratedML
if [ -f "$CUSTOM_SRC/custom_churn_model.py" ]; then
    cp "$CUSTOM_SRC/custom_churn_model.py" "$DST/iris_automl/Classifiers/"
    echo "Custom churn model copied to Classifiers/"
fi
if [ -f "$CUSTOM_SRC/custom_salary_model.py" ]; then
    cp "$CUSTOM_SRC/custom_salary_model.py" "$DST/iris_automl/Regressors/"
    echo "Custom salary model copied to Regressors/"
fi
if [ -f "$CUSTOM_SRC/custom_demand_model.py" ]; then
    cp "$CUSTOM_SRC/custom_demand_model.py" "$DST/iris_automl/Regressors/"
    echo "Custom demand model copied to Regressors/"
fi

echo "Setup complete"
