#!/bin/bash
export PATH="/opt/homebrew/bin:$PATH"
# Claude Code ステータスライン
# stdin から JSON を受け取り、フォーマットして stdout に出力
#
# 表示例:
#   main | claude-sonnet-4 | effort:high
#   ctx:45% | 5h:12% | 7d:3% | cost:Today $1.20 (5h:$0.45)

# 入力データを変数に保持
INPUT=$(cat)

# コスト情報の計算スクリプトを実行
COST_JSON=$(echo "$INPUT" | python3 "$(dirname "$0")/hooks/calc-daily-cost.py" 2>/dev/null)

# ステータスラインを構築して出力
echo "$INPUT" | jq -r --argjson cost "$COST_JSON" '
  # 1行目: ブランチ名 | モデル名 | effort
  def line1:
    [
      (.git.branch // empty),
      (.model.display_name // empty),
      (if .effort.level != null then "effort:" + .effort.level else empty end)
    ] | join(" | ");

  # 2行目: ctx使用率 | 5h使用率 | 7d使用率 | コスト
  def line2:
    [
      ("ctx:" + ((.context_window.used_percentage // 0) | tostring) + "%"),
      ("5h:" + ((.rate_limits.five_hour.used_percentage // 0) | tostring) + "%"),
      ("7d:" + ((.rate_limits.seven_day.used_percentage // 0) | tostring) + "%"),
      (if $cost.daily_cost != null then "cost:Today " + $cost.daily_cost + " (5h:" + $cost.five_hour_cost + ")" else empty end)
    ] | join(" | ");

  [line1, line2] | map(select(. != "")) | join("\n")
'

