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

# ── Git Worktree ヘルパー ──────────────────────────────

# 内部関数: .code-workspace を生成して VS Code で開く
_wt_internal() {
  local wt_path="$1"
  local branch="$2"
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || return 1

  local ws_dir="${repo_root}/.claude/worktree-workspace"
  mkdir -p "$ws_dir"

  # ブランチ名ハッシュで色を決定
  local colors=("#1e3a5f" "#3a1e5f" "#5f1e3a" "#1e5f3a" "#5f3a1e" "#3a5f1e" "#1e555f" "#5f1e55")
  local hash
  hash=$(echo -n "$branch" | cksum | awk '{print $1}')
  local color="${colors[$((hash % ${#colors[@]} + 1))]}"

  local ws_file="${ws_dir}/${branch}.code-workspace"
  cat > "$ws_file" <<EOF
{
  "folders": [{ "path": "${wt_path}" }],
  "settings": {
    "workbench.colorCustomizations": {
      "titleBar.activeBackground": "${color}",
      "titleBar.activeForeground": "#ffffff",
      "titleBar.inactiveBackground": "${color}99",
      "titleBar.inactiveForeground": "#cccccc"
    }
  }
}
EOF
  code --new-window "$ws_file"
  echo "✔ worktree '${branch}' opened (color: ${color})"
}

# wt <branch> — worktree を作成して VS Code で開く (base: origin/main)
wt() {
  local branch="${1:?Usage: wt <branch-name>}"
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not a git repo"; return 1; }

  local wt_path="${repo_root}/.claude/worktrees/${branch}"

  # 既に存在すればそのまま開く
  if [[ -d "$wt_path" ]]; then
    _wt_internal "$wt_path" "$branch"
    return 0
  fi

  mkdir -p "${repo_root}/.claude/worktrees"

  if git show-ref --verify --quiet "refs/heads/${branch}"; then
    # ローカルブランチが存在
    git worktree add "$wt_path" "$branch"
  elif git ls-remote --exit-code --heads origin "$branch" &>/dev/null; then
    # リモートのみに存在
    git worktree add --track -b "$branch" "$wt_path" "origin/${branch}"
  else
    # 新規ブランチ — origin/main をベースに作成
    git worktree add -b "$branch" "$wt_path" origin/main
  fi

  _wt_internal "$wt_path" "$branch"
}

# wto — 既存の worktree を fzf で選んで開く
wto() {
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not a git repo"; return 1; }

  local selected
  selected=$(git worktree list \
    | grep "${repo_root}/.claude/worktrees/" \
    | fzf --prompt="Select worktree: " --height=10) || return 0

  local wt_path branch
  wt_path=$(echo "$selected" | awk '{print $1}')
  branch=$(basename "$wt_path")

  _wt_internal "$wt_path" "$branch"
}
