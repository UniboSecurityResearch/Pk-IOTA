# Maynard Overhead Report

- Generated at: `2026-03-02T23:23:02.956333+00:00`
- Input dir: `/home/lorenzo/Documents/Projects/Pk-IOTA/testbeds/Maynard/overhead`
- Runs discovered: `1`

## Quality Checks (`opcua_all_8666`)

| run | same_ingress_count | drop_fw_pct | drop_ex_pct | rst_fw/rst_ex |
| --- | --- | --- | --- | --- |
| 1 | yes | 0.000000 | 0.000000 | 59074/59074 |

## Summary (paired deltas, extraction - forward)

| class | metric | n_pairs | forward | extraction | delta_abs | delta_pct | ci95 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| opcua_opn | latency_mean_ms | 1 | 0.062943 | -0.103378 | -0.166321 | -264.242424 | [nan, nan] |
| opcua_opn | latency_p95_ms | 1 | 0.581026 | 0.671864 | 0.090837 | 15.633976 | [nan, nan] |
| opcua_opn | unmatched_ingress | 1 | 0.000000 | 0.000000 | 0.000000 | nan | [nan, nan] |
| opcua_opn | drop_rate_pct | 1 | 0.000000 | 0.000000 | 0.000000 | nan | [nan, nan] |
| opcua_other | latency_mean_ms | 1 | 0.018132 | 0.026158 | 0.008026 | 44.261667 | [nan, nan] |
| opcua_other | latency_p95_ms | 1 | 0.517130 | 0.601053 | 0.083923 | 16.228677 | [nan, nan] |
| opcua_other | unmatched_ingress | 1 | 0.000000 | 0.000000 | 0.000000 | nan | [nan, nan] |
| opcua_other | drop_rate_pct | 1 | 0.000000 | 0.000000 | 0.000000 | nan | [nan, nan] |
| opcua_all_8666 | latency_mean_ms | 1 | 0.012461 | 0.019964 | 0.007502 | 60.203275 | [nan, nan] |
| opcua_all_8666 | latency_p95_ms | 1 | 0.483036 | 0.578880 | 0.095844 | 19.842053 | [nan, nan] |
| opcua_all_8666 | unmatched_ingress | 1 | 0.000000 | 0.000000 | 0.000000 | nan | [nan, nan] |
| opcua_all_8666 | drop_rate_pct | 1 | 0.000000 | 0.000000 | 0.000000 | nan | [nan, nan] |

Artifacts:
- `per_run.csv`
- `summary.csv`
- `report.md`
