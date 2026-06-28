#!/bin/bash
# Claude Code PreToolUse フック: Bash コマンドの自動許可 / 自動拒否
# stdin から JSON を受け取り、tool_input.command を解析して判定する。
#
# 判定:
#   自動許可 → exit 0
#   自動拒否 → exit 2 (stderr に理由)
#   ユーザーに確認 → JSON {"decision":"ask"} を stdout に出力して exit 0

INPUT=$(cat)
COMMAND=$(jq -r '.tool_input.command // empty' <<< "$INPUT")

# コマンドが空なら判断できないのでユーザーに確認を委ねる
if [[ -z "$COMMAND" ]]; then
  echo '{"decision":"ask"}'
  exit 0
fi

# ── 自動拒否: 明確に危険なパターン ──
# コマンド全体に対してチェック（パイプ・チェーン含む）
DENY_PATTERNS=(
  'rm\s+-[a-zA-Z]*r[a-zA-Z]*f'   # rm -rf, rm -fr 等
  'rm\s+-[a-zA-Z]*f[a-zA-Z]*r'
  'sudo\s+'                        # sudo 全般
  'chmod\s+(-R\s+)?0?777'          # chmod 777 / chmod 0777
  'mkfs'
  'dd\s+'                          # dd 全般
  ':\(\)\{.*\};:'                  # fork bomb
  '>\s*/dev/(sd|disk|nvme)'        # デバイスへの直接書き込み
  'mv\s+.*\s+/dev/null'
  'curl.*\|\s*(bash|sh|zsh)'       # curl | bash パターン
  'wget.*\|\s*(bash|sh|zsh)'       # wget | bash パターン
)

for pattern in "${DENY_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "Blocked: dangerous pattern '${pattern}' in: $COMMAND" >&2
    exit 2
  fi
done

# ── 複合コマンド（パイプ・チェーン・セミコロン）はユーザーに確認 ──
# 拒否パターンに該当しなくても、複合コマンドは先頭だけでは安全性を判断できない
if echo "$COMMAND" | grep -qE '[|&;]'; then
  echo '{"decision":"ask"}'
  exit 0
fi

# ── 自動許可: 安全な読み取り系コマンド（単体のみ） ──
FIRST_CMD=$(awk '{print $1}' <<< "$COMMAND")

SAFE_COMMANDS=(
  ls cat head tail wc grep egrep fgrep rg
  find fd which where whereis type
  echo printf pwd date whoami hostname uname
  file stat du df free
  sort uniq tr cut
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

# ── 自動許可: 安全な git 読み取り専用サブコマンド ──
if [[ "$FIRST_CMD" == "git" ]]; then
  GIT_SUB=$(awk '{print $2}' <<< "$COMMAND")
  SAFE_GIT_SUBS=(
    status log diff show tag
    branch remote
    ls-files ls-tree
    rev-parse rev-list describe
    shortlog reflog name-rev
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
