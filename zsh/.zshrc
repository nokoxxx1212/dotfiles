export PATH="/opt/homebrew/bin:$PATH"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

### zinit
source ~/.zsh/zinit.git/zinit.zsh

# 補完 & 色づけ
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
# fzf-tab: <Tab> 補完を fzf 化
zinit light Aloxaf/fzf-tab

# ツール初期化
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

# direnv（ディレクトリ毎に環境を自動切替）
eval "$(direnv hook zsh)"

# エイリアス
alias ls='eza --group-directories-first --icons'

# Ctrl-f で最近のファイルを fzf から開く
fzf-open-file() {
  local file
  file=$(fd . -t f | fzf) || return
  code "$file"
}
zle -N fzf-open-file
bindkey '^F' fzf-open-file

# Ctrl-b で Git ブランチ切替
fzf-git-switch() {
  local b
  b=$(git for-each-ref --format='%(refname:short)' refs/heads/ | fzf) || return
  git switch "$b"
}
zle -N fzf-git-switch
bindkey '^B' fzf-git-switch

# Git Worktree ヘルパー (wt / wto)
source "${0:A:h}/worktree.zsh"
