# Instalación desde cero

En una máquina nueva con Arch:

```bash
sudo pacman -S git stow
cd ~
git clone git@github.com:Codenburg/dotfiles-arch.git ~/dotfiles
mv ~/.zshrc ~/.zshrc.system.bak   # si existe
cd ~/dotfiles
stow .
ls -lah ~ | grep "\->"              # verificar symlinks
```

## Actualizar

```bash
cd ~/dotfiles
git add -A && git commit -m "..." && git push
```

En la otra máquina:

```bash
cd ~/dotfiles && git pull && stow .
```

## Estructura

```
~/.dotfiles/
├── .zshrc
├── .gitignore
└── README.md
```
