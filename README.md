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
| atuin            | repos oficiales |
| bat              | repos oficiales |
| fd               | repos oficiales |
| tmux             | repos oficiales |
| Zed              | repos oficiales |
| zsh-autosuggestions | repos oficiales |
| zsh-autocomplete | repos oficiales |
| zsh-syntax-highlighting | repos oficiales |
| carapace         | AUR (yay)    |
| Powerlevel10k    | AUR (yay)    |

### Apps opcionales (pregunta durante el setup)

| App              | Desde        |
|------------------|--------------|
| KeePassXC        | repos oficiales |
| Docker           | repos oficiales |
| LibreWolf        | AUR (yay)    |
| Zen Browser      | AUR (yay)    |
| fnm              | AUR (yay)    |
| pnpm             | AUR (yay)    |
| LocalSend        | AUR (yay)    |

> El CLI de Zed se instala como `zeditor`. El `setup.sh` crea automáticamente un symlink `zed → zeditor` en `/usr/local/bin/` para que puedas usar `zed` directamente.

### Tmux

La config de tmux está en `.tmux.conf` (stow lo linkea a `~/.tmux.conf`) con tema Kanagawa, navegación tipo vim, ventana flotante con `Alt+G`, y soporte de plugins via TPM. El `setup.sh` instala TPM automáticamente. Los plugins se instalan al abrir tmux con `Ctrl+A + I`.

## Actualizar

```bash
cd ~/dotfiles
git add -A && git commit -m "..." && git push
```

En la otra máquina:

```bash
cd ~/dotfiles && git pull && stow .
```

### LibreWolf

Después de la primera ejecución de `setup.sh`, **abrí LibreWolf una vez y cerrálo** para que se cree el perfil. Luego ejecutá de nuevo el script o linkeá manualmente:

```bash
ln -sf ~/dotfiles/librewolf/user.js ~/.librewolf/*.default*/user.js
```

Esto aplica tweaks de rendimiento para máquinas con poca RAM (procesos, descarga de pestañas, caché, precarga desactivada, etc).

### Docker

El script instala Docker y docker-compose, habilita el servicio y te agrega al grupo `docker`.
**Después de la primera ejecución, cerrá sesión y volvé a entrar** para poder usar `docker` sin sudo.

Verificá que funcione:

```bash
docker run hello-world
```

> ⚠️ Si no cerrás sesión, ejecutá `newgrp docker` en la terminal actual para activar el grupo sin reiniciar.

### Referencia rápida: default → nuevo

| Preferencia | Default | Nuevo | Qué hace |
|---|---|---|---|
| `dom.ipc.processCount` | `8` | `2` | Reduce procesos hijos de Firefox. **El que más RAM libera.** |
| `browser.tabs.unloadOnLowMemory` | `false` | `true` | Descarga pestañas de la RAM en vez de mantenerlas cargadas. |
| `browser.tabs.min_inactive_duration_interval_ms` | `300000` (5 min) | `600000` (10 min) | Tiempo sin tocar una pestaña antes de descargarla. |
| `browser.cache.memory.enable` | `true` | `true` | Usa caché en RAM (más rápido que disco). |
| `browser.cache.memory.capacity` | `5120` | `2048` | Límite de caché en RAM (2MB es suficiente). |
| `media.memory_cache_max_size` | `256000` | `65536` | Caché de video en RAM limitado a 64MB. |
| `network.predictor.enabled` | `true` | `false` | No predice qué páginas vas a visitar. |
| `network.prefetch-next` | `true` | `false` | No precarga enlaces anticipadamente. |
| `network.dns.disablePrefetch` | `false` | `true` | No resuelve DNS antes de tiempo. |
| `browser.places.speculativeConnect.enabled` | `true` | `false` | No abre conexiones especulativas. |
| `layers.acceleration.force-enabled` | `false` | `true` | Fuerza aceleración por hardware. |
| `browser.smoothScroll` | `true` | `false` | Desactiva scroll animado — más seco pero más rápido. |
| `privacy.clearOnShutdown.cache` | `true` | `true` | Limpia caché al cerrar. |
| `privacy.clearOnShutdown.cookies` | `true` | `true` | Limpia cookies al cerrar. |
| `privacy.clearOnShutdown.history` | `true` | `true` | Limpia historial al cerrar. |
| `privacy.sanitize.sanitizeOnShutdown` | `true` | `true` | Activa limpieza automática al cerrar. |

> **Si algo se rompe**: abrí `about:config`, buscá la preferencia, toccá en el lápiz/lapicito y poné el valor de Default. No hace falta reinstalar nada.

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


