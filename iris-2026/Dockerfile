FROM intersystems/iris-community:2026.1

USER root
RUN mkdir -p /home/irisowner/src
RUN chown -R irisowner:irisowner /home/irisowner/src

# PostgreSQL JDBCドライバ（Foreign Table デモ用）
ADD --chmod=644 https://jdbc.postgresql.org/download/postgresql-42.7.5.jar /usr/irissys/dev/java/lib/1.8/postgresql-42.7.5.jar

# IntegratedML AutoMLパッケージ
RUN python3 -m pip install \
    --index-url https://registry.intersystems.com/pypi/simple \
    --no-cache-dir \
    --target /usr/irissys/mgr/python \
    intersystems-iris-automl

USER irisowner

COPY --chown=irisowner:irisowner src /home/irisowner/src-build/
COPY iris-2026/iris.script /tmp/iris.script
COPY iris-2026/merge.cpf /tmp/merge.cpf
COPY iris-2026/init.script /tmp/init.script

RUN iris start IRIS quietly \
    && iris merge IRIS /tmp/merge.cpf \
    && iris session IRIS < /tmp/iris.script \
    && iris session IRIS < /tmp/init.script \
    && iris stop IRIS quietly
