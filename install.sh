#!/usr/bin/env bash
# JackSneider — Instalador desde GitHub
set -euo pipefail
KEY="${1:-}"
[[ -n "$KEY" ]] || { echo "[ERROR] Falta la KEY: bash install.sh TU_KEY"; exit 1; }
[[ $EUID -eq 0 ]] || { echo "[ERROR] root requerido"; exit 1; }

REPO="anonymousmasterpro1234-dot/JackSneider"
URL="https://github.com/$REPO/raw/main/movivip-pro.tar.gz"
TMP="/tmp/movivip-pro.tar.gz"

echo "[*] Descargando instalador..."
curl -fsSL -o "$TMP" "$URL"

echo "[*] Extrayendo..."
cd /tmp && rm -rf movivip-pro && tar -xzf "$TMP"

echo "[*] Ejecutando deploy..."
cd /tmp/movivip-pro
export MV_KEY="$KEY"
bash deploy.sh
