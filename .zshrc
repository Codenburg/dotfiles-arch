# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

# ─── History (CachyOS-style) ──────────────────────────────────────────────
export HISTCONTROL=ignoreboth
export HISTORY_IGNORE="(\&|[bf]g|c|clear|history|exit|q|pwd|* --help)"
export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

# ─── PATH ───────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$HOME/.cargo/bin:/usr/local/bin:/usr/bin:$PATH"

# ─── Editor ──────────────────────────────────────────────────────────────────
export EDITOR="zed"
export VISUAL="zed"

# ─── ls colors ───────────────────────────────────────────────────────────────
export LS_COLORS="di=38;5;67:ow=48;5;60:ex=38;5;132:ln=38;5;144:*.tar=38;5;180:*.zip=38;5;180:*.jpg=38;5;175:*.png=38;5;175:*.mp3=38;5;175:*.wav=38;5;175:*.txt=38;5;223:*.sh=38;5;132"
alias ls='ls --color=auto'

# ─── Homebrew (presente pero los binarios nativos de Arch tienen prioridad) ──
if [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# ─── Zsh plugins — Arch nativo ──────────────────────────────────────────────
source /usr/share/zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ─── Powerlevel10k ──────────────────────────────────────────────────────────
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme

# ─── Proyectos ────────────────────────────────────────────────────────────────
export PROJECT_DIR="$HOME/Codenburg"

# ─── FZF ─────────────────────────────────────────────────────────────────────
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# ─── Tmux auto-start ────────────────────────────────────────────────────────
function start_if_needed() {
    if [[ $- == *i* ]] && [[ -z "$TMUX" ]] && [[ -t 1 ]]; then
        exec tmux
    fi
}

# ─── Aliases ─────────────────────────────────────────────────────────────────
alias fzfbat='fzf --preview="bat --theme=gruvbox-dark --color=always {}"'
alias fzfzed='zed $(fzf --preview="bat --theme=gruvbox-dark --color=always {}")'
alias cleanup='sudo pacman -Rns $(pacman -Qtdq)'
alias pkg-add='sudo pacman -Syu'
alias pkg-rm='sudo pacman -Rns'
alias pkg-search='pacman -Ss'
alias pkg-local='pacman -Qs'
alias pkg-info='pacman -Si'
alias pkg-clean='sudo pacman -Sc'
alias sys-update='sudo pacman -Syu'
alias npm="pnpm"
alias yall='yay -Sua'
alias aur-add='yay -S --needed'
alias aur-search='yay -Ss'
alias aur-info='yay -Si'
alias aur-clean='yay -Yc'

# ─── CachyOS-style extras ──────────────────────────────────────────────────
alias c="clear"
alias make="make -j\`nproc\`"
alias ninja="ninja -j\`nproc\`"
alias n="ninja"
alias cleanch="sudo pacman -Scc"
alias fixpacman="sudo rm /var/lib/pacman/db.lck"
alias jctl="journalctl -p 3 -xb"
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"
alias tb="nc termbin.com 9999"
alias apt="man pacman"
alias apt-get="man pacman"
alias please="sudo"

# ─── Oh My Zsh ───────────────────────────────────────────────────────────────
plugins=(command-not-found)
source $ZSH/oh-my-zsh.sh

# ─── Carapace ────────────────────────────────────────────────────────────────
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
source <(carapace _carapace)

# ─── FZF, Zoxide, Atuin ──────────────────────────────────────────────────────
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"
eval "$(atuin init zsh)"

# ─── Powerlevel10k user config ───────────────────────────────────────────────
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

start_if_needed
