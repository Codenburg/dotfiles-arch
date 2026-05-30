#!/bin/bash

# Terminar el script si algún comando falla
set -eo pipefail

echo "=> Actualizando el sistema e instalando Zsh y Stow..."
sudo pacman -Syu --needed zsh stow git --noconfirm

# 1. Instalar Oh My Zsh si no está instalado
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "=> Instalando Oh My Zsh..."
    # Se usa env CHSH=no RUNZSH=no para que el instalador no bloquee el script pidiendo interactividad
    env CHSH=no RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "=> Oh My Zsh ya está instalado."
fi

# 2. Instalar Plugins (Autocompletado y Resaltado de sintaxis)
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

# Autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo "=> Instalando zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# Syntax Highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo "=> Instalando zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# 3. Eliminar el archivo .zshrc por defecto que crea Oh My Zsh para evitar conflictos con Stow
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    echo "=> Respaldando el .zshrc por defecto del sistema..."
    mv ~/.zshrc ~/.zshrc.system.bak
fi

# 4. Ejecutar Stow para enlazar tus dotfiles
echo "=> Enlazando configuraciones con Stow..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
stow .

# 5. Cambiar el shell por defecto a Zsh
if [ "$SHELL" != "/usr/bin/zsh" ]; then
    echo "=> Cambiando el shell por defecto a Zsh (ingresa tu contraseña de usuario)..."
    chsh -s "$(command -v zsh)"
fi

# 6. Instalar AUR helper (yay) y aplicaciones
if ! command -v yay &> /dev/null; then
    echo "=> Instalando dependencias de compilación y yay (AUR helper)..."
    sudo pacman -S --needed base-devel git --noconfirm

    mkdir -p /tmp/yay-build
    git clone https://aur.archlinux.org/yay.git /tmp/yay-build/yay
    cd /tmp/yay-build/yay
    makepkg -si --noconfirm
    cd "$SCRIPT_DIR"
else
    echo "=> yay ya está instalado."
fi

echo "=> Instalando aplicaciones (KeePassXC, Zed, LibreWolf)..."
sudo pacman -S --needed keepassxc --noconfirm
yay -S --needed sublime-text-4 librewolf-bin --noconfirm

# 7. Linkear user.js de LibreWolf al perfil (si ya existe)
LIBREWOLF_PROFILE=$(ls -d "$HOME/.librewolf/"*.default* 2>/dev/null | head -1)
if [ -n "$LIBREWOLF_PROFILE" ]; then
    echo "=> Linkeando librewolf/user.js al perfil..."
    ln -sf "$SCRIPT_DIR/librewolf/user.js" "$LIBREWOLF_PROFILE/user.js"
    echo "   ✓ user.js linkeado a $LIBREWOLF_PROFILE"
else
    echo "=> ⚠️  No se encontró perfil de LibreWolf."
    echo "   Abrí LibreWolf una vez, cerrálo, y volvé a ejecutar este script"
    echo "   para linkear librewolf/user.js al perfil."
fi

echo "=> ¡Instalación completada con éxito! Reinicia la terminal."
