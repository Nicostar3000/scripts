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

# Hole die aktuelle Zeit vom DC und konvertiere sie in ein Format für faketime
echo "[*] Frage Zeit vom DC $DC_IP ab..."
DC_TIMESTAMP=$(ntpdate -q "$DC_IP" 2>/dev/null | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}' | head -1)

if [[ -z "$DC_TIMESTAMP" ]]; then
    echo "[!] Konnte DC-Zeit nicht ermitteln"
    exit 1
fi

# Konvertiere das Datum in das faketime-Format (YYYY-MM-DD HH:MM:SS)
FAKETIME="$DC_TIMESTAMP"

echo "[*] DC-Zeit: $DC_TIMESTAMP"
echo "[*] Führe Befehl mit faketime aus: $CMD"
echo ""

# Finde faketime library
FAKETIME_LIB=""
for lib_path in /usr/lib/x86_64-linux-gnu/faketime/libfaketime.so.1 \
                /usr/lib/faketime/libfaketime.so.1 \
                /usr/lib64/faketime/libfaketime.so.1 \
                /usr/local/lib/faketime/libfaketime.so.1; do
    if [[ -f "$lib_path" ]]; then
        FAKETIME_LIB="$lib_path"
        break
    fi
done

if [[ -z "$FAKETIME_LIB" ]]; then
    echo "[!] libfaketime.so.1 nicht gefunden!"
    exit 1
fi

echo "[*] Verwende faketime library: $FAKETIME_LIB"

# Befehl mit faketime ausführen
FAKETIME="$FAKETIME" \
LD_PRELOAD="$FAKETIME_LIB" \
bash -c "$CMD"
