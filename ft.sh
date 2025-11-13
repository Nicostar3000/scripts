#!/bin/bash

# Default values
DC_IP=""
CMD=""

# Argumente parsen
while [[ $# -gt 0 ]]; do
    case "$1" in
        -dc)
            DC_IP="$2"
            shift 2
            ;;
        -cmd)
            CMD="$2"
            shift 2
            ;;
        *)
            echo "[!] Unbekannter Parameter: $1"
            exit 1
            ;;
    esac
done

# Validierung
if [[ -z "$DC_IP" || -z "$CMD" ]]; then
    echo "Usage: $0 -dc <domain_controller_ip> -cmd '<command_to_run>'"
    exit 1
fi

# Zeitabweichung ermitteln
OFFSET_RAW=$(ntpdate -q "$DC_IP" 2>/dev/null | grep -oP 'offset \K[-0-9.]+')
if [[ -z "$OFFSET_RAW" ]]; then
    echo "[!] Konnte Zeitabweichung nicht ermitteln. Ist der DC erreichbar?"
    exit 1
fi

OFFSET_SEC=$(printf "%.0f" "$OFFSET_RAW")
FAKETIME="@${OFFSET_SEC}s"

echo "[*] Zeitabweichung zum DC: ${OFFSET_SEC} Sekunden"
echo "[*] Führe Befehl mit faketime aus: $CMD"

# Befehl mit faketime ausführen
FAKETIME="$FAKETIME" \
LD_PRELOAD=/usr/lib/faketime/libfaketime.so.1 \
bash -c "$CMD"