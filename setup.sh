#!/bin/bash

# Terminar el script si algún comando falla, PERO solo en pasos obligatorios
# (los confirm devuelven 1 cuando es "no" y eso no debe cortar el script)
set -eo pipefail

# ─── Función de confirmación ───────────────────────────────────────────────
confirm() {
    read -r -p "$1 [s/N] " response
    case "$response" in
        [sSyY]) return 0 ;;
        *) return 1 ;;
    esac
}

# ─── Preámbulo obligatorio ─────────────────────────────────────────────────

echo "=> Actualizando el sistema e instalando paquetes base..."
sudo pacman -Syu --needed zsh stow git \
  fzf zoxide bat fd tmux \
  zsh-autosuggestions zsh-syntax-highlighting \
  --noconfirm

# 1. Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "=> Instalando Oh My Zsh..."
    env CHSH=no RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "=> Oh My Zsh ya está instalado."
fi

# 2. Respaldar .zshrc por defecto
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    echo "=> Respaldando el .zshrc por defecto del sistema..."
    mv ~/.zshrc ~/.zshrc.system.bak
fi

# 3b. Respaldar configs pre-existentes que pueden chocar con stow
# Cubre real files en las rutas de stow. Foreign symlinks (creados a mano
# o por stow viejo) NO se respaldan — hay que borrarlos a mano antes de
# correr setup.sh, o stow va a fallar con "not owned by stow".
for stow_cfg in \
    "$HOME/.p10k.zsh" \
    "$HOME/.tmux.conf" \
    "$HOME/.config/alacritty/alacritty.toml" \
    "$HOME/.config/zed/settings.json"; do
    if [ -f "$stow_cfg" ] && [ ! -L "$stow_cfg" ]; then
        echo "=> Respaldando $(basename "$stow_cfg") existente a $(basename "$stow_cfg").pre-stow.bak..."
        mv "$stow_cfg" "${stow_cfg}.pre-stow.bak"
    fi
done

# 3. Stow — enlazar configs
echo "=> Enlazando configuraciones con Stow..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
stow .

# ─── Configuración por resolución de pantalla ──────────────────────────

detect_resolution() {
    local res=""

    # X11
    if command -v xrandr &>/dev/null; then
        res=$(xrandr --current 2>/dev/null | grep -oP '\d+x\d+' | head -1)
    fi

    # Wayland (wlroots-based compositors)
    if [ -z "$res" ] && command -v wlr-randr &>/dev/null; then
        res=$(wlr-randr 2>/dev/null | grep -oP '\d+x\d+' | head -1)
    fi

    # Hyprland
    if [ -z "$res" ] && command -v hyprctl &>/dev/null; then
        res=$(hyprctl monitors 2>/dev/null | grep -oP '\d+x\d+' | head -1)
    fi

    echo "$res"
}

configure_for_resolution() {
    local resolution
    resolution=$(detect_resolution)

    local alacritty_size=7.4
    local zed_ui=11
    local zed_buffer=9
    local profile="netbook"

    if [ -n "$resolution" ]; then
        local height="${resolution#*x}"
        if [ "$height" -ge 900 ] 2>/dev/null; then
            alacritty_size=11
            zed_ui=15
            zed_buffer=13
            profile="1080p"
        fi
        echo "=> Resolución detectada: $resolution → perfil $profile"
    else
        echo "=> ⚠️  No se pudo detectar la resolución automáticamente."
        if confirm "¿Estás usando una pantalla 1080p o más grande?"; then
            alacritty_size=11
            zed_ui=15
            zed_buffer=13
            profile="1080p"
        fi
        echo "   → perfil $profile"
    fi

    # Alacritty — escribir size.toml (stow no lo gestiona)
    mkdir -p "$HOME/.config/alacritty"
    cat > "$HOME/.config/alacritty/size.toml" <<- EOF
[font]
size = $alacritty_size
EOF
    echo "   ✓ Alacritty: font.size → $alacritty_size"

    # Zed — parchear settings.json si existe (post-stow)
    local zed_settings="$HOME/.config/zed/settings.json"
    if [ -f "$zed_settings" ]; then
        sed -i "s/\"ui_font_size\": [0-9]*/\"ui_font_size\": $zed_ui/" "$zed_settings"
        sed -i "s/\"buffer_font_size\": [0-9]*/\"buffer_font_size\": $zed_buffer/" "$zed_settings"
        echo "   ✓ Zed: ui_font_size → $zed_ui, buffer_font_size → $zed_buffer"
    fi
}

configure_for_resolution

# 4. Cambiar shell a Zsh
if [ "$SHELL" != "/usr/bin/zsh" ] && confirm "¿Cambiar el shell por defecto a Zsh?"; then
    echo "=> Cambiando el shell por defecto a Zsh (ingresa tu contraseña de usuario)..."
    chsh -s "$(command -v zsh)"
fi

# ─── AUR helper ────────────────────────────────────────────────────────────

HAS_YAY=false
if command -v yay &> /dev/null; then
    HAS_YAY=true
    echo "=> yay ya está instalado."
elif confirm "¿Instalar yay (AUR helper, necesario para apps de AUR)?"; then
    echo "=> Instalando dependencias de compilación y yay..."
    sudo pacman -S --needed base-devel git --noconfirm
    mkdir -p /tmp/yay-build
    git clone https://aur.archlinux.org/yay.git /tmp/yay-build/yay
    cd /tmp/yay-build/yay
    makepkg -si --noconfirm
    cd "$SCRIPT_DIR"
    HAS_YAY=true
fi

# ─── Aplicaciones ──────────────────────────────────────────────────────────

PACMAN_PKGS=()
YAY_PKGS=()

# Repos oficiales
if confirm "¿Instalar KeePassXC?"; then
    PACMAN_PKGS+=(keepassxc)
fi

if confirm "¿Instalar Docker?"; then
    PACMAN_PKGS+=(docker docker-compose)
    DOCKER_SELECTED=true
fi

if confirm "¿Instalar Zed?"; then
    PACMAN_PKGS+=(zed)
fi

if confirm "¿Instalar Alacritty (terminal)?"; then
    PACMAN_PKGS+=(alacritty)
fi

if confirm "¿Instalar OpenCode (AI coding agent)?"; then
    PACMAN_PKGS+=(opencode)
fi

# Solo preguntar si hay GPU Intel
HAS_INTEL_GPU=false
if command -v lspci &>/dev/null && lspci -nn 2>/dev/null | grep -qi '0300.*Intel'; then
    HAS_INTEL_GPU=true
fi

if [ "$HAS_INTEL_GPU" = true ] && confirm "¿Configurar Intel GPU TearFree? (picom + drivers Intel + anti-tearing para video en X11)"; then
    PACMAN_PKGS+=(picom mesa vulkan-intel intel-media-driver libva-intel-driver)
    CONFIGURE_INTEL_TEARFREE=true
fi

# AUR (solo si hay yay)

if [ "$HAS_YAY" = true ]; then
    if confirm "¿Instalar LibreWolf?"; then
        YAY_PKGS+=(librewolf-bin)
    fi

    if confirm "¿Instalar Zen Browser?"; then
        YAY_PKGS+=(zen-browser-bin)
    fi

    if confirm "¿Instalar fnm (Fast Node Manager)?"; then
        YAY_PKGS+=(fnm-bin)
        FNM_SELECTED=true
    fi

    if confirm "¿Instalar pnpm?"; then
        YAY_PKGS+=(pnpm-bin)
    fi

    if confirm "¿Instalar LocalSend?"; then
        YAY_PKGS+=(localsend-bin)
    fi

    if confirm "¿Instalar carapace (autocompletado avanzado)?"; then
        YAY_PKGS+=(carapace-bin)
    fi

    if confirm "¿Instalar Powerlevel10k (tema para Zsh)?"; then
        YAY_PKGS+=(zsh-theme-powerlevel10k ttf-meslo-nerd-font-powerlevel10k)
    fi

