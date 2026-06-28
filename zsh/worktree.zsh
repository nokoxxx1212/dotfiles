# ── Git Worktree ヘルパー ──────────────────────────────
# .zshrc から source して使う。wt / wto コマンドを提供する。

# 内部関数: .code-workspace を生成して VS Code で開く
_wt_internal() {
  local wt_path="$1"
  local branch="$2"
  local repo_root="$3"

  local ws_dir="${repo_root}/.claude/worktree-workspace"
  mkdir -p "$ws_dir"

  # ブランチ名ハッシュで色を決定
  local colors=("#1e3a5f" "#3a1e5f" "#5f1e3a" "#1e5f3a" "#5f3a1e" "#3a5f1e" "#1e555f" "#5f1e55")
  local hash
  hash=$(echo -n "$branch" | cksum | awk '{print $1}')
  local color="${colors[$((hash % ${#colors[@]} + 1))]}"

  # ディレクトリ名に変換したブランチ名で workspace ファイルを作成
  local safe_name="${branch//\//-}"
  local ws_file="${ws_dir}/${safe_name}.code-workspace"
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

# デフォルトブランチを自動検出する内部関数
_wt_default_branch() {
  local db
  db=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
  echo "${db:-main}"
}

# wt <branch> — worktree を作成して VS Code で開く
wt() {
  local branch="${1:?Usage: wt <branch-name>}"
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not a git repo"; return 1; }

  # ブランチ名の / を - に変換してディレクトリ名に使う
  local safe_branch="${branch//\//-}"
  local wt_path="${repo_root}/.claude/worktrees/${safe_branch}"

  # 既に存在すればそのまま開く
  if [[ -d "$wt_path" ]]; then
    _wt_internal "$wt_path" "$branch" "$repo_root"
    return 0
  fi

  mkdir -p "${repo_root}/.claude/worktrees"

  if git show-ref --verify --quiet "refs/heads/${branch}"; then
    # ローカルブランチが存在
    git worktree add "$wt_path" "$branch" || { echo "Failed to create worktree"; return 1; }
  elif git ls-remote --exit-code --heads origin "$branch" &>/dev/null; then
    # リモートのみに存在
    git worktree add --track -b "$branch" "$wt_path" "origin/${branch}" || { echo "Failed to create worktree"; return 1; }
  else
    # 新規ブランチ — デフォルトブランチをベースに作成
    local default_branch
    default_branch=$(_wt_default_branch)
    git worktree add -b "$branch" "$wt_path" "origin/${default_branch}" || { echo "Failed to create worktree"; return 1; }
  fi

  _wt_internal "$wt_path" "$branch" "$repo_root"
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
  # ディレクトリ名からではなく、git worktree list の出力からブランチ名を取得
  branch=$(echo "$selected" | sed 's/.*\[//' | sed 's/\]$//')

  _wt_internal "$wt_path" "$branch" "$repo_root"
}
