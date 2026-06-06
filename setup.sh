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

echo "=> Actualizando el sistema e instalando Zsh y Stow..."
sudo pacman -Syu --needed zsh stow git --noconfirm

# 1. Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "=> Instalando Oh My Zsh..."
    env CHSH=no RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "=> Oh My Zsh ya está instalado."
fi

# 2. Plugins de Zsh
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo "=> Instalando zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo "=> Instalando zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# 3. Respaldar .zshrc por defecto
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    echo "=> Respaldando el .zshrc por defecto del sistema..."
    mv ~/.zshrc ~/.zshrc.system.bak
fi

# 4. Stow — enlazar configs
echo "=> Enlazando configuraciones con Stow..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
stow .

# 5. Cambiar shell a Zsh
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

# AUR (solo si hay yay)
if [ "$HAS_YAY" = true ]; then
    if confirm "¿Instalar Sublime Text 4?"; then
        YAY_PKGS+=(sublime-text-4)
    fi

    if confirm "¿Instalar LibreWolf?"; then
        YAY_PKGS+=(librewolf-bin)
        LIBREWOLF_SELECTED=true
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

# user.js de LibreWolf
if [ "${LIBREWOLF_SELECTED:-false}" = true ]; then
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
fi

echo "=> ¡Instalación completada con éxito! Reinicia la terminal."
