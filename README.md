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
| Sublime Text 4   | AUR (yay)    |
| LibreWolf        | AUR (yay)    |

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

## Estructura

```
~/.dotfiles/
├── setup.sh
├── librewolf/
│   └── user.js
├── .zshrc
├── .gitignore
└── README.md
```
