# AI Skills / エージェントスキル一覧

意思決定支援型のデータ分析を、PPDAC の5ステップで進めるためのスキルです。

## 成果物

```
analysis/<案件>/
  analysis.md
  data.ipynb
  analysis.ipynb
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
- `analysis_analysis` は、analysis.md の 1-1② と 1-2①、data.ipynb のサマリーを読む。
- `analysis_conclusion` は、analysis.ipynb のサマリーを読み、1-1② のイシューと意思決定に照らして評価する。
