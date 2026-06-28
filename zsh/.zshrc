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

# Git worktree を VS Code の別ウィンドウで開く（色を自動変更）
wt() {
  local branch="${1:?Usage: wt <branch-name>}"
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not a git repo"; return 1; }
  local wt_base="${repo_root}/.worktrees"
  local wt_path="${wt_base}/${branch}"

  # worktree がなければ作成
  if [[ ! -d "$wt_path" ]]; then
    mkdir -p "$wt_base"
    # ブランチが存在すればそのまま、なければ新規作成
    if git show-ref --verify --quiet "refs/heads/${branch}"; then
      git worktree add "$wt_path" "$branch"
    else
      git worktree add -b "$branch" "$wt_path"
    fi
  fi

  # worktree ごとに異なるタイトルバー色を設定
  local colors=("#1e3a5f" "#3a1e5f" "#5f1e3a" "#1e5f3a" "#5f3a1e" "#3a5f1e")
  local hash=$(echo -n "$branch" | cksum | awk '{print $1}')
  local color="${colors[$((hash % ${#colors[@]} + 1))]}"

  # worktree 用の VS Code 設定を作成
  mkdir -p "${wt_path}/.vscode"
  cat > "${wt_path}/.vscode/settings.json" <<EOF
{
  "workbench.colorCustomizations": {
    "titleBar.activeBackground": "${color}",
    "titleBar.activeForeground": "#ffffff",
    "titleBar.inactiveBackground": "${color}99",
    "titleBar.inactiveForeground": "#cccccc"
  }
}
EOF

  # 新しいウィンドウで開く
  code --new-window "$wt_path"
  echo "Opened worktree '${branch}' in new VS Code window (color: ${color})"
}
