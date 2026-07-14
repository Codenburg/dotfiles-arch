#!/bin/bash
# ============================================================
# Fix: estabilidad touchpad Elantech (congelamiento del cursor)
# ============================================================
# Problema: el driver psmouse pierde sincronización con
# touchpads Elantech por PS/2. El cursor se congela, los
# clicks físicos siguen andando, y hay que reiniciar la PC.
#
# Solución: forzar el uso del bus SMBus con el parámetro
# psmouse.elantech_smbus=1, que es más estable que PS/2
# para estos touchpads.
#
# Archivos que modifica:
#   /etc/default/grub (agrega psmouse.elantech_smbus=1)
#
# Requiere: grub
# ============================================================

set -e

GRUB_FILE="/etc/default/grub"
PARAM="psmouse.elantech_smbus=1"

echo "=== Touchpad Elantech: forzando SMBus ==="

if [ ! -f "$GRUB_FILE" ]; then
    echo "ERROR: no se encuentra $GRUB_FILE"
    exit 1
fi

# Si ya está el parámetro, no repetir
if grep -q "$PARAM" "$GRUB_FILE"; then
    echo "OK: $PARAM ya está en $GRUB_FILE"
else
    echo "Agregando $PARAM a GRUB_CMDLINE_LINUX_DEFAULT..."
    sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"\(.*\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\1 $PARAM\"/" "$GRUB_FILE"

    # Sacar espacios duplicados por las dudas
    sed -i 's/  */ /g' "$GRUB_FILE"

    echo "Regenerando grub.cfg..."
    grub-mkconfig -o /boot/grub/grub.cfg

    echo ""
    echo "✅ Parámetro agregado. Reiniciá para que tome efecto."
fi
