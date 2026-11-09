#!/usr/bin/env bash
# JackSneider — Instalador desde GitHub
set -euo pipefail
KEY="${1:-}"
[[ -n "$KEY" ]] || { echo "[ERROR] Falta la KEY: bash install.sh TU_KEY"; exit 1; }
if [[ "$KEY" == "TU_KEY" ]]; then
    echo "[ERROR] No uses TU_KEY, pon tu clave real de MoviVIP."
    exit 1
fi
[[ $EUID -eq 0 ]] || { echo "[ERROR] root requerido"; exit 1; }

REPO="anonymousmasterpro1234-dot/JackSneider"
URL="https://github.com/$REPO/releases/latest/download/movivip-pro.tar.gz"
TMP="/tmp/movivip-pro.tar.gz"

echo "[*] Descargando instalador..."
curl -fsSL -o "$TMP" "$URL"

echo "[*] Extrayendo..."
cd /tmp && rm -rf movivip-pro && tar -xzf "$TMP"

echo "[*] Ejecutando deploy..."
cd /tmp/movivip-pro
export MV_KEY="$KEY"
bash deploy.sh
