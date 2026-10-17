#!/bin/bash
# Claude Code PreToolUse フック: BigQuery スキャン量ガード
# stdin から JSON を受け取り、tool_input.command が `bq query` の場合に
# --dry_run で推定スキャン量を取得し、閾値を超える場合は実行を拒否する。
#
# 判定:
#   対象外 / 閾値以内 → exit 0
#   閾値超過 → exit 2 (stderr に理由)
#   見積もり不能 → JSON {"decision":"ask"} を stdout に出力して exit 0
#
# 閾値: 環境変数 BQ_MAX_SCAN_GB (既定 1)。1GB = 1024^3 bytes。

INPUT=$(cat)
COMMAND=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' <<< "$INPUT")

# コマンドが空なら対象外
if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# ── 対象判定: bq query 以外は対象外 ──
if ! echo "$COMMAND" | grep -qE '^\s*bq\s' || ! echo "$COMMAND" | grep -qE '(^|\s)query(\s|$)'; then
  exit 0
fi

# 既に --dry_run が付いているものは実行されても課金されない
if echo "$COMMAND" | grep -qE '(^|\s)--dry_run(=true)?(\s|$)'; then
  exit 0
fi

# ── 複合コマンド（パイプ・チェーン・コマンド置換）は見積もり用の再実行が危険なのでユーザーに確認 ──
if echo "$COMMAND" | grep -qE '[|&;`]|\$\('; then
  echo '{"decision":"ask","reason":"bq query: 複合コマンドのためスキャン量を見積もれません"}'
  exit 0
fi

# ── dry-run で推定スキャン量を取得 ──
DRY_COMMAND=$(sed -E '0,/(^|[[:space:]])query([[:space:]]|$)/s//\1query --dry_run\2/' <<< "$COMMAND")
DRY_OUTPUT=$(bash -c "$DRY_COMMAND" 2>&1)

BYTES=$(echo "$DRY_OUTPUT" | grep -oE '[0-9]+ bytes' | head -1 | grep -oE '[0-9]+')
if [[ -z "$BYTES" ]]; then
  BYTES=$(echo "$DRY_OUTPUT" | grep -oE '"totalBytesProcessed": *"[0-9]+"' | head -1 | grep -oE '[0-9]+')
fi

if [[ -z "$BYTES" ]]; then
  echo '{"decision":"ask","reason":"bq query: スキャン量を取得できませんでした"}'
  exit 0
fi

# ── 閾値判定 ──
MAX_GB="${BQ_MAX_SCAN_GB:-1}"
if awk -v b="$BYTES" -v g="$MAX_GB" 'BEGIN { exit !(b > g * 1024 * 1024 * 1024) }'; then
  GB=$(awk -v b="$BYTES" 'BEGIN { printf "%.2f", b / 1024 / 1024 / 1024 }')
  echo "Blocked: bq query の推定スキャン量 ${GB}GB が閾値 ${MAX_GB}GB を超えています。実行せず、ユーザーに許可を求めてください。" >&2
  exit 2
fi

exit 0
