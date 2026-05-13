# 1client_1server Certificate Overhead Report

- Generated at: `2026-05-11T08:47:43.237648+00:00`
- Input dir: `/home/lorenzo/Documents/Projects/Pk-IOTA/testbeds/1client_1server/overhead_cert_smoke2`
- Runs discovered: `1`
- TCP port: `4840`

## Quality Checks (`opcua_all_4840`)

| run | key_bits | same_ingress_count | drop_fw_pct | drop_ex_pct | rst_fw/rst_ex |
| --- | --- | --- | --- | --- | --- |
| 1 | 2048 | no | 0.000000 | 0.000000 | 0/0 |

## Summary (paired deltas, extraction - forward)

| key_bits | class | metric | n_pairs | forward | extraction | delta_abs | delta_pct | ci95 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2048 | opcua_opn | latency_mean_ms | 1 | 0.396013 | 0.631571 | 0.235558 | 59.482240 | [nan, nan] |
| 2048 | opcua_opn | latency_p95_ms | 1 | 0.431061 | 0.657082 | 0.226021 | 52.433628 | [nan, nan] |
| 2048 | opcua_opn | unmatched_ingress | 1 | 0.000000 | 0.000000 | 0.000000 | nan | [nan, nan] |
| 2048 | opcua_opn | drop_rate_pct | 1 | 0.000000 | 0.000000 | 0.000000 | nan | [nan, nan] |
| 2048 | opcua_other | latency_mean_ms | 1 | 0.353416 | 0.386318 | 0.032902 | 9.309647 | [nan, nan] |
| 2048 | opcua_other | latency_p95_ms | 1 | 0.560045 | 0.536919 | -0.023127 | -4.129417 | [nan, nan] |
| 2048 | opcua_other | unmatched_ingress | 1 | 0.000000 | 0.000000 | 0.000000 | nan | [nan, nan] |
| 2048 | opcua_other | drop_rate_pct | 1 | 0.000000 | 0.000000 | 0.000000 | nan | [nan, nan] |
| 2048 | opcua_all_4840 | latency_mean_ms | 1 | 0.364040 | 0.396073 | 0.032033 | 8.799249 | [nan, nan] |
| 2048 | opcua_all_4840 | latency_p95_ms | 1 | 1.074076 | 0.742912 | -0.331163 | -30.832408 | [nan, nan] |
| 2048 | opcua_all_4840 | unmatched_ingress | 1 | 0.000000 | 0.000000 | 0.000000 | nan | [nan, nan] |
| 2048 | opcua_all_4840 | drop_rate_pct | 1 | 0.000000 | 0.000000 | 0.000000 | nan | [nan, nan] |

Artifacts:
- `per_run.csv`
- `summary.csv`
- `report.md`
