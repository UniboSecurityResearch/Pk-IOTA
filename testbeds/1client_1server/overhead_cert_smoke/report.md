# 1client_1server Certificate Overhead Report

- Generated at: `2026-05-11T08:45:15.865866+00:00`
- Input dir: `/home/lorenzo/Documents/Projects/Pk-IOTA/testbeds/1client_1server/overhead_cert_smoke`
- Runs discovered: `2`
- TCP port: `4840`

## Quality Checks (`opcua_all_4840`)

| run | key_bits | same_ingress_count | drop_fw_pct | drop_ex_pct | rst_fw/rst_ex |
| --- | --- | --- | --- | --- | --- |
| 1 | 2048 | missing variant | n/a | n/a | n/a |
| 2 | 2048 | missing variant | n/a | n/a | n/a |

## Summary (paired deltas, extraction - forward)

| key_bits | class | metric | n_pairs | forward | extraction | delta_abs | delta_pct | ci95 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2048 | opcua_opn | latency_mean_ms | 0 | nan | nan | nan | nan | [nan, nan] |
| 2048 | opcua_opn | latency_p95_ms | 0 | nan | nan | nan | nan | [nan, nan] |
| 2048 | opcua_opn | unmatched_ingress | 0 | nan | nan | nan | nan | [nan, nan] |
| 2048 | opcua_opn | drop_rate_pct | 0 | nan | nan | nan | nan | [nan, nan] |
| 2048 | opcua_other | latency_mean_ms | 0 | nan | nan | nan | nan | [nan, nan] |
| 2048 | opcua_other | latency_p95_ms | 0 | nan | nan | nan | nan | [nan, nan] |
| 2048 | opcua_other | unmatched_ingress | 0 | nan | nan | nan | nan | [nan, nan] |
| 2048 | opcua_other | drop_rate_pct | 0 | nan | nan | nan | nan | [nan, nan] |
| 2048 | opcua_all_4840 | latency_mean_ms | 0 | nan | nan | nan | nan | [nan, nan] |
| 2048 | opcua_all_4840 | latency_p95_ms | 0 | nan | nan | nan | nan | [nan, nan] |
| 2048 | opcua_all_4840 | unmatched_ingress | 0 | nan | nan | nan | nan | [nan, nan] |
| 2048 | opcua_all_4840 | drop_rate_pct | 0 | nan | nan | nan | nan | [nan, nan] |

Artifacts:
- `per_run.csv`
- `summary.csv`
- `report.md`
