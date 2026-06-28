#!/bin/bash
# Claude Code PreToolUse フック: Bash コマンドの自動許可 / 自動拒否
# stdin から JSON を受け取り、tool_input.command を解析して判定する。
#
# 判定:
#   自動許可 → exit 0
#   自動拒否 → exit 2 (stderr に理由)
#   ユーザーに確認 → JSON {"decision":"ask"} を stdout に出力して exit 0

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# コマンドが空なら何もしない (通常の承認フローに委ねる)
if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# ── 自動拒否: 明確に危険なパターン ──
DENY_PATTERNS=(
  'rm -rf /'
  'rm -rf ~'
  'rm -rf \.'
  'chmod 777'
  'chmod -R 777'
  'mkfs\.'
  'dd if='
  ':\(\)\{ :\|:& \};:'
  'sudo rm'
  '> /dev/sd'
  'mv .* /dev/null'
)

for pattern in "${DENY_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "Blocked: dangerous pattern '${pattern}' in: $COMMAND" >&2
    exit 2
  fi
done

# ── 自動許可: 安全な読み取り系コマンド ──
# 先頭のコマンド名を抽出 (パイプや && の前の最初のコマンド)
FIRST_CMD=$(echo "$COMMAND" | sed 's/[|&;].*//' | awk '{print $1}')

SAFE_COMMANDS=(
  ls cat head tail wc grep egrep fgrep rg
  find fd which where whereis type
  echo printf pwd date whoami hostname uname
  file stat du df free
  sort uniq tr cut sed awk
  diff comm
  tree eza
  jq yq
  man help
)

for safe in "${SAFE_COMMANDS[@]}"; do
  if [[ "$FIRST_CMD" == "$safe" ]]; then
    exit 0
  fi
done

# ── 自動許可: 安全な git サブコマンド ──
if [[ "$FIRST_CMD" == "git" ]]; then
  GIT_SUB=$(echo "$COMMAND" | sed 's/[|&;].*//' | awk '{print $2}')
  SAFE_GIT_SUBS=(
    status log diff branch show tag remote
    worktree stash ls-files ls-tree
    rev-parse rev-list describe
    shortlog reflog name-rev
    config
  )
  for sg in "${SAFE_GIT_SUBS[@]}"; do
    if [[ "$GIT_SUB" == "$sg" ]]; then
      exit 0
    fi
  done
fi

# ── それ以外: ユーザーに確認を委ねる ──
echo '{"decision":"ask"}'
exit 0
