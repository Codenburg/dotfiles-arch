#!/bin/bash
# ============================================================
# Fix: montaje automático de USBs en LXQt (sin escritorio GNOME/KDE)
# ============================================================
# Problema: Arch + LXQt no monta USBs automáticamente al conectarlos.
# udisks2 no auto-monta sin una sesión gráfica con agente polkit.
# Usar `mount` directo vía udev hace que PCManFM (LXQt) no vea los discos.
#
# Solución: udev TAG+="systemd" → servicio systemd → udisksctl como el usuario
#
# Archivos que crea:
#   /etc/polkit-1/rules.d/10-udisks2-mount.rules
#   /etc/udev/rules.d/99-usb-automount.rules
#   /etc/systemd/system/usb-automount@.service
#   /usr/local/bin/udev-automount.sh
# ============================================================

set -e

USERNAME="${SUDO_USER:-titanium}"
USER_UID=1000

echo "=== Instalando auto-mount USB para $USERNAME ==="

# ─── 1. Polkit ───────────────────────────────────────────────
# Permite montar sin autenticación (no hay agente polkit sin DE)
echo "[1/4] Regla de polkit..."
mkdir -p /etc/polkit-1/rules.d
cat > /etc/polkit-1/rules.d/10-udisks2-mount.rules << 'POLKIT'
// Allow udisks2 to mount/unmount without authentication
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.udisks2.filesystem-mount" ||
        action.id == "org.freedesktop.udisks2.filesystem-mount-other-seat" ||
        action.id == "org.freedesktop.udisks2.filesystem-unmount-other-seat") {
        return polkit.Result.YES;
    }
});
POLKIT

# ─── 2. Script helper ────────────────────────────────────────
echo "[2/4] Script helper con retry loop..."
cat > /usr/local/bin/udev-automount.sh << 'SCRIPT'
#!/bin/bash
# Monta/desmonta USB via udisksctl para que el file manager lo vea
# Retry loop: udisks2 necesita tiempo para reconocer el device nuevo

DEVNAME="$1"
ACTION="$2"
USER="titanium"

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"

case "$ACTION" in
    add)
        for i in 1 2 3 4 5 6 7 8 9 10; do
            output=$(sudo -u "$USER" udisksctl mount -b "$DEVNAME" 2>&1)
            rc=$?
            
            # Código 0 = montado correctamente
            if [ $rc -eq 0 ]; then
                logger -t udev-udisks "OK: $output"
                exit 0
            fi
            
            # AlreadyMounted = ya estaba montado (éxito)
            if echo "$output" | grep -qi "already mounted\|ya montado\|AlreadyMounted"; then
                logger -t udev-udisks "OK (already): $output"
                exit 0
            fi
            
            # Error looking up object = udisks2 aún no reconoce el device
            if echo "$output" | grep -qi "error looking up object\|no se encuentra"; then
                sleep 0.5
                continue
            fi
            
            # Otro error
            logger -t udev-udisks "ERROR: $output"
            sleep 1
        done
        logger -t udev-udisks "FAIL: No se pudo montar $DEVNAME"
        exit 1
        ;;
    remove)
        sudo -u "$USER" udisksctl unmount -b "$DEVNAME" 2>&1 | logger -t udev-udisks
        ;;
esac
SCRIPT
chmod 755 /usr/local/bin/udev-automount.sh

# ─── 3. Regla udev ───────────────────────────────────────────
echo "[3/4] Regla udev..."
cat > /etc/udev/rules.d/99-usb-automount.rules << 'RULES'
# Auto-mount USB via systemd service
# NOTA: usamos ID_USB_VENDOR_ID en vez de ID_BUS=="usb" porque
# los HDD en enclosure USB-SATA se reportan como ID_BUS=ata.
ACTION=="add",   KERNEL=="sd[a-z][0-9]", SUBSYSTEM=="block", ENV{ID_USB_VENDOR_ID}=="?*", TAG+="systemd", ENV{SYSTEMD_WANTS}="usb-automount@$kernel.service"
ACTION=="remove", KERNEL=="sd[a-z][0-9]", SUBSYSTEM=="block", ENV{ID_USB_VENDOR_ID}=="?*", RUN+="/usr/local/bin/udev-automount.sh $env{DEVNAME} remove"
RULES

# ─── 4. Servicio systemd ─────────────────────────────────────
echo "[4/4] Servicio systemd..."
cat > /etc/systemd/system/usb-automount@.service << 'SERVICE'
[Unit]
Description=Auto-mount USB device %i
After=udisks2.service
Requires=udisks2.service
BindsTo=dev-%i.device
After=dev-%i.device

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/udev-automount.sh /dev/%i add
ExecStop=/usr/local/bin/udev-automount.sh /dev/%i remove
SERVICE

# ─── Reload ──────────────────────────────────────────────────
udevadm control --reload-rules
systemctl daemon-reload

# Montar dispositivos ya conectados
for dev in /dev/sd[a-z][0-9]; do
    [ -e "$dev" ] || continue
    name="$(basename "$dev")"
    systemctl start "usb-automount@$name.service" 2>&1 | logger -t udev-udisks || true
done

echo ""
echo "✅ Instalado. Desconectá y reconectá los USBs para probar."
echo "   Los discos aparecen en PCManFM > Dispositivos"
echo "   Logs: journalctl -t udev-udisks -f"
