# AI Skills / エージェントスキル一覧

ここでは、AIエージェントが自律的に実行またはレビューできる各スキルの概要をまとめています。

## 意思決定支援（Type1）データ分析 5ステップフレームワーク

データ分析プロジェクトにおいて、意思決定支援を行うためのパイプラインとして以下の4つのスキルが定義されています。各スキルは独立して動作しますが、組み合わせることで強力なプロセスを形成します。

| フェーズ (PPDAC) | 担当スキル (AIエージェント) | 役割の概要 |
| :--- | :--- | :--- |
| **Step 1: 課題設定** (Problem) | 🤖 [`analysis_proposal_review`](./analysis_proposal_review/) | ビジネス課題・ROIのキックオフ資料レビュー |
| **Step 2: 計画** (Plan) | 🤖 [`analysis_report_review`](./analysis_report_review/) | イシュー分解・空パケの設計レビュー (Phase 1) |
| **Step 3: データ収集** (Data) | 🤖 [`analysis_data_profiling_execute`](./analysis_data_profiling_execute/) | 自律的なデータの健康診断・プロファイリング |
| **Step 4: 分析** (Analysis) | 🤖 [`analysis_insight_execute`](./analysis_insight_execute/) | 比較を通じた「深いSo What」の抽出 |
| **Step 5: 結論** (Conclusion) | 🤖 [`analysis_report_review`](./analysis_report_review/) | 空雨傘・ロジックの最終報告レビュー (Phase 2) |

### Step 1: 課題設定（Problem）
👉 **[`analysis_proposal_review`](./analysis_proposal_review/)**
- **役割**: ビジネス課題から、分析の目的・スコープ・投資対効果を定義するキックオフ資料をレビューする。
- **ポイント**: KPIの厳密性、意思決定者の明記、撤退条件などを厳しくチェックし、分析の方向性を固める。

### Step 2 & 5: 計画（Plan）および 結論（Conclusion）
👉 **[`analysis_report_review`](./analysis_report_review/)**
- **役割**: 「分析設計書（Step 2）」としてスタートし、最後に「分析報告書（Step 5）」へと進化するリビングドキュメントをレビューする。
- **ポイント（Phase 1: 設計時）**: イシューが「問いの形式」に分解されているか、比較設計やサンプルサイズが妥当かを確認（空パケのレビュー）。
- **ポイント（Phase 2: 報告時）**: 抽出された「So What」が空雨傘のロジックで正しく接続されているか、相関と因果の取り違えがないかを厳格にチェック。

### Step 3: データ収集・プロファイリング（Data）
👉 **[`analysis_data_profiling_execute`](./analysis_data_profiling_execute/)**
- **役割**: テーブル定義から自律的にデータを抽出し、Step 4の分析に耐えうるかの健康診断（プロファイリング）を行う。
- **ポイント**: **【安全装置】**として、SQL実行前に必ずDry-RunやEXPLAINでスキャン量を見積もり、閾値超えの場合は人間の承認を要求する仕組みを搭載。
- **出力**: ER構造やビジネスルールの推測結果、およびStep 4への「申し送り事項・アラート」を含むデータカタログ。

### Step 4: 分析（Analysis）
👉 **[`analysis_insight_execute`](./analysis_insight_execute/)**
- **役割**: クリーンなデータを用いて、比較（A/B、時系列、セグメント等）を通じてイシューに白黒つける。
- **ポイント**: 単なる集計や「観察レベルのSo What」を禁止。「なぜそうなったか？次に何をすべきか？」という**「深い洞察レベルのSo What」**を抽出させるよう指示を強化。

---
※今後、新たなスキル（業務自動化など）を追加した際も、本READMEに追記して全体像を管理します。
