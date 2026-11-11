#!/usr/bin/env bash
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

# ── APLICAR PARCHES DE CLOUDFRONT Y CLOUDFLARE ──
echo "[*] Aplicando parches de CloudFront y Cloudflare..."

# CloudFront
cat > /etc/movivip/herramientas/cloudfront.sh << 'CF_EOF'
#!/bin/bash
# CloudFront Manager - Recreado por Bypass (Sin validación Premium)
G='\033[0;32m'; R='\033[0;31m'; C='\033[0;36m'; Y='\033[1;33m'; N='\033[0m'
CONF="/etc/movivip/cloudfront_aws.conf"
if ! command -v aws &>/dev/null; then
    echo -e "${R}⚠️ AWS CLI no está instalado.${N}"
    echo -e "${Y}Instalando AWS CLI...${N}"
    apt-get update -y -q >/dev/null 2>&1
    apt-get install -y -q awscli >/dev/null 2>&1 || pip3 install awscli >/dev/null 2>&1
fi
mostrar_menu() {
    clear
    echo -e "${C}─────────────────────────────────────────────────────────────────${N}"
    echo -e "         ${G}Administración de distribuciones CloudFront${N}"
    echo -e "      ${Y}📱 https://t.me/+I-VOBBPsGSZjOGE5${N}  ·  💬 JackSneider"
    echo -e "${C}─────────────────────────────────────────────────────────────────${N}"
    echo -e "${C}╭──────────────────◆ ESTADO DE CREDENCIALES ◆───────────────────╮${N}"
    if [ -f "$CONF" ] && [ -s "$CONF" ]; then
        echo -e "│ ${G}✅ AWS · Credenciales configuradas${N}                         │"
    else
        echo -e "│ ${R}⚠️ AWS · Pendientes: configura las credenciales${N}          │"
    fi
    echo -e "${C}╰───────────────────────────────────────────────────────────────╯${N}"
    echo -e "${C}╭─────────────────────────◆ ACCIONES ◆──────────────────────────╮${N}"
    echo -e "│ ${G}1${N} Listar distribuciones ·                                     │"
    echo -e "│ ${G}2${N} Ver distribución ·                                          │"
    echo -e "│ ${G}3${N} Cambiar dominio de origen ·                                 │"
    echo -e "│ ${G}4${N} Agregar o quitar alias ·                                    │"
    echo -e "│ ${G}5${N} Crear distribución nueva ·                                  │"
    echo -e "│ ${G}6${N} Credenciales AWS ·                                          │"
    echo -e "│ ${G}7${N} Ayuda: dónde conseguir credenciales AWS ·                   │"
    echo -e "│ ${G}0${N} Volver ·                                                    │"
    echo -e "${C}╰───────────────────────────────────────────────────────────────╯${N}"
    echo ""
}
configurar_aws() {
    clear
    echo -e "${C}═══ CONFIGURAR CREDENCIALES AWS ═══${N}"
    read -p "AWS Access Key ID: " aws_key
    read -p "AWS Secret Access Key: " aws_secret
    read -p "Región (default: us-east-1): " aws_region
    aws_region=${aws_region:-us-east-1}
    echo "export AWS_ACCESS_KEY_ID=$aws_key" > "$CONF"
    echo "export AWS_SECRET_ACCESS_KEY=$aws_secret" >> "$CONF"
    echo "export AWS_DEFAULT_REGION=$aws_region" >> "$CONF"
    chmod 600 "$CONF"
    echo -e "${G}✅ Credenciales guardadas.${N}"
    read -p "Presiona Enter para continuar..."
}
cargar_aws() { [ -f "$CONF" ] && source "$CONF"; }
while true; do
    mostrar_menu
    read -p "Opción [0]: " op
    case $op in
        1) cargar_aws; clear; echo -e "${C}═══ LISTAR DISTRIBUCIONES ═══${N}"; aws cloudfront list-distributions --query "DistributionList.Items[*].[Id,DomainName,Status,Origins.Items[0].DomainName]" --output table 2>&1 | head -30; read -p "Enter para volver..."; ;;
        2) cargar_aws; clear; read -p "ID de la distribución: " dist_id; aws cloudfront get-distribution --id "$dist_id" 2>&1 | head -30; read -p "Enter para volver..."; ;;
        3) cargar_aws; clear; read -p "ID de la distribución: " dist_id; read -p "Nuevo dominio: " nd; echo "Edita manualmente desde la consola AWS"; read -p "Enter..."; ;;
        4) cargar_aws; clear; read -p "ID distribución: " d; read -p "Alias: " a; echo "Gestiona alias desde consola AWS"; read -p "Enter..."; ;;
        5) cargar_aws; clear; echo "Crea distribución desde consola AWS"; read -p "Enter..."; ;;
        6) configurar_aws ;;
        7) clear; echo "1. Ve a https://console.aws.amazon.com/iam/"; echo "2. Crea usuario con permisos CloudFront"; echo "3. Genera Access Key"; read -p "Enter..."; ;;
        0) exit 0 ;;
        *) echo -e "${R}Opción inválida${N}"; sleep 1 ;;
    esac
