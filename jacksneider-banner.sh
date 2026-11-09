#!/bin/bash
if [[ $- == *i* ]]; then
    clear
    
    # Colores
    C=$'\033[1;36m'; M=$'\033[1;35m'; G=$'\033[1;32m'; Y=$'\033[1;33m'; W=$'\033[1;37m'; R=$'\033[0m'

    # Datos
    IP_PUB=$(curl -4 -s --max-time 2 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    CONEXIONES=$( (who | awk '{print $1}' && ps aux | grep -E "dropbear|sshd:" | grep -v grep | awk '{print $1}') | sort -u | wc -l)
    UPTIME=$(uptime -p | sed 's/up //' | cut -c1-18)
    RAM_PCT=$(free -m | awk '/Mem:/ {printf "%d", $3/$2 * 100}')
    CPU_PCT=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{printf "%d", 100 - $1}')
    DISCO_PCT=$(df / | awk 'NR==2 {gsub("%","",$5); print $5}')

    # Función Barra
    draw_bar() {
        local pct=$1
        local blocks=$((pct / 10))
        local bar=""
        for ((i=0; i<10; i++)); do
            if [ $i -lt $blocks ]; then bar="${bar}█"; else bar="${bar}░"; fi
        done
        echo "$bar"
    }

    # Logo
    echo -e "${C}"
    echo "          ██████╗ ██╗ ██████╗ ███████╗"
    echo "          ██╔══██╗██║██╔═══██╗██╔════╝"
    echo "          ██║  ██║██║██║   ██║███████╗"
    echo "          ██║  ██║██║██║   ██║╚════██║"
    echo "          ██████╔╝██║╚██████╔╝███████║"
    echo "          ╚═════╝ ╚═╝ ╚═════╝ ╚══════╝"
    echo -e "${M}                 E S   A M O R${R}"
    echo ""

    # Panel
    echo -e "${M}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
    echo -e "   ${G}⚡ INICIANDO SISTEMA...${R}"
    echo -e "   ${Y}📍 IP:${R}         ${C}$IP_PUB${R}"
    echo -e "   ${Y}👥 Online:${R}     ${C}$CONEXIONES${R}"
    echo -e "   ${Y}⏱  Uptime:${R}     ${C}$UPTIME${R}"
    echo -e "${M}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
    
    # Barras animadas
    echo -ne "   ${Y}RAM   ${R}"
    for i in {1..10}; do
        p=$((i * 10))
        echo -ne "\r   ${Y}RAM   ${G}$(draw_bar $p)${R} ${W}${p}%${R}"
        sleep 0.03
    done
    echo -ne "\r   ${Y}RAM   ${G}$(draw_bar $RAM_PCT)${R} ${W}${RAM_PCT}%${R}\n"

    echo -ne "   ${Y}CPU   ${R}"
    for i in {1..10}; do
        p=$((i * 10))
        echo -ne "\r   ${Y}CPU   ${G}$(draw_bar $p)${R} ${W}${p}%${R}"
        sleep 0.03
    done
    echo -ne "\r   ${Y}CPU   ${G}$(draw_bar $CPU_PCT)${R} ${W}${CPU_PCT}%${R}\n"

    echo -ne "   ${Y}Disco ${R}"
    for i in {1..10}; do
        p=$((i * 10))
        echo -ne "\r   ${Y}Disco ${G}$(draw_bar $p)${R} ${W}${p}%${R}"
        sleep 0.03
    done
    echo -ne "\r   ${Y}Disco ${G}$(draw_bar $DISCO_PCT)${R} ${W}${DISCO_PCT}%${R}\n"

    # Footer
    echo -e "${M}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
    echo -e "   ${C}📢 Telegram: ${W}t.me/+I-VOBBPsGSZjOGE5${R}"
    echo -e "   ${C}📱 WhatsApp: ${W}3181882682${R}"
    echo -e "${M}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
    echo -e "${G}       ✝  \"Jehová es mi pastor; nada me faltará.\"${R}"
    echo ""
fi
