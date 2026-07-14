# Fixes

Scripts de configuración y arreglos para el sistema.
Cada fix se aplica con `sudo bash fixes/<nombre>.sh`.

## Índice

| Fix | Problema | Solución |
|-----|----------|----------|
| [`udev-usb-automount.sh`](#udev-usb-automountsh) | USBs no se montan solos al conectarlos en LXQt | udev + systemd + udisksctl |
| [`touchpad-tap-to-click.sh`](#touchpad-tap-to-clicksh) | Tap-to-click no funciona en el touchpad | Config de Xorg para libinput |
| [`touchpad-elantech-smbus.sh`](#touchpad-elantech-smbussh) | Touchpad Elantech pierde el movimiento, cursor se congela | Fuerza bus SMBus vía kernel parameter |

---
### `udev-usb-automount.sh`

**Problema:** En LXQt sin GNOME/KDE, udisks2 no monta automáticamente los USBs
al conectarlos porque no hay un agente de polkit de escritorio que autorice la
operación. El file manager (PCManFM-Qt) no muestra los discos en "Dispositivos".

**Solución:**
1. Regla de **polkit** que permite montar sin autenticación
2. Regla **udev** que detecta USBs al conectarlos usando `TAG+="systemd"`
3. Servicio **systemd** que ejecuta `udisksctl mount` con retry loop

**Lecciones:**
- Los HDD en enclosure USB-SATA reportan `ID_BUS=ata`, no `usb`
- No matchear por `ID_BUS=usb`, usar `ID_USB_VENDOR_ID`
- `udisksctl` habla en el locale del sistema — no parsear texto inglés
- udev `RUN+=` se ejecuta antes de que udisks2 procese el device — usar systemd service
- Ventoy crea 2 particiones (data + EFI), se montan ambas

**Archivos que crea:**
- `/etc/polkit-1/rules.d/10-udisks2-mount.rules`
- `/etc/udev/rules.d/99-usb-automount.rules`
- `/etc/systemd/system/usb-automount@.service`
- `/usr/local/bin/udev-automount.sh`

---

### `touchpad-tap-to-click.sh`

**Problema:** libinput deshabilita el tap-to-click por defecto. Tocar el touchpad
no genera click izquierdo, aunque los botones físicos sí funcionan.

**Solución:** Crea `/etc/X11/xorg.conf.d/30-touchpad.conf` con `Tapping "on"`
para cualquier touchpad que use el driver libinput. Funciona en cualquier laptop.

**Archivos que crea:**
- `/etc/X11/xorg.conf.d/30-touchpad.conf`

---

### `touchpad-elantech-smbus.sh`

**Problema:** Touchpad Elantech pierde sincronización con el driver `psmouse`.
El cursor se congela (no responde el movimiento), los clicks físicos siguen
andando, y solo se recupera reiniciando la PC.

**Solución:** Agrega `psmouse.elantech_smbus=1` a `GRUB_CMDLINE_LINUX_DEFAULT`
y regenera `grub.cfg`. Fuerza el uso del bus SMBus que es más estable que PS/2
para estos touchpads.

**Archivos que modifica:**
- `/etc/default/grub`

---

### Template para nuevos fixes

```markdown
### `nombre-del-fix.sh`

**Problema:** [qué falla o falta]

**Solución:** [qué hace el script]

**Archivos que crea/modifica:**
- `/ruta/al/archivo`
```

Agregar al índice y al README al añadir un fix.
