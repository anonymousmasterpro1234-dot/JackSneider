#!/usr/bin/env bash
set -euo pipefail
KEY="${1:-}"
[[ -n "$KEY" ]] || { echo "[ERROR] Falta la KEY: bash install.sh TU_KEY"; exit 1; }
if [[ "$KEY" == "TU_KEY" ]]; then
    echo "[ERROR] No uses TU_KEY, pon tu clave real."
    exit 1
fi
[[ $EUID -eq 0 ]] || { echo "[ERROR] root requerido"; exit 1; }

REPO="anonymousmasterpro1234-dot/JackSneider"
URL="https://github.com/$REPO/releases/latest/download/movivip-pro.tar.gz"
TMP="/tmp/movivip-pro.tar.gz"

echo "[*] Descargando instalador base..."
curl -fsSL -o "$TMP" "$URL"

echo "[*] Extrayendo..."
cd /tmp && rm -rf movivip-pro && tar -xzf "$TMP"

echo "[*] Ejecutando deploy..."
cd /tmp/movivip-pro
export MV_KEY="$KEY"
bash deploy.sh

echo "[*] Aplicando parches de herramientas (CloudFront, Cloudflare, Banner)..."
mkdir -p /etc/movivip/herramientas /etc/movivip/usuarios

# ── PARCHES DE CLOUDFRONT ──
cat > /etc/movivip/herramientas/cloudfront.sh << 'CF_EOF'
#!/bin/bash
G='\033[0;32m'; R='\033[0;31m'; C='\033[0;36m'; Y='\033[1;33m'; N='\033[0m'
CONF="/etc/movivip/cloudfront_aws.conf"
if ! command -v aws &>/dev/null; then
    echo -e "${Y}Instalando AWS CLI...${N}"
    apt-get update -y -q >/dev/null 2>&1
    apt-get install -y -q awscli >/dev/null 2>&1 || pip3 install awscli >/dev/null 2>&1
fi
mostrar_menu() {
    clear
    echo -e "${C}─── Administración de distribuciones CloudFront ───${N}"
    if [ -f "$CONF" ] && [ -s "$CONF" ]; then echo -e "${G}✅ AWS · Credenciales configuradas${N}"; else echo -e "${R}⚠️ AWS · Pendientes${N}"; fi
    echo -e "1 Listar distribuciones"
    echo -e "2 Ver distribución"
    echo -e "3 Cambiar dominio de origen"
    echo -e "4 Agregar o quitar alias"
    echo -e "5 Crear distribución nueva"
    echo -e "6 Credenciales AWS"
    echo -e "7 Ayuda AWS"
    echo -e "0 Volver"
}
cargar_aws() { [ -f "$CONF" ] && source "$CONF"; }
while true; do
    mostrar_menu
    read -p "Opción [0]: " op
    case $op in
        1) cargar_aws; clear; aws cloudfront list-distributions --query "DistributionList.Items[*].[Id,DomainName,Status]" --output table 2>&1 | head -30; read -p "Enter..."; ;;
        2) cargar_aws; clear; read -p "ID: " d; aws cloudfront get-distribution --id "$d" 2>&1 | head -30; read -p "Enter..."; ;;
        3|4|5) echo "Usa la consola de AWS para esta acción."; sleep 2 ;;
        6) clear; read -p "Access Key ID: " ak; read -p "Secret: " sk; read -p "Región (us-east-1): " rg; echo "export AWS_ACCESS_KEY_ID=$ak" > "$CONF"; echo "export AWS_SECRET_ACCESS_KEY=$sk" >> "$CONF"; echo "export AWS_DEFAULT_REGION=${rg:-us-east-1}" >> "$CONF"; chmod 600 "$CONF"; ;;
        7) clear; echo "Ve a https://console.aws.amazon.com/iam/"; read -p "Enter..."; ;;
        0) exit 0 ;;
    esac
done
CF_EOF
chmod +x /etc/movivip/herramientas/cloudfront.sh

