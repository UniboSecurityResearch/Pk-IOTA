# 1client_1server Certificate Overhead Report

- Generated at: `2026-07-08T14:14:32.657489+00:00`
- Input dir: `/root/lorenzino/Pk-IOTA/tests/TESTBEDS/cert_size_overhead_smoke2`
- TCP port: `4840`
- Capture units discovered: `3`

## Quality

| run | key_bits | variants | status | reasons |
| --- | --- | --- | --- | --- |
| 1 | 2048 | extraction,ip_forward,opcua_forward | pass | ok |

## Summary Deltas

| key_bits | class | metric | delta | n_pairs | baseline | candidate | delta_abs | delta_pct |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2048 | opcua_opn_cert | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.231075 | 0.396252 | 0.165176 | 71.481634 |
| 2048 | opcua_opn_cert | latency_mean_ms | extraction - opcua_forward | 1 | 0.396252 | 0.581193 | 0.184941 | 46.672684 |
| 2048 | opcua_opn_cert | latency_mean_ms | extraction - ip_forward | 1 | 0.231075 | 0.581193 | 0.350118 | 151.516715 |
| 2048 | opcua_opn_cert | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.270844 | 0.473022 | 0.202179 | 74.647887 |
| 2048 | opcua_opn_cert | latency_p95_ms | extraction - opcua_forward | 1 | 0.473022 | 0.889063 | 0.416040 | 87.953629 |
| 2048 | opcua_opn_cert | latency_p95_ms | extraction - ip_forward | 1 | 0.270844 | 0.889063 | 0.618219 | 228.257042 |
| 2048 | opcua_opn_cert | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| 2048 | opcua_opn_cert | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| 2048 | opcua_opn_cert | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| 2048 | opcua_opn_cert | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| 2048 | opcua_opn_cert | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| 2048 | opcua_opn_cert | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| 2048 | opcua_opn_no_cert | latency_mean_ms | opcua_forward - ip_forward | 0 | nan | nan | nan | nan |
| 2048 | opcua_opn_no_cert | latency_mean_ms | extraction - opcua_forward | 0 | nan | nan | nan | nan |
| 2048 | opcua_opn_no_cert | latency_mean_ms | extraction - ip_forward | 0 | nan | nan | nan | nan |
| 2048 | opcua_opn_no_cert | latency_p95_ms | opcua_forward - ip_forward | 0 | nan | nan | nan | nan |
| 2048 | opcua_opn_no_cert | latency_p95_ms | extraction - opcua_forward | 0 | nan | nan | nan | nan |
| 2048 | opcua_opn_no_cert | latency_p95_ms | extraction - ip_forward | 0 | nan | nan | nan | nan |
| 2048 | opcua_opn_no_cert | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| 2048 | opcua_opn_no_cert | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| 2048 | opcua_opn_no_cert | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| 2048 | opcua_opn_no_cert | drop_rate_pct | opcua_forward - ip_forward | 0 | nan | nan | nan | nan |
| 2048 | opcua_opn_no_cert | drop_rate_pct | extraction - opcua_forward | 0 | nan | nan | nan | nan |
| 2048 | opcua_opn_no_cert | drop_rate_pct | extraction - ip_forward | 0 | nan | nan | nan | nan |
| 2048 | opcua_other | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.219205 | 0.371009 | 0.151805 | 69.252610 |
| 2048 | opcua_other | latency_mean_ms | extraction - opcua_forward | 1 | 0.371009 | 0.377444 | 0.006435 | 1.734401 |
| 2048 | opcua_other | latency_mean_ms | extraction - ip_forward | 1 | 0.219205 | 0.377444 | 0.158240 | 72.188130 |
| 2048 | opcua_other | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.286818 | 0.416994 | 0.130177 | 45.386534 |
| 2048 | opcua_other | latency_p95_ms | extraction - opcua_forward | 1 | 0.416994 | 0.550032 | 0.133038 | 31.903945 |
| 2048 | opcua_other | latency_p95_ms | extraction - ip_forward | 1 | 0.286818 | 0.550032 | 0.263214 | 91.770574 |
| 2048 | opcua_other | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| 2048 | opcua_other | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| 2048 | opcua_other | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| 2048 | opcua_other | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| 2048 | opcua_other | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| 2048 | opcua_other | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| 2048 | opcua_all_4840 | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.225810 | 0.352425 | 0.126615 | 56.071418 |
| 2048 | opcua_all_4840 | latency_mean_ms | extraction - opcua_forward | 1 | 0.352425 | 0.379755 | 0.027330 | 7.754825 |
| 2048 | opcua_all_4840 | latency_mean_ms | extraction - ip_forward | 1 | 0.225810 | 0.379755 | 0.153945 | 68.174483 |
| 2048 | opcua_all_4840 | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.299931 | 0.449896 | 0.149965 | 50.000000 |
| 2048 | opcua_all_4840 | latency_p95_ms | extraction - opcua_forward | 1 | 0.449896 | 0.576973 | 0.127077 | 28.245893 |
| 2048 | opcua_all_4840 | latency_p95_ms | extraction - ip_forward | 1 | 0.299931 | 0.576973 | 0.277042 | 92.368839 |
| 2048 | opcua_all_4840 | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| 2048 | opcua_all_4840 | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| 2048 | opcua_all_4840 | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| 2048 | opcua_all_4840 | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| 2048 | opcua_all_4840 | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| 2048 | opcua_all_4840 | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |

Artifacts:
- `per_run.csv`
- `summary.csv`
- `quality.csv`
- `report.md`