else
    echo "=> ⚠️  Saltando apps de AUR (no tenés yay). Ejecutá de nuevo el script si instalás yay después."
fi

# ─── Instalar batches ──────────────────────────────────────────────────────

if [ ${#PACMAN_PKGS[@]} -gt 0 ]; then
    echo "=> Instalando paquetes de repos oficiales..."
    sudo pacman -S --needed "${PACMAN_PKGS[@]}" --noconfirm
fi

if [ ${#YAY_PKGS[@]} -gt 0 ] && [ "$HAS_YAY" = true ]; then
    echo "=> Instalando paquetes de AUR..."
    yay -S --needed "${YAY_PKGS[@]}" --noconfirm
fi

# ─── Post-instalación de cada app ──────────────────────────────────────────

# Docker
if [ "${DOCKER_SELECTED:-false}" = true ]; then
    echo "=> Configurando Docker..."
    sudo systemctl enable --now docker 2>/dev/null || true
    sudo usermod -aG docker "$USER"
    echo "   ✓ Docker listo. Necesitás reiniciar sesión para usar docker sin sudo."
fi

# Node.js con fnm
if [ "${FNM_SELECTED:-false}" = true ] && command -v fnm &> /dev/null; then
    if confirm "¿Instalar Node.js 24 con fnm?"; then
        echo "=> Instalando Node.js 24..."
        fnm install 24
        fnm default 24
        echo "   ✓ Node.js $(node --version) instalado"
    fi
fi

# Tmux — instalar TPM (el .tmux.conf lo linkea stow automáticamente)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "=> Instalando TPM..."
    mkdir -p "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# Symlink de Zed (el paquete de Arch instala el CLI como "zeditor")
if command -v zeditor &> /dev/null && [ ! -L "/usr/local/bin/zed" ] && [ ! -f "/usr/local/bin/zed" ]; then
    echo "=> Creando symlink zed -> zeditor..."
    sudo ln -s /usr/bin/zeditor /usr/local/bin/zed
fi

# Intel GPU TearFree — config para X11/modesetting
if [ "${CONFIGURE_INTEL_TEARFREE:-false}" = true ]; then
    echo "=> Configurando Intel GPU TearFree para X11..."

    INTEL_CONF="/etc/X11/xorg.conf.d/20-intel.conf"
    sudo mkdir -p /etc/X11/xorg.conf.d

    if [ ! -f "$INTEL_CONF" ]; then
        sudo tee "$INTEL_CONF" > /dev/null <<- 'CONF'
Section "Device"
    Identifier "Intel Graphics"
    Driver "modesetting"
    Option "TearFree" "true"
EndSection
CONF
        echo "   ✓ Creado $INTEL_CONF con Driver modesetting + TearFree"
    else
        echo "   ✓ $INTEL_CONF ya existe, no se sobreescribe"
    fi

    # Si existe xorg.conf con Driver "intel", advertir
    if grep -q 'Driver\s+"intel"' /etc/X11/xorg.conf 2>/dev/null; then
        echo "   ⚠️  /etc/X11/xorg.conf usa Driver \"intel\" (no carga en Xorg moderno)."
        echo "      El config correcto está en $INTEL_CONF con modesetting."
        echo "      Podés borrar /etc/X11/xorg.conf si querés:"
        echo "      sudo rm /etc/X11/xorg.conf"
    fi

    echo "   ✓ TearFree configurado. Reiniciá la sesión de Xorg para aplicar."
fi

# ─── Gentle-AI (ecosistema AI) ──────────────────────────────────────────────

if command -v opencode &> /dev/null && confirm "¿Instalar Gentle-AI (skills, SDD, memoria persistente para OpenCode)?"; then
    echo "=> Instalando Gentle-AI..."
    curl -fsSL https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh | bash
    echo "   ✓ Gentle-AI instalado. Corré 'gentle-ai doctor' para verificar."
fi

echo "=> ¡Instalación completada con éxito! Reinicia la terminal."
