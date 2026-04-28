#!/bin/bash
# ECC (P-256) と RSA (2048bit) の証明書を生成
# docker compose up 後に実行、または手動実行:
#   docker exec iris-2026 /opt/iris/generate-certs.sh

CERT_DIR=/opt/iris/certs
mkdir -p $CERT_DIR

echo "=== Generating ECC (P-256) certificate ==="
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 \
  -nodes -keyout $CERT_DIR/ecc-key.pem -out $CERT_DIR/ecc-cert.pem \
  -days 365 -subj "/CN=iris-ecc-demo" 2>/dev/null
echo "  ECC cert: $CERT_DIR/ecc-cert.pem"
echo "  ECC key:  $CERT_DIR/ecc-key.pem"

echo "=== Generating RSA (2048bit) certificate ==="
openssl req -x509 -newkey rsa:2048 \
  -nodes -keyout $CERT_DIR/rsa-key.pem -out $CERT_DIR/rsa-cert.pem \
  -days 365 -subj "/CN=iris-rsa-demo" 2>/dev/null
echo "  RSA cert: $CERT_DIR/rsa-cert.pem"
echo "  RSA key:  $CERT_DIR/rsa-key.pem"

echo "=== Key size comparison ==="
ECC_SIZE=$(wc -c < $CERT_DIR/ecc-key.pem)
RSA_SIZE=$(wc -c < $CERT_DIR/rsa-key.pem)
echo "  ECC key: ${ECC_SIZE} bytes"
echo "  RSA key: ${RSA_SIZE} bytes"

echo "=== Done ==="
