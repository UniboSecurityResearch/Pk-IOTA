# Maynard Overhead Report

- Generated at: `2026-03-05T10:43:07.714600+00:00`
- Input dir: `/home/lorenzo/Documents/Projects/Pk-IOTA/testbeds/Maynard/overhead_10`
- Runs discovered: `10`

## Quality Checks (`opcua_all_8666`)

| run | same_ingress_count | drop_fw_pct | drop_ex_pct | rst_fw/rst_ex |
| --- | --- | --- | --- | --- |
| 1 | yes | 0.000000 | 0.000000 | 59074/59074 |
| 2 | no | 0.000000 | 0.000000 | 59072/59074 |
| 3 | yes | 0.000000 | 0.000000 | 59074/59074 |
| 4 | yes | 0.000000 | 0.000000 | 59074/59074 |
| 5 | yes | 0.000000 | 0.000000 | 59074/59074 |
| 6 | no | 0.000000 | 0.000000 | 59074/59072 |
| 7 | yes | 0.000000 | 0.000000 | 59074/59074 |
| 8 | no | 0.000000 | 0.000000 | 59074/59072 |
| 9 | yes | 0.000000 | 0.000000 | 59074/59074 |
| 10 | yes | 0.000000 | 0.000000 | 59074/59074 |

## Summary (paired deltas, extraction - forward)

| class | metric | n_pairs | forward | extraction | delta_abs | delta_pct | ci95 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| opcua_opn | latency_mean_ms | 10 | -0.004027 | 0.000870 | 0.004897 | -121.610420 | [-0.127080, 0.136875] |
| opcua_opn | latency_p95_ms | 10 | 1.314306 | 0.766468 | -0.547838 | -41.682691 | [-2.640127, 1.544450] |
| opcua_opn | unmatched_ingress | 10 | 0.000000 | 0.000000 | 0.000000 | nan | [0.000000, 0.000000] |
| opcua_opn | drop_rate_pct | 10 | 0.000000 | 0.000000 | 0.000000 | nan | [0.000000, 0.000000] |
| opcua_other | latency_mean_ms | 10 | 0.025484 | 0.016541 | -0.008943 | -35.092211 | [-0.018866, 0.000980] |
| opcua_other | latency_p95_ms | 10 | 0.472116 | 0.598145 | 0.126028 | 26.694273 | [0.115817, 0.136239] |
| opcua_other | unmatched_ingress | 10 | 0.000000 | 0.000000 | 0.000000 | nan | [0.000000, 0.000000] |
| opcua_other | drop_rate_pct | 10 | 0.000000 | 0.000000 | 0.000000 | nan | [0.000000, 0.000000] |
| opcua_all_8666 | latency_mean_ms | 10 | 0.014632 | 0.016260 | 0.001628 | 11.127453 | [-0.003859, 0.007115] |
| opcua_all_8666 | latency_p95_ms | 10 | 0.448918 | 0.573707 | 0.124788 | 27.797546 | [0.114927, 0.134650] |
| opcua_all_8666 | unmatched_ingress | 10 | 0.000000 | 0.000000 | 0.000000 | nan | [0.000000, 0.000000] |
| opcua_all_8666 | drop_rate_pct | 10 | 0.000000 | 0.000000 | 0.000000 | nan | [0.000000, 0.000000] |

Artifacts:
- `per_run.csv`
- `summary.csv`
- `report.md`