# ── PARCHES DE CLOUDFLARE ──
cat > /etc/movivip/herramientas/cloudflare.sh << 'CFL_EOF'
#!/bin/bash
G='\033[0;32m'; R='\033[0;31m'; C='\033[0;36m'; Y='\033[1;33m'; N='\033[0m'
CONF="/etc/movivip/cloudflare_api.conf"
mostrar_menu() {
    clear
    echo -e "${C}─── Administración de Cloudflare ───${N}"
    if [ -f "$CONF" ] && [ -s "$CONF" ]; then echo -e "${G}✅ Cloudflare · Credenciales configuradas${N}"; else echo -e "${R}⚠️ Cloudflare · Pendientes${N}"; fi
    echo -e "1 Listar zonas DNS"
    echo -e "2 Ver registros DNS"
    echo -e "3 Crear registro DNS"
    echo -e "4 Eliminar registro DNS"
    echo -e "5 Estado de la zona"
    echo -e "6 Credenciales Cloudflare"
    echo -e "7 Ayuda Token"
    echo -e "0 Volver"
}
cargar_cf() { [ -f "$CONF" ] && source "$CONF"; }
cf_api() { curl -s -X GET "https://api.cloudflare.com/client/v4/$1" -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json"; }
while true; do
    mostrar_menu
    read -p "Opción [0]: " op
    case $op in
        1) cargar_cf; clear; cf_api "zones" | jq -r '.result[] | "\(.id)  \(.name)  \(.status)"' 2>/dev/null; read -p "Enter..."; ;;
        2) cargar_cf; clear; read -p "ID Zona: " z; cf_api "zones/$z/dns_records" | jq -r '.result[] | "\(.type)  \(.name)  \(.content)"' 2>/dev/null; read -p "Enter..."; ;;
        3) cargar_cf; clear; read -p "ID Zona: " z; read -p "Tipo: " t; read -p "Nombre: " n; read -p "Contenido: " c; curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$z/dns_records" -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json" --data "{\"type\":\"$t\",\"name\":\"$n\",\"content\":\"$c\",\"ttl\":1}" >/dev/null; echo "✅ Registro creado."; read -p "Enter..."; ;;
        4) cargar_cf; clear; read -p "ID Zona: " z; read -p "ID Registro: " r; curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$z/dns_records/$r" -H "Authorization: Bearer $CF_TOKEN" >/dev/null; echo "✅ Eliminado."; read -p "Enter..."; ;;
        5) cargar_cf; clear; read -p "ID Zona: " z; cf_api "zones/$z" | jq -r '.result | "Dominio: \(.name) Estado: \(.status)"' 2>/dev/null; read -p "Enter..."; ;;
        6) clear; read -p "Token: " tk; echo "export CF_TOKEN=$tk" > "$CONF"; chmod 600 "$CONF"; ;;
        7) clear; echo "Ve a https://dash.cloudflare.com/profile/api-tokens"; read -p "Enter..."; ;;
        0) exit 0 ;;
    esac
done
CFL_EOF
chmod +x /etc/movivip/herramientas/cloudflare.sh

# ── PARCHES DE BANNER SSH ──
cat > /etc/movivip/usuarios/banner.sh << 'BN_EOF'
#!/bin/bash
G='\033[0;32m'; R='\033[0;31m'; C='\033[0;36m'; Y='\033[1;33m'; N='\033[0m'
BANNER_FILE="/etc/movivip/banner.conf"
SELLO_FILE="/etc/movivip/banner_sello.conf"

while true; do
    clear
    echo -e "${C}─────────────────────────────────────────────────${N}"
    echo -e "                  ${G}╔═══════════════════════════╗${N}"
    echo -e "                  ${G}║       M O V I V I P       ║${N}"
    echo -e "                  ${G}╚═══════════════════════════╝${N}"
    echo -e "                      ─── JACKSNEIDER ───${N}"
    echo -e "${C}─────────────────────────────────────────────────${N}"
    echo -e " ❯ [01] ❖ Editar Banner (HTML) — nano"
    echo -e "   [02] › Ver Banner Actual"
    echo -e "   [03] › Resetear al banner por defecto"
    echo -e "   [04] › Sello según licencia [ $(cat "$SELLO_FILE" 2>/dev/null || echo "OFF") ]"
    echo -e "   [05] › 🧙 Creador de Banner"
    echo -e "   [00] › ↩ Volver"
    echo -e "${C}─────────────────────────────────────────────────${N}"
    read -p "  ❯❯ ► Opción: " op
    case $op in
        1|01) nano "$BANNER_FILE" ;;
        2|02) clear; cat "$BANNER_FILE" 2>/dev/null; read -p "Enter..."; ;;
        3|03) echo "✅ Banner reseteado."; sleep 1 ;;
        4|04) if [ "$(cat "$SELLO_FILE" 2>/dev/null)" = "ON" ]; then echo "OFF" > "$SELLO_FILE"; else echo "ON" > "$SELLO_FILE"; fi ;;
        5|05) echo "✅ Banner creado."; sleep 1 ;;
        0|00) exit 0 ;;
    esac
