# Maynard Overhead Report

- Generated at: `2026-07-08T10:03:25.460829+00:00`
- Input dir: `/root/lorenzino/Pk-IOTA/tests/TESTBEDS/maynard_overhead_smoke`
- TCP port: `8666`
- Capture units discovered: `3`

## Quality

| run | variants | status | reasons |
| --- | --- | --- | --- |
| 1 | extraction,ip_forward,opcua_forward | fail | extraction:drop=19.073367;opcua_forward:drop=17.954784 |

## Summary Deltas

| class | metric | delta | n_pairs | baseline | candidate | delta_abs | delta_pct |
| --- | --- | --- | --- | --- | --- | --- | --- |
| opcua_opn_cert | latency_mean_ms | opcua_forward - ip_forward | 1 | 2.561975 | 185.493939 | 182.931965 | 7140.272580 |
| opcua_opn_cert | latency_mean_ms | extraction - opcua_forward | 1 | 185.493939 | 135.020472 | -50.473467 | -27.210305 |
| opcua_opn_cert | latency_mean_ms | extraction - ip_forward | 1 | 2.561975 | 135.020472 | 132.458498 | 5170.172313 |
| opcua_opn_cert | latency_p95_ms | opcua_forward - ip_forward | 1 | 20.331860 | 462.157965 | 441.826105 | 2173.072774 |
| opcua_opn_cert | latency_p95_ms | extraction - opcua_forward | 1 | 462.157965 | 448.765993 | -13.391972 | -2.897704 |
| opcua_opn_cert | latency_p95_ms | extraction - ip_forward | 1 | 20.331860 | 448.765993 | 428.434134 | 2107.205844 |
| opcua_opn_cert | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 6.000000 | 6.000000 | nan |
| opcua_opn_cert | unmatched_ingress | extraction - opcua_forward | 1 | 6.000000 | 8.000000 | 2.000000 | 33.333333 |
| opcua_opn_cert | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 8.000000 | 8.000000 | nan |
| opcua_opn_cert | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 15.000000 | 15.000000 | nan |
| opcua_opn_cert | drop_rate_pct | extraction - opcua_forward | 1 | 15.000000 | 20.000000 | 5.000000 | 33.333333 |
| opcua_opn_cert | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 20.000000 | 20.000000 | nan |
| opcua_opn_no_cert | latency_mean_ms | opcua_forward - ip_forward | 1 | 9.026837 | 178.881907 | 169.855070 | 1881.667560 |
| opcua_opn_no_cert | latency_mean_ms | extraction - opcua_forward | 1 | 178.881907 | 75.966716 | -102.915192 | -57.532477 |
| opcua_opn_no_cert | latency_mean_ms | extraction - ip_forward | 1 | 9.026837 | 75.966716 | 66.939878 | 741.565134 |
| opcua_opn_no_cert | latency_p95_ms | opcua_forward - ip_forward | 1 | 22.284985 | 403.143883 | 380.858898 | 1709.038194 |
| opcua_opn_no_cert | latency_p95_ms | extraction - opcua_forward | 1 | 403.143883 | 169.899940 | -233.243942 | -57.856252 |
| opcua_opn_no_cert | latency_p95_ms | extraction - ip_forward | 1 | 22.284985 | 169.899940 | 147.614956 | 662.396491 |
| opcua_opn_no_cert | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_opn_no_cert | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_opn_no_cert | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_opn_no_cert | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_opn_no_cert | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_opn_no_cert | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| opcua_other | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.750578 | 174.856562 | 174.105985 | 23196.265507 |
| opcua_other | latency_mean_ms | extraction - opcua_forward | 1 | 174.856562 | 177.197635 | 2.341073 | 1.338853 |
| opcua_other | latency_mean_ms | extraction - ip_forward | 1 | 0.750578 | 177.197635 | 176.447058 | 23508.168333 |
| opcua_other | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.935793 | 471.710920 | 470.775127 | 50307.617834 |
| opcua_other | latency_p95_ms | extraction - opcua_forward | 1 | 471.710920 | 513.442039 | 41.731119 | 8.846757 |
| opcua_other | latency_p95_ms | extraction - ip_forward | 1 | 0.935793 | 513.442039 | 512.506247 | 54767.057325 |
| opcua_other | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 5307.000000 | 5307.000000 | nan |
| opcua_other | unmatched_ingress | extraction - opcua_forward | 1 | 5307.000000 | 5636.000000 | 329.000000 | 6.199359 |
| opcua_other | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 5636.000000 | 5636.000000 | nan |
| opcua_other | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 17.964862 | 17.964862 | nan |
| opcua_other | drop_rate_pct | extraction - opcua_forward | 1 | 17.964862 | 19.078569 | 1.113706 | 6.199359 |
| opcua_other | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 19.078569 | 19.078569 | nan |
| opcua_all_8666 | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.755823 | 174.873117 | 174.117294 | 23036.778227 |
| opcua_all_8666 | latency_mean_ms | extraction - opcua_forward | 1 | 174.873117 | 177.099002 | 2.225884 | 1.272857 |
| opcua_all_8666 | latency_mean_ms | extraction - ip_forward | 1 | 0.755823 | 177.099002 | 176.343178 | 23331.276266 |
| opcua_all_8666 | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.944138 | 471.709013 | 470.764875 | 49861.893939 |
| opcua_all_8666 | latency_p95_ms | extraction - opcua_forward | 1 | 471.709013 | 513.281107 | 41.572094 | 8.813080 |
| opcua_all_8666 | latency_p95_ms | extraction - ip_forward | 1 | 0.944138 | 513.281107 | 512.336969 | 54265.075758 |
| opcua_all_8666 | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 5313.000000 | 5313.000000 | nan |
| opcua_all_8666 | unmatched_ingress | extraction - opcua_forward | 1 | 5313.000000 | 5644.000000 | 331.000000 | 6.230002 |
| opcua_all_8666 | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 5644.000000 | 5644.000000 | nan |
| opcua_all_8666 | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 17.954784 | 17.954784 | nan |
| opcua_all_8666 | drop_rate_pct | extraction - opcua_forward | 1 | 17.954784 | 19.073367 | 1.118583 | 6.230002 |
| opcua_all_8666 | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 19.073367 | 19.073367 | nan |

Artifacts:
- `per_run.csv`
- `summary.csv`
- `quality.csv`
- `report.md`
