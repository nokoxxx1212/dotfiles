# AI Skills / エージェントスキル一覧

意思決定支援型のデータ分析を、PPDAC の5ステップで進めるためのスキルです。

## 成果物

```
analysis/<案件>/
  analysis.md        # 1-1 与件整理 / 1-2 実施概要 / 2 分析結果 / 3 グラフ集 / 4 Appendix
  data.ipynb         # 冒頭にサマリー（申し送り）
  analysis.ipynb     # 冒頭にサマリー（論点ごとの空・雨・傘）
```

- 章立てのテンプレートと用語集は [`analysis_common/`](./analysis_common/) にあります。

## スキル

| Step | PPDAC | スキル | 型 | 担当 |
| :--- | :--- | :--- | :--- | :--- |
| 1・2 | Problem・Plan | [`analysis_problem_plan`](./analysis_problem_plan/) | レビュー | analysis.md 1-1・1-2 |
| 3 | Data | [`analysis_data`](./analysis_data/) | 実行 | data.ipynb |
| 4 | Analysis | [`analysis_analysis`](./analysis_analysis/) | 実行 | analysis.ipynb |
| 5 | Conclusion | [`analysis_conclusion`](./analysis_conclusion/) | レビュー | analysis.md 2〜4 |

## 参照関係

- `analysis_data` は、analysis.md の 1-2② を読む。
- `analysis_analysis` は、analysis.md の 1-1②・1-2① と、data.ipynb のサマリーを読む。
- `analysis_conclusion` は、analysis.ipynb のサマリーを読み、1-1②（論点・意思決定）と突き合わせる。
