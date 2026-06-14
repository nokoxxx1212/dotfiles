#!/bin/bash
export PATH="/opt/homebrew/bin:$PATH"
# Claude Code ステータスライン
# stdin から JSON を受け取り、フォーマットして stdout に出力
#
# 表示例:
#   main | claude-sonnet-4 | high
#   ctx:45% | 5h:12% | 7d:3%

jq -r '
  # 1行目: ブランチ名 | モデル名 | effort
  def line1:
    [
      (.git.branch // empty),
      (.model.display_name // empty),
      (.effort.level // empty)
    ] | join(" | ");

  # 2行目: ctx使用率 | 5h使用率 | 7d使用率
  def line2:
    [
      ("ctx:" + ((.context_window.used_percentage // 0) | tostring) + "%"),
      ("5h:" + ((.rate_limits.five_hour.used_percentage // 0) | tostring) + "%"),
      ("7d:" + ((.rate_limits.seven_day.used_percentage // 0) | tostring) + "%")
    ] | join(" | ");

  [line1, line2] | map(select(. != "")) | join("\n")
'
