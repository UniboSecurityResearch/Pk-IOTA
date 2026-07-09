# MOTRA Overhead Report

- Generated at: `2026-07-08T10:13:31.750949+00:00`
- Input dir: `/root/lorenzino/Pk-IOTA/tests/TESTBEDS/motra_overhead_smoke`
- TCP port: `4840`
- Capture units discovered: `12`

## Quality

| run | switch | variants | status | reasons |
| --- | --- | --- | --- | --- |
| 1 | s_it | extraction,ip_forward,opcua_forward | pass | ok |
| 1 | s_lsensor | extraction,ip_forward,opcua_forward | pass | ok |
| 1 | s_ot | extraction,ip_forward,opcua_forward | pass | ok |
| 1 | s_plc | extraction,ip_forward,opcua_forward | pass | ok |

## Summary Deltas

| switch | class | metric | delta | n_pairs | baseline | candidate | delta_abs | delta_pct |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| s_it | opcua_opn_cert | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.381333 | 0.744175 | 0.362842 | 95.151038 |
| s_it | opcua_opn_cert | latency_mean_ms | extraction - opcua_forward | 1 | 0.744175 | 1.494567 | 0.750392 | 100.835360 |
| s_it | opcua_opn_cert | latency_mean_ms | extraction - ip_forward | 1 | 0.381333 | 1.494567 | 1.113234 | 291.932291 |
| s_it | opcua_opn_cert | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.550985 | 0.865936 | 0.314951 | 57.161402 |
| s_it | opcua_opn_cert | latency_p95_ms | extraction - opcua_forward | 1 | 0.865936 | 1.518011 | 0.652075 | 75.302863 |
| s_it | opcua_opn_cert | latency_p95_ms | extraction - ip_forward | 1 | 0.550985 | 1.518011 | 0.967026 | 175.508438 |
| s_it | opcua_opn_cert | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_opn_cert | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_opn_cert | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_opn_cert | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_opn_cert | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_opn_cert | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_opn_no_cert | latency_mean_ms | opcua_forward - ip_forward | 0 | nan | nan | nan | nan |
| s_it | opcua_opn_no_cert | latency_mean_ms | extraction - opcua_forward | 0 | nan | nan | nan | nan |
| s_it | opcua_opn_no_cert | latency_mean_ms | extraction - ip_forward | 0 | nan | nan | nan | nan |
| s_it | opcua_opn_no_cert | latency_p95_ms | opcua_forward - ip_forward | 0 | nan | nan | nan | nan |
| s_it | opcua_opn_no_cert | latency_p95_ms | extraction - opcua_forward | 0 | nan | nan | nan | nan |
| s_it | opcua_opn_no_cert | latency_p95_ms | extraction - ip_forward | 0 | nan | nan | nan | nan |
| s_it | opcua_opn_no_cert | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_opn_no_cert | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_opn_no_cert | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_opn_no_cert | drop_rate_pct | opcua_forward - ip_forward | 0 | nan | nan | nan | nan |
| s_it | opcua_opn_no_cert | drop_rate_pct | extraction - opcua_forward | 0 | nan | nan | nan | nan |
| s_it | opcua_opn_no_cert | drop_rate_pct | extraction - ip_forward | 0 | nan | nan | nan | nan |
| s_it | opcua_other | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.397628 | 0.880329 | 0.482701 | 121.395174 |
| s_it | opcua_other | latency_mean_ms | extraction - opcua_forward | 1 | 0.880329 | 0.938155 | 0.057826 | 6.568730 |
| s_it | opcua_other | latency_mean_ms | extraction - ip_forward | 1 | 0.397628 | 0.938155 | 0.540527 | 135.938026 |
| s_it | opcua_other | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.662088 | 1.109123 | 0.447035 | 67.518905 |
| s_it | opcua_other | latency_p95_ms | extraction - opcua_forward | 1 | 1.109123 | 1.173973 | 0.064850 | 5.846948 |
| s_it | opcua_other | latency_p95_ms | extraction - ip_forward | 1 | 0.662088 | 1.173973 | 0.511885 | 77.313648 |
| s_it | opcua_other | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_other | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_other | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_other | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_other | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_other | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_all_4840 | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.427459 | 0.687737 | 0.260278 | 60.889533 |
| s_it | opcua_all_4840 | latency_mean_ms | extraction - opcua_forward | 1 | 0.687737 | 0.893967 | 0.206230 | 29.986757 |
| s_it | opcua_all_4840 | latency_mean_ms | extraction - ip_forward | 1 | 0.427459 | 0.893967 | 0.466508 | 109.135086 |
| s_it | opcua_all_4840 | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.622988 | 1.016855 | 0.393867 | 63.222350 |
| s_it | opcua_all_4840 | latency_p95_ms | extraction - opcua_forward | 1 | 1.016855 | 1.485109 | 0.468254 | 46.049238 |
| s_it | opcua_all_4840 | latency_p95_ms | extraction - ip_forward | 1 | 0.622988 | 1.485109 | 0.862122 | 138.384998 |
| s_it | opcua_all_4840 | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_all_4840 | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_all_4840 | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_all_4840 | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_all_4840 | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_all_4840 | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_opn_cert | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.440827 | 0.733095 | 0.292267 | 66.299666 |
| s_lsensor | opcua_opn_cert | latency_mean_ms | extraction - opcua_forward | 1 | 0.733095 | 1.558372 | 0.825277 | 112.574482 |
| s_lsensor | opcua_opn_cert | latency_mean_ms | extraction - ip_forward | 1 | 0.440827 | 1.558372 | 1.117545 | 253.510653 |
| s_lsensor | opcua_opn_cert | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.533104 | 0.787020 | 0.253916 | 47.629696 |
| s_lsensor | opcua_opn_cert | latency_p95_ms | extraction - opcua_forward | 1 | 0.787020 | 1.649857 | 0.862837 | 109.633444 |
| s_lsensor | opcua_opn_cert | latency_p95_ms | extraction - ip_forward | 1 | 0.533104 | 1.649857 | 1.116753 | 209.481216 |
| s_lsensor | opcua_opn_cert | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_opn_cert | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_opn_cert | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_opn_cert | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_opn_cert | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_opn_cert | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_opn_no_cert | latency_mean_ms | opcua_forward - ip_forward | 0 | nan | nan | nan | nan |
| s_lsensor | opcua_opn_no_cert | latency_mean_ms | extraction - opcua_forward | 0 | nan | nan | nan | nan |
| s_lsensor | opcua_opn_no_cert | latency_mean_ms | extraction - ip_forward | 0 | nan | nan | nan | nan |
| s_lsensor | opcua_opn_no_cert | latency_p95_ms | opcua_forward - ip_forward | 0 | nan | nan | nan | nan |
| s_lsensor | opcua_opn_no_cert | latency_p95_ms | extraction - opcua_forward | 0 | nan | nan | nan | nan |
| s_lsensor | opcua_opn_no_cert | latency_p95_ms | extraction - ip_forward | 0 | nan | nan | nan | nan |
| s_lsensor | opcua_opn_no_cert | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_opn_no_cert | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_opn_no_cert | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_opn_no_cert | drop_rate_pct | opcua_forward - ip_forward | 0 | nan | nan | nan | nan |
| s_lsensor | opcua_opn_no_cert | drop_rate_pct | extraction - opcua_forward | 0 | nan | nan | nan | nan |
| s_lsensor | opcua_opn_no_cert | drop_rate_pct | extraction - ip_forward | 0 | nan | nan | nan | nan |
| s_lsensor | opcua_other | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.447767 | 0.820034 | 0.372266 | 83.138415 |
| s_lsensor | opcua_other | latency_mean_ms | extraction - opcua_forward | 1 | 0.820034 | 0.988079 | 0.168045 | 20.492497 |
| s_lsensor | opcua_other | latency_mean_ms | extraction - ip_forward | 1 | 0.447767 | 0.988079 | 0.540312 | 120.668049 |
| s_lsensor | opcua_other | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.532866 | 0.987053 | 0.454187 | 85.234899 |
| s_lsensor | opcua_other | latency_p95_ms | extraction - opcua_forward | 1 | 0.987053 | 1.142979 | 0.155926 | 15.797101 |
| s_lsensor | opcua_other | latency_p95_ms | extraction - ip_forward | 1 | 0.532866 | 1.142979 | 0.610113 | 114.496644 |
| s_lsensor | opcua_other | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_other | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_other | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_other | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_other | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_other | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_all_4840 | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.461030 | 0.668304 | 0.207274 | 44.958900 |
| s_lsensor | opcua_all_4840 | latency_mean_ms | extraction - opcua_forward | 1 | 0.668304 | 0.844212 | 0.175908 | 26.321532 |
| s_lsensor | opcua_all_4840 | latency_mean_ms | extraction - ip_forward | 1 | 0.461030 | 0.844212 | 0.383182 | 83.114302 |
| s_lsensor | opcua_all_4840 | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.603914 | 0.905037 | 0.301123 | 49.861824 |
| s_lsensor | opcua_all_4840 | latency_p95_ms | extraction - opcua_forward | 1 | 0.905037 | 1.542091 | 0.637054 | 70.389884 |
| s_lsensor | opcua_all_4840 | latency_p95_ms | extraction - ip_forward | 1 | 0.603914 | 1.542091 | 0.938177 | 155.349388 |
| s_lsensor | opcua_all_4840 | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_all_4840 | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_all_4840 | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_all_4840 | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_all_4840 | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_all_4840 | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_opn_cert | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.436785 | 0.912510 | 0.475725 | 108.915034 |
| s_ot | opcua_opn_cert | latency_mean_ms | extraction - opcua_forward | 1 | 0.912510 | 1.722320 | 0.809811 | 88.745455 |
| s_ot | opcua_opn_cert | latency_mean_ms | extraction - ip_forward | 1 | 0.436785 | 1.722320 | 1.285535 | 294.317632 |
| s_ot | opcua_opn_cert | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.538111 | 1.382113 | 0.844002 | 156.845370 |
| s_ot | opcua_opn_cert | latency_p95_ms | extraction - opcua_forward | 1 | 1.382113 | 2.001047 | 0.618935 | 44.781784 |
| s_ot | opcua_opn_cert | latency_p95_ms | extraction - ip_forward | 1 | 0.538111 | 2.001047 | 1.462936 | 271.865308 |
| s_ot | opcua_opn_cert | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_opn_cert | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_opn_cert | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_opn_cert | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_opn_cert | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_opn_cert | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_opn_no_cert | latency_mean_ms | opcua_forward - ip_forward | 0 | nan | nan | nan | nan |
| s_ot | opcua_opn_no_cert | latency_mean_ms | extraction - opcua_forward | 0 | nan | nan | nan | nan |
| s_ot | opcua_opn_no_cert | latency_mean_ms | extraction - ip_forward | 0 | nan | nan | nan | nan |
| s_ot | opcua_opn_no_cert | latency_p95_ms | opcua_forward - ip_forward | 0 | nan | nan | nan | nan |
| s_ot | opcua_opn_no_cert | latency_p95_ms | extraction - opcua_forward | 0 | nan | nan | nan | nan |
| s_ot | opcua_opn_no_cert | latency_p95_ms | extraction - ip_forward | 0 | nan | nan | nan | nan |
| s_ot | opcua_opn_no_cert | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_opn_no_cert | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_opn_no_cert | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_opn_no_cert | drop_rate_pct | opcua_forward - ip_forward | 0 | nan | nan | nan | nan |
| s_ot | opcua_opn_no_cert | drop_rate_pct | extraction - opcua_forward | 0 | nan | nan | nan | nan |
| s_ot | opcua_opn_no_cert | drop_rate_pct | extraction - ip_forward | 0 | nan | nan | nan | nan |
| s_ot | opcua_other | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.459635 | 0.992426 | 0.532792 | 115.916348 |
| s_ot | opcua_other | latency_mean_ms | extraction - opcua_forward | 1 | 0.992426 | 1.179748 | 0.187322 | 18.875152 |
| s_ot | opcua_other | latency_mean_ms | extraction - ip_forward | 1 | 0.459635 | 1.179748 | 0.720114 | 156.670886 |
| s_ot | opcua_other | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.632048 | 1.463890 | 0.831842 | 131.610713 |
| s_ot | opcua_other | latency_p95_ms | extraction - opcua_forward | 1 | 1.463890 | 1.886129 | 0.422239 | 28.843648 |
| s_ot | opcua_other | latency_p95_ms | extraction - ip_forward | 1 | 0.632048 | 1.886129 | 1.254082 | 198.415692 |
| s_ot | opcua_other | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_other | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_other | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_other | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_other | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_other | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_all_4840 | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.474357 | 0.829221 | 0.354864 | 74.809495 |
| s_ot | opcua_all_4840 | latency_mean_ms | extraction - opcua_forward | 1 | 0.829221 | 0.949935 | 0.120715 | 14.557597 |
| s_ot | opcua_all_4840 | latency_mean_ms | extraction - ip_forward | 1 | 0.474357 | 0.949935 | 0.475579 | 100.257556 |
| s_ot | opcua_all_4840 | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.650167 | 1.471996 | 0.821829 | 126.402640 |
| s_ot | opcua_all_4840 | latency_p95_ms | extraction - opcua_forward | 1 | 1.471996 | 1.821041 | 0.349045 | 23.712342 |
| s_ot | opcua_all_4840 | latency_p95_ms | extraction - ip_forward | 1 | 0.650167 | 1.821041 | 1.170874 | 180.088009 |
| s_ot | opcua_all_4840 | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_all_4840 | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_all_4840 | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_all_4840 | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_all_4840 | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_all_4840 | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_opn_cert | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.396252 | 0.761995 | 0.365743 | 92.300664 |
| s_plc | opcua_opn_cert | latency_mean_ms | extraction - opcua_forward | 1 | 0.761995 | 1.451378 | 0.689383 | 90.470838 |
| s_plc | opcua_opn_cert | latency_mean_ms | extraction - ip_forward | 1 | 0.396252 | 1.451378 | 1.055126 | 266.276686 |
| s_plc | opcua_opn_cert | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.422955 | 0.801086 | 0.378132 | 89.402480 |
| s_plc | opcua_opn_cert | latency_p95_ms | extraction - opcua_forward | 1 | 0.801086 | 1.502037 | 0.700951 | 87.500000 |
| s_plc | opcua_opn_cert | latency_p95_ms | extraction - ip_forward | 1 | 0.422955 | 1.502037 | 1.079082 | 255.129651 |
| s_plc | opcua_opn_cert | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_opn_cert | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_opn_cert | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_opn_cert | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_opn_cert | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_opn_cert | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_opn_no_cert | latency_mean_ms | opcua_forward - ip_forward | 0 | nan | nan | nan | nan |
| s_plc | opcua_opn_no_cert | latency_mean_ms | extraction - opcua_forward | 0 | nan | nan | nan | nan |
| s_plc | opcua_opn_no_cert | latency_mean_ms | extraction - ip_forward | 0 | nan | nan | nan | nan |
| s_plc | opcua_opn_no_cert | latency_p95_ms | opcua_forward - ip_forward | 0 | nan | nan | nan | nan |
| s_plc | opcua_opn_no_cert | latency_p95_ms | extraction - opcua_forward | 0 | nan | nan | nan | nan |
| s_plc | opcua_opn_no_cert | latency_p95_ms | extraction - ip_forward | 0 | nan | nan | nan | nan |
| s_plc | opcua_opn_no_cert | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_opn_no_cert | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_opn_no_cert | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_opn_no_cert | drop_rate_pct | opcua_forward - ip_forward | 0 | nan | nan | nan | nan |
| s_plc | opcua_opn_no_cert | drop_rate_pct | extraction - opcua_forward | 0 | nan | nan | nan | nan |
| s_plc | opcua_opn_no_cert | drop_rate_pct | extraction - ip_forward | 0 | nan | nan | nan | nan |
| s_plc | opcua_other | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.413666 | 0.901787 | 0.488121 | 117.998821 |
| s_plc | opcua_other | latency_mean_ms | extraction - opcua_forward | 1 | 0.901787 | 1.032797 | 0.131010 | 14.527764 |
| s_plc | opcua_other | latency_mean_ms | extraction - ip_forward | 1 | 0.413666 | 1.032797 | 0.619131 | 149.669174 |
| s_plc | opcua_other | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.473976 | 1.079082 | 0.605106 | 127.665996 |
| s_plc | opcua_other | latency_p95_ms | extraction - opcua_forward | 1 | 1.079082 | 1.224041 | 0.144958 | 13.433495 |
| s_plc | opcua_other | latency_p95_ms | extraction - ip_forward | 1 | 0.473976 | 1.224041 | 0.750065 | 158.249497 |
| s_plc | opcua_other | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_other | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_other | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_other | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_other | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_other | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_all_4840 | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.429817 | 0.752803 | 0.322986 | 75.144859 |
| s_plc | opcua_all_4840 | latency_mean_ms | extraction - opcua_forward | 1 | 0.752803 | 0.856512 | 0.103709 | 13.776405 |
| s_plc | opcua_all_4840 | latency_mean_ms | extraction - ip_forward | 1 | 0.429817 | 0.856512 | 0.426695 | 99.273524 |
| s_plc | opcua_all_4840 | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.595093 | 1.013994 | 0.418901 | 70.392628 |
| s_plc | opcua_all_4840 | latency_p95_ms | extraction - opcua_forward | 1 | 1.013994 | 1.442194 | 0.428200 | 42.229015 |
| s_plc | opcua_all_4840 | latency_p95_ms | extraction - ip_forward | 1 | 0.595093 | 1.442194 | 0.847101 | 142.347756 |
| s_plc | opcua_all_4840 | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_all_4840 | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_all_4840 | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_all_4840 | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_all_4840 | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_all_4840 | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |

Artifacts:
- `per_run.csv`
- `summary.csv`
- `quality.csv`
- `report.md`