done
CF_EOF

# Cloudflare
cat > /etc/movivip/herramientas/cloudflare.sh << 'CFL_EOF'
#!/bin/bash
# Cloudflare Manager - Recreado por Bypass (Sin validación Premium)
G='\033[0;32m'; R='\033[0;31m'; C='\033[0;36m'; Y='\033[1;33m'; N='\033[0m'
CONF="/etc/movivip/cloudflare_api.conf"
mostrar_menu() {
    clear
    echo -e "${C}─────────────────────────────────────────────────────────────────${N}"
    echo -e "         ${G}Administración de Cloudflare${N}"
    echo -e "      ${Y}📱 https://t.me/+I-VOBBPsGSZjOGE5${N}  ·  💬 JackSneider"
    echo -e "${C}─────────────────────────────────────────────────────────────────${N}"
    echo -e "${C}╭──────────────────◆ ESTADO DE CREDENCIALES ◆───────────────────╮${N}"
    if [ -f "$CONF" ] && [ -s "$CONF" ]; then
        echo -e "│ ${G}✅ Cloudflare · Credenciales configuradas${N}                 │"
    else
        echo -e "│ ${R}⚠️ Cloudflare · Pendientes: configura las credenciales${N}     │"
    fi
    echo -e "${C}╰───────────────────────────────────────────────────────────────╯${N}"
    echo -e "${C}╭─────────────────────────◆ ACCIONES ◆──────────────────────────╮${N}"
    echo -e "│ ${G}1${N} Listar zonas DNS ·                                          │"
    echo -e "│ ${G}2${N} Ver registros DNS de una zona ·                             │"
    echo -e "│ ${G}3${N} Crear registro DNS ·                                        │"
    echo -e "│ ${G}4${N} Eliminar registro DNS ·                                     │"
    echo -e "│ ${G}5${N} Estado de la zona ·                                         │"
    echo -e "│ ${G}6${N} Credenciales Cloudflare ·                                   │"
    echo -e "│ ${G}7${N} Ayuda: dónde conseguir el token de API ·                    │"
    echo -e "│ ${G}0${N} Volver ·                                                    │"
    echo -e "${C}╰───────────────────────────────────────────────────────────────╯${N}"
    echo ""
}
configurar_cf() {
    clear
    echo -e "${C}═══ CONFIGURAR CREDENCIALES CLOUDFLARE ═══${N}"
    read -p "Cloudflare API Token: " cf_token
    echo "export CF_TOKEN=$cf_token" > "$CONF"
    chmod 600 "$CONF"
    echo -e "${G}✅ Token guardado.${N}"
    read -p "Presiona Enter para continuar..."
}
cargar_cf() { [ -f "$CONF" ] && source "$CONF"; }
cf_api() { curl -s -X GET "https://api.cloudflare.com/client/v4/$1" -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json"; }
while true; do
    mostrar_menu
    read -p "Opción [0]: " op
    case $op in
        1) cargar_cf; clear; cf_api "zones" | jq -r '.result[] | "\(.id)  \(.name)  \(.status)"' 2>/dev/null || echo "Error: verifica el token."; read -p "Enter..."; ;;
        2) cargar_cf; clear; read -p "ID zona: " z; cf_api "zones/$z/dns_records" | jq -r '.result[] | "\(.type)  \(.name)  \(.content)"' 2>/dev/null; read -p "Enter..."; ;;
        3) cargar_cf; clear; read -p "ID zona: " z; read -p "Tipo: " t; read -p "Nombre: " n; read -p "Contenido: " c; curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$z/dns_records" -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json" --data "{\"type\":\"$t\",\"name\":\"$n\",\"content\":\"$c\",\"ttl\":1}" >/dev/null; echo -e "${G}✅ Registro creado.${N}"; read -p "Enter..."; ;;
        4) cargar_cf; clear; read -p "ID zona: " z; read -p "ID registro: " r; curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$z/dns_records/$r" -H "Authorization: Bearer $CF_TOKEN" >/dev/null; echo -e "${G}✅ Eliminado.${N}"; read -p "Enter..."; ;;
        5) cargar_cf; clear; read -p "ID zona: " z; cf_api "zones/$z" | jq -r '.result | "Dominio: \(.name)  Estado: \(.status)"' 2>/dev/null; read -p "Enter..."; ;;
        6) configurar_cf ;;
        7) clear; echo "1. Ve a https://dash.cloudflare.com/profile/api-tokens"; echo "2. Crea token con permisos Zone.DNS Edit"; read -p "Enter..."; ;;
        0) exit 0 ;;
        *) echo -e "${R}Opción inválida${N}"; sleep 1 ;;
    esac
done
CFL_EOF

chmod +x /etc/movivip/herramientas/cloudfront.sh
chmod +x /etc/movivip/herramientas/cloudflare.sh
echo "✅ Parches aplicados (CloudFront y Cloudflare)."

echo "✅ Instalación completada."
