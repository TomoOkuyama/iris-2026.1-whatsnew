#!/bin/bash
# Keycloak起動後にmasterレルムとiris-demoレルムのSSL要件を無効化
# docker compose up後に実行: docker exec demo-keycloak /opt/keycloak/data/import/disable-ssl.sh

echo "Disabling SSL requirement for master and iris-demo realms..."

/opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user admin \
  --password admin

/opt/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE
/opt/keycloak/bin/kcadm.sh update realms/iris-demo -s sslRequired=NONE

echo "SSL requirement disabled for both realms."