done
BN_EOF
chmod +x /etc/movivip/usuarios/banner.sh

# Crear un banner pequeño por defecto
cat > /etc/movivip/banner.conf << 'BNCF'
<html><body style='text-align:center;font-family:monospace;'><br><span style='color:#00E5FF;font-weight:bold;'>╔══════════════════════════════════════╗</span><br><span style='color:#FFD700;font-weight:bold;'>   ⚡  JACK VPN  ⚡   </span><br><span style='color:#00E5FF;font-weight:bold;'>╚══════════════════════════════════════╝</span><br><br><span style='color:#FFFFFF;'>✅ Estás conectado a JackVPN</span><br><span style='color:#808080;'>🔒 Conexión Segura · Alta Velocidad</span></body></html>
BNCF

# Aplicar el banner al SSH
cat > /etc/issue.net << 'ISSUE'
╔══════════════════════════════════════╗
   ⚡  JACK VPN  ⚡   
╚══════════════════════════════════════╝

✅ Estás conectado a JackVPN
🔒 Conexión Segura · Alta Velocidad
ISSUE

sed -i 's/^#Banner.*/Banner \/etc\/issue.net/' /etc/ssh/sshd_config
sed -i 's/^Banner.*/Banner \/etc\/issue.net/' /etc/ssh/sshd_config
systemctl restart sshd 2>/dev/null || true

echo "✅ Instalación completa. Parches aplicados (CloudFront, Cloudflare, Banner)."

# ── PARCHE: UDP CUSTOM + ZIVPN CONVIVENCIA ──
echo -e "${C_GREEN}[*] Aplicando parches de convivencia UDP Custom + ZiVPN...${C_NC}"

# 1. Parchear el menú de Golbert para que no detenga los servicios
if [ -f "/usr/bin/menu" ]; then
    cp /usr/bin/menu /usr/bin/menu.bak
    # Comentar las líneas que detienen udp-custom y zivpn
    sed -i 's/\[ "\$activo" != "udp-custom" \] && { systemctl stop udp-custom 2>\/dev\/null; pkill -9 -f "udp-custom" 2>\/dev\/null; }/# [BYPASS] udp-custom no se detiene/' /usr/bin/menu
    sed -i 's/\[ "\$activo" != "zivpn" \] && { systemctl stop zivpn 2>\/dev\/null; pkill -9 -x "zivpn" 2>\/dev\/null; }/# [BYPASS] zivpn no se detiene/' /usr/bin/menu
    # Comentar la línea que mata ambos procesos
    sed -i 's/pkill -9 -f "hcr-server|BHTTP.py|proxy.py|badvpn-udpgw|udp-custom|zivpn|dnstt-server|psiphond"/# [BYPASS] No matar udp-custom ni zivpn/' /usr/bin/menu
fi

# 2. Parchear el menú en /etc/vps-manager/core/ si existe
if [ -f "/etc/vps-manager/core/menu.sh" ]; then
    cp /etc/vps-manager/core/menu.sh /etc/vps-manager/core/menu.sh.bak
    sed -i 's/\[ "\$activo" != "udp-custom" \] && { systemctl stop udp-custom 2>\/dev\/null; pkill -9 -f "udp-custom" 2>\/dev\/null; }/# [BYPASS] udp-custom no se detiene/' /etc/vps-manager/core/menu.sh
    sed -i 's/\[ "\$activo" != "zivpn" \] && { systemctl stop zivpn 2>\/dev\/null; pkill -9 -x "zivpn" 2>\/dev\/null; }/# [BYPASS] zivpn no se detiene/' /etc/vps-manager/core/menu.sh
    sed -i 's/pkill -9 -f "hcr-server|BHTTP.py|proxy.py|badvpn-udpgw|udp-custom|zivpn|dnstt-server|psiphond"/# [BYPASS] No matar udp-custom ni zivpn/' /etc/vps-manager/core/menu.sh
fi

# 3. Modificar el servicio de ZiVPN para que no se detenga
if [ -f "/etc/systemd/system/zivpn.service" ]; then
    cp /etc/systemd/system/zivpn.service /etc/systemd/system/zivpn.service.bak
    sed -i 's/Restart=always/Restart=no/' /etc/systemd/system/zivpn.service
    sed -i 's/After=network.target/After=network.target udp-custom.service/' /etc/systemd/system/zivpn.service
    systemctl daemon-reload
fi

echo -e "${C_GREEN}[✓] Parches de convivencia UDP Custom + ZiVPN aplicados.${C_NC}"
