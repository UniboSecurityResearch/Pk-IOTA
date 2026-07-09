# Maynard Overhead Report

- Generated at: `2026-07-08T14:00:40.960262+00:00`
- Input dir: `/root/lorenzino/Pk-IOTA/tests/TESTBEDS/maynard_overhead_smoke2`
- TCP port: `8666`
- Capture units discovered: `3`

## Quality

| run | variants | status | reasons |
| --- | --- | --- | --- |
| 1 | extraction,ip_forward,opcua_forward | pass | ok |

## Summary Deltas

| class | metric | delta | n_pairs | baseline | candidate | delta_abs | delta_pct |
| --- | --- | --- | --- | --- | --- | --- | --- |
| opcua_opn_cert | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.219375 | 0.329977 | 0.110602 | 50.417063 |
| opcua_opn_cert | latency_mean_ms | extraction - opcua_forward | 1 | 0.329977 | 0.601250 | 0.271273 | 82.209498 |
| opcua_opn_cert | latency_mean_ms | extraction - ip_forward | 1 | 0.219375 | 0.601250 | 0.381875 | 174.074175 |
| opcua_opn_cert | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.278950 | 0.429153 | 0.150204 | 53.846154 |
| opcua_opn_cert | latency_p95_ms | extraction - opcua_forward | 1 | 0.429153 | 0.806093 | 0.376940 | 87.833333 |
| opcua_opn_cert | latency_p95_ms | extraction - ip_forward | 1 | 0.278950 | 0.806093 | 0.527143 | 188.974359 |
| opcua_opn_cert | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_opn_cert | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_opn_cert | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_opn_cert | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_opn_cert | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_opn_cert | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_opn_no_cert | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.225687 | 0.345635 | 0.119948 | 53.148109 |
| opcua_opn_no_cert | latency_mean_ms | extraction - opcua_forward | 1 | 0.345635 | 0.464702 | 0.119066 | 34.448507 |
| opcua_opn_no_cert | latency_mean_ms | extraction - ip_forward | 1 | 0.225687 | 0.464702 | 0.239015 | 105.905345 |
| opcua_opn_no_cert | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.287056 | 0.449181 | 0.162125 | 56.478405 |
| opcua_opn_no_cert | latency_p95_ms | extraction - opcua_forward | 1 | 0.449181 | 0.552893 | 0.103712 | 23.089172 |
| opcua_opn_no_cert | latency_p95_ms | extraction - ip_forward | 1 | 0.287056 | 0.552893 | 0.265837 | 92.607973 |
| opcua_opn_no_cert | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_opn_no_cert | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_opn_no_cert | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_opn_no_cert | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_opn_no_cert | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_opn_no_cert | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_other | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.213066 | 0.313697 | 0.100631 | 47.230006 |
| opcua_other | latency_mean_ms | extraction - opcua_forward | 1 | 0.313697 | 0.320897 | 0.007200 | 2.295108 |
| opcua_other | latency_mean_ms | extraction - ip_forward | 1 | 0.213066 | 0.320897 | 0.107831 | 50.609093 |
| opcua_other | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.276089 | 0.399113 | 0.123024 | 44.559585 |
| opcua_other | latency_p95_ms | extraction - opcua_forward | 1 | 0.399113 | 0.425100 | 0.025988 | 6.511350 |
| opcua_other | latency_p95_ms | extraction - ip_forward | 1 | 0.276089 | 0.425100 | 0.149012 | 53.972366 |
| opcua_other | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_other | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_other | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_other | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_other | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_other | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_all_8666 | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.213079 | 0.313730 | 0.100651 | 47.236560 |
| opcua_all_8666 | latency_mean_ms | extraction - opcua_forward | 1 | 0.313730 | 0.321325 | 0.007594 | 2.420699 |
| opcua_all_8666 | latency_mean_ms | extraction - ip_forward | 1 | 0.213079 | 0.321325 | 0.108246 | 50.800713 |
| opcua_all_8666 | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.276089 | 0.399113 | 0.123024 | 44.559585 |
| opcua_all_8666 | latency_p95_ms | extraction - opcua_forward | 1 | 0.399113 | 0.426054 | 0.026941 | 6.750299 |
| opcua_all_8666 | latency_p95_ms | extraction - ip_forward | 1 | 0.276089 | 0.426054 | 0.149965 | 54.317789 |
| opcua_all_8666 | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_all_8666 | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_all_8666 | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_all_8666 | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_all_8666 | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_all_8666 | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |

Artifacts:
- `per_run.csv`
- `summary.csv`
- `quality.csv`
- `report.md`
