# Instalación desde cero

En una máquina nueva con Arch:

```bash
sudo pacman -S git
cd ~
git clone git@github.com:Codenburg/dotfiles-arch.git ~/dotfiles
~/dotfiles/setup.sh
```

El script se encarga de todo: instalar paquetes base y herramientas, Oh My Zsh, crear los symlinks con Stow, cambiar el shell a Zsh, y preguntar por apps opcionales.

### Paquetes base (se instalan siempre)

| Paquete          | Desde        |
|------------------|--------------|
| fzf              | repos oficiales |
| zoxide           | repos oficiales |
| bat              | repos oficiales |
| fd               | repos oficiales |
| tmux             | repos oficiales |
| zsh-autosuggestions | repos oficiales |
| zsh-syntax-highlighting | repos oficiales |

### Apps opcionales (pregunta durante el setup)

| App              | Desde        |
|------------------|--------------|
| KeePassXC        | repos oficiales |
| Docker           | repos oficiales |
| Alacritty        | repos oficiales |
| OpenCode         | repos oficiales |
| Zed              | repos oficiales |
| LibreWolf        | AUR (yay)    |
| Zen Browser      | AUR (yay)    |
| fnm              | AUR (yay)    |
| carapace         | AUR (yay)    |
| pnpm             | AUR (yay)    |
| LocalSend        | AUR (yay)    |
| CopyQ (gestor de portapapeles)   | repos oficiales |
| Powerlevel10k (config versionada) | AUR (yay)    |

> El CLI de Zed se instala como `zeditor`. El `setup.sh` crea automáticamente un symlink `zed → zeditor` en `/usr/local/bin/` para que puedas usar `zed` directamente. La configuración de Zed (fuentes, tema, etc.) está en `.config/zed/settings.json` y stow la linkea automáticamente.

> `$PROJECT_DIR` está configurado como `~/Codenburg` en el `.zshrc`.

### Tmux

La config de tmux está en `.tmux.conf` (stow lo linkea a `~/.tmux.conf`) con tema Kanagawa, navegación tipo vim, ventana flotante con `Alt+G`, y soporte de plugins via TPM. El `setup.sh` instala TPM automáticamente. Los plugins se instalan al abrir tmux con `Ctrl+A + I`.

### CopyQ

La configuración de CopyQ está en `.config/copyq/` y stow la linkea a `~/.config/copyq/`. Incluye:

- **Historial** con soporte de imágenes, texto, y búsqueda
- **Atajo global** `Super+V` para mostrar/ocultar la ventana
- **Autostart** con LXQT via `~/.config/autostart/com.github.hluk.copyq.desktop`
- Tema oscuro, notificaciones, vista previa de imágenes (max 320x240)
- Comandos personalizados: cifrar/descifrar, fijar items, etiquetas

Para cambiar el atajo global, abrí CopyQ → `Ctrl+P` → pestaña *Atajos* o editá `~/.config/copyq/copyq-commands.ini`.

### Alacritty

La config de alacritty está en `.config/alacritty/alacritty.toml` y stow la linkea a `~/.config/alacritty/alacritty.toml`. Usa la paleta Kanagawa (que ya tenés en tmux), la fuente `IosevkaTerm NF`, y la ventana arranca en fullscreen con opacidad 0.95 y blur.

> La fuente `IosevkaTerm NF` no la instala el `setup.sh` automáticamente. Si no la tenés, instalala con:
> ```bash
> sudo pacman -S ttf-iosevkaterm-nerd
> ```

### Powerlevel10k

La config de p10k está en `.p10k.zsh` y stow la linkea a `~/.p10k.zsh`. Es el snapshot generado por `p10k configure` (1777 líneas, ~92 KB).

Si querés re-personalizar el prompt:

```bash
p10k configure
```

El wizard sobreescribe `~/.p10k.zsh` (rompe el symlink de stow). Para volver a la versión versionada:

```bash
rm ~/.p10k.zsh && stow .
```

> **Mismatch de font**: si p10k muestra `?` o glifos rotos, es porque la config fue generada para una Nerd Font distinta a la que usa alacritty. Re-corré `p10k configure` para regenerarla con la font actual.

### OpenCode + Gentle-AI

OpenCode es el AI coding agent, instalado desde repos oficiales. Después de instalarlo, podés sumarle el ecosistema **Gentle-AI** (skills, SDD, memoria persistente entre sesiones):

```bash
gentle-ai doctor
```

El `setup.sh` te ofrece instalarlo automáticamente al final, vía el script de bootstrap de `Gentleman-Programming/gentle-ai`.

## Actualizar

```bash
cd ~/dotfiles
git add -A && git commit -m "..." && git push
```

En la otra máquina:

```bash
cd ~/dotfiles && git pull && stow .
```

> Si `stow` tira "existing target is not owned by stow" en algún symlink (foreign symlink creado a mano, o el repo fue recreado), respaldá el real file a `*.pre-stow.bak` o borrá el foreign symlink, y reintentá. Ver bloque "3b" en `setup.sh` para los targets cubiertos.

### Docker

El script instala Docker y docker-compose, habilita el servicio y te agrega al grupo `docker`.
**Después de la primera ejecución, cerrá sesión y volvé a entrar** para poder usar `docker` sin sudo.

Verificá que funcione:

```bash
docker run hello-world
```

> ⚠️ Si no cerrás sesión, ejecutá `newgrp docker` en la terminal actual para activar el grupo sin reiniciar.

## Mantenimiento

### Limpiar dependencias huérfanas sin romper nada

```bash
cleanup
```

`pacman -Qtd` lista paquetes que fueron instalados como dependencia y ya no los requiere nada. Pero **esto incluye herramientas que usás directo** (`zip`, `jq`, `nodejs`, etc.) que en su momento fueron traídas por otro paquete.

Para evitar que `cleanup` te las borre, marcalas como explícitas **una sola vez**:

```bash
sudo pacman -D --asexplicit zip jq nodejs rust inetutils
```

Después de eso, `cleanup` solo va a mostrar dependencias y librerías reales que no necesita nadie.

### Previsualizar antes de borrar

```bash
pacman -Qtd
```


