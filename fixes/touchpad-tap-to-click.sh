#!/bin/bash
# ============================================================
# Fix: tap-to-click en touchpads con libinput
# ============================================================
# Problema: libinput tiene el tap-to-click deshabilitado por
# defecto. Tocar el touchpad no genera click izquierdo.
# Los clicks físicos (botones derecho/izquierdo) sí andan.
#
# Solución: config de Xorg que habilita Tapping para cualquier
# touchpad que use el driver libinput.
#
# Archivos que crea:
#   /etc/X11/xorg.conf.d/30-touchpad.conf
# ============================================================

set -e

echo "=== Activando tap-to-click para libinput ==="

mkdir -p /etc/X11/xorg.conf.d

cat > /etc/X11/xorg.conf.d/30-touchpad.conf << 'CONF'
Section "InputClass"
    Identifier "Touchpad Tapping"
    MatchIsTouchpad "on"
    Driver "libinput"
    Option "Tapping" "on"
    Option "TappingButtonMap" "lrm"
EndSection
CONF

echo ""
echo "✅ Config creada en /etc/X11/xorg.conf.d/30-touchpad.conf"
echo "   Cerra sesión y volvé a entrar (o reiniciá X) para que ande."
echo ""
echo "   Si también querés deshabilitar el click físico del botón inferior:"
echo "     Option \"ClickMethod\" \"clickfinger\""
