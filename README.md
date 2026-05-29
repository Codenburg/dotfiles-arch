# Instalación desde cero

En una máquina nueva con Arch:

```bash
sudo pacman -S git
cd ~
git clone git@github.com:Codenburg/dotfiles-arch.git ~/dotfiles
~/dotfiles/setup.sh
```

El script se encarga de todo: instalar dependencias, Oh My Zsh, plugins, crear los symlinks con Stow y cambiar el shell a Zsh.

### Apps que instala

| App              | Desde        |
|------------------|--------------|
| KeePassXC        | repos oficiales |
| Zed              | AUR (yay)    |
| Zen Browser      | AUR (yay)    |

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
├── setup.sh
├── .zshrc
├── .gitignore
└── README.md
```
