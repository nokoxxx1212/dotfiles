#!/usr/bin/env python3
import os
import sys
import json
import time
from datetime import datetime

def main():
    # stdin から JSON を読み込む
    try:
        input_data = json.loads(sys.stdin.read())
    except Exception:
        input_data = {}

    session_id = input_data.get("session_id", "unknown_session")
    cost_obj = input_data.get("cost", {})
    session_cost = float(cost_obj.get("total_cost_usd", 0.0))

    # 保存先ディレクトリの作成 (~/.claude/)
    home_dir = os.path.expanduser("~")
    claude_dir = os.path.join(home_dir, ".claude")
    os.makedirs(claude_dir, exist_ok=True)
    history_file = os.path.join(claude_dir, "cost_history.json")

    # 履歴の読み込み
    history = {"sessions": {}}
    if os.path.exists(history_file):
        try:
            with open(history_file, "r") as f:
                history = json.load(f)
        except Exception:
            pass

    if "sessions" not in history:
        history["sessions"] = {}

    # セッション情報の更新
    now = time.time()
    history["sessions"][session_id] = {
        "last_updated": now,
        "cost_usd": session_cost
    }

    # 7日以上経過した古いセッションデータをクリーンアップ（604800秒）
    cutoff = now - 604800
    cleaned_sessions = {}
    for sid, data in history["sessions"].items():
        if data.get("last_updated", 0) > cutoff:
            cleaned_sessions[sid] = data
    history["sessions"] = cleaned_sessions

    # 履歴の書き込み
    try:
        with open(history_file, "w") as f:
            json.dump(history, f, indent=2)
    except Exception:
        pass

    # 今日（ローカル時間の00:00:00以降）の合計コストを計算
    now_dt = datetime.now()
    today_start_dt = now_dt.replace(hour=0, minute=0, second=0, microsecond=0)
    today_start_ts = today_start_dt.timestamp()

    daily_cost = 0.0
    for sid, data in history["sessions"].items():
        if data.get("last_updated", 0) >= today_start_ts:
            daily_cost += float(data.get("cost_usd", 0.0))

    # 直近5時間の合計コストを計算
    five_hours_ago = now - 5 * 3600
    five_hour_cost = 0.0
    for sid, data in history["sessions"].items():
        if data.get("last_updated", 0) >= five_hours_ago:
            five_hour_cost += float(data.get("cost_usd", 0.0))

    # 結果をJSONとして出力
    result = {
        "session_cost": f"${session_cost:.2f}",
        "daily_cost": f"${daily_cost:.2f}",
        "five_hour_cost": f"${five_hour_cost:.2f}"
    }
    print(json.dumps(result))

if __name__ == "__main__":
    main()
