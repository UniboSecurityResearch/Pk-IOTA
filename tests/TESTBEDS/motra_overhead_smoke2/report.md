# MOTRA Overhead Report

- Generated at: `2026-07-08T14:10:48.626425+00:00`
- Input dir: `/root/lorenzino/Pk-IOTA/tests/TESTBEDS/motra_overhead_smoke2`
- TCP port: `4840`
- Capture units discovered: `12`

## Quality

| run | switch | variants | status | reasons |
| --- | --- | --- | --- | --- |
| 1 | s_it | extraction,ip_forward,opcua_forward | pass | ok |
| 1 | s_lsensor | extraction,ip_forward,opcua_forward | pass | ok |
| 1 | s_ot | extraction,ip_forward,opcua_forward | fail | extraction:drop=0.403226 |
| 1 | s_plc | extraction,ip_forward,opcua_forward | pass | ok |

## Summary Deltas

| switch | class | metric | delta | n_pairs | baseline | candidate | delta_abs | delta_pct |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| s_it | opcua_opn_cert | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.206202 | 0.368821 | 0.162619 | 78.863585 |
| s_it | opcua_opn_cert | latency_mean_ms | extraction - opcua_forward | 1 | 0.368821 | 0.719984 | 0.351164 | 95.212535 |
| s_it | opcua_opn_cert | latency_mean_ms | extraction - ip_forward | 1 | 0.206202 | 0.719984 | 0.513782 | 249.164137 |
| s_it | opcua_opn_cert | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.221014 | 0.407934 | 0.186920 | 84.573894 |
| s_it | opcua_opn_cert | latency_p95_ms | extraction - opcua_forward | 1 | 0.407934 | 0.747204 | 0.339270 | 83.167738 |
| s_it | opcua_opn_cert | latency_p95_ms | extraction - ip_forward | 1 | 0.221014 | 0.747204 | 0.526190 | 238.079827 |
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
| s_it | opcua_other | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.229232 | 0.393496 | 0.164263 | 71.657989 |
| s_it | opcua_other | latency_mean_ms | extraction - opcua_forward | 1 | 0.393496 | 0.414673 | 0.021178 | 5.381894 |
| s_it | opcua_other | latency_mean_ms | extraction - ip_forward | 1 | 0.229232 | 0.414673 | 0.185441 | 80.896440 |
| s_it | opcua_other | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.304222 | 0.463009 | 0.158787 | 52.194357 |
| s_it | opcua_other | latency_p95_ms | extraction - opcua_forward | 1 | 0.463009 | 0.452995 | -0.010014 | -2.162719 |
| s_it | opcua_other | latency_p95_ms | extraction - ip_forward | 1 | 0.304222 | 0.452995 | 0.148773 | 48.902821 |
| s_it | opcua_other | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_other | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_other | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_other | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_other | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_other | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_all_4840 | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.221160 | 0.328715 | 0.107555 | 48.632046 |
| s_it | opcua_all_4840 | latency_mean_ms | extraction - opcua_forward | 1 | 0.328715 | 0.370338 | 0.041624 | 12.662570 |
| s_it | opcua_all_4840 | latency_mean_ms | extraction - ip_forward | 1 | 0.221160 | 0.370338 | 0.149178 | 67.452683 |
| s_it | opcua_all_4840 | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.303984 | 0.432968 | 0.128984 | 42.431373 |
| s_it | opcua_all_4840 | latency_p95_ms | extraction - opcua_forward | 1 | 0.432968 | 0.710964 | 0.277996 | 64.207048 |
| s_it | opcua_all_4840 | latency_p95_ms | extraction - ip_forward | 1 | 0.303984 | 0.710964 | 0.406981 | 133.882353 |
| s_it | opcua_all_4840 | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_all_4840 | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_all_4840 | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_all_4840 | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_all_4840 | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_it | opcua_all_4840 | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_opn_cert | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.204921 | 0.381895 | 0.176975 | 86.362503 |
| s_lsensor | opcua_opn_cert | latency_mean_ms | extraction - opcua_forward | 1 | 0.381895 | 0.680102 | 0.298206 | 78.085842 |
| s_lsensor | opcua_opn_cert | latency_mean_ms | extraction - ip_forward | 1 | 0.204921 | 0.680102 | 0.475181 | 231.885232 |
| s_lsensor | opcua_opn_cert | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.231028 | 0.501871 | 0.270844 | 117.234262 |
| s_lsensor | opcua_opn_cert | latency_p95_ms | extraction - opcua_forward | 1 | 0.501871 | 0.736952 | 0.235081 | 46.840855 |
| s_lsensor | opcua_opn_cert | latency_p95_ms | extraction - ip_forward | 1 | 0.231028 | 0.736952 | 0.505924 | 218.988648 |
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
| s_lsensor | opcua_other | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.208344 | 0.385836 | 0.177493 | 85.192224 |
| s_lsensor | opcua_other | latency_mean_ms | extraction - opcua_forward | 1 | 0.385836 | 0.394598 | 0.008762 | 2.270880 |
| s_lsensor | opcua_other | latency_mean_ms | extraction - ip_forward | 1 | 0.208344 | 0.394598 | 0.186255 | 89.397717 |
| s_lsensor | opcua_other | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.256062 | 0.478983 | 0.222921 | 87.057728 |
| s_lsensor | opcua_other | latency_p95_ms | extraction - opcua_forward | 1 | 0.478983 | 0.452042 | -0.026941 | -5.624689 |
| s_lsensor | opcua_other | latency_p95_ms | extraction - ip_forward | 1 | 0.256062 | 0.452042 | 0.195980 | 76.536313 |
| s_lsensor | opcua_other | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_other | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_other | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_other | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_other | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_other | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_all_4840 | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.216376 | 0.327339 | 0.110964 | 51.282827 |
| s_lsensor | opcua_all_4840 | latency_mean_ms | extraction - opcua_forward | 1 | 0.327339 | 0.362053 | 0.034714 | 10.604844 |
| s_lsensor | opcua_all_4840 | latency_mean_ms | extraction - ip_forward | 1 | 0.216376 | 0.362053 | 0.145677 | 67.326135 |
| s_lsensor | opcua_all_4840 | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.295877 | 0.438213 | 0.142336 | 48.106366 |
| s_lsensor | opcua_all_4840 | latency_p95_ms | extraction - opcua_forward | 1 | 0.438213 | 0.690937 | 0.252724 | 57.671382 |
| s_lsensor | opcua_all_4840 | latency_p95_ms | extraction - ip_forward | 1 | 0.295877 | 0.690937 | 0.395060 | 133.521354 |
| s_lsensor | opcua_all_4840 | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_all_4840 | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_all_4840 | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_all_4840 | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_all_4840 | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_lsensor | opcua_all_4840 | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_opn_cert | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.233468 | 0.376657 | 0.143189 | 61.331306 |
| s_ot | opcua_opn_cert | latency_mean_ms | extraction - opcua_forward | 1 | 0.376657 | 0.714615 | 0.337958 | 89.725560 |
| s_ot | opcua_opn_cert | latency_mean_ms | extraction - ip_forward | 1 | 0.233468 | 0.714615 | 0.481147 | 206.086723 |
| s_ot | opcua_opn_cert | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.297070 | 0.475168 | 0.178099 | 59.951846 |
| s_ot | opcua_opn_cert | latency_p95_ms | extraction - opcua_forward | 1 | 0.475168 | 0.820875 | 0.345707 | 72.754641 |
| s_ot | opcua_opn_cert | latency_p95_ms | extraction - ip_forward | 1 | 0.297070 | 0.820875 | 0.523806 | 176.324238 |
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
| s_ot | opcua_other | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.228236 | 0.379328 | 0.151093 | 66.200329 |
| s_ot | opcua_other | latency_mean_ms | extraction - opcua_forward | 1 | 0.379328 | 0.421801 | 0.042473 | 11.196800 |
| s_ot | opcua_other | latency_mean_ms | extraction - ip_forward | 1 | 0.228236 | 0.421801 | 0.193565 | 84.809447 |
| s_ot | opcua_other | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.303984 | 0.471115 | 0.167131 | 54.980392 |
| s_ot | opcua_other | latency_p95_ms | extraction - opcua_forward | 1 | 0.471115 | 0.499964 | 0.028849 | 6.123482 |
| s_ot | opcua_other | latency_p95_ms | extraction - ip_forward | 1 | 0.303984 | 0.499964 | 0.195980 | 64.470588 |
| s_ot | opcua_other | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_other | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 2.000000 | 2.000000 | nan |
| s_ot | opcua_other | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 2.000000 | 2.000000 | nan |
| s_ot | opcua_other | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_other | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.595238 | 0.595238 | nan |
| s_ot | opcua_other | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.595238 | 0.595238 | nan |
| s_ot | opcua_all_4840 | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.227167 | 0.314278 | 0.087110 | 38.346349 |
| s_ot | opcua_all_4840 | latency_mean_ms | extraction - opcua_forward | 1 | 0.314278 | 0.370659 | 0.056381 | 17.939806 |
| s_ot | opcua_all_4840 | latency_mean_ms | extraction - ip_forward | 1 | 0.227167 | 0.370659 | 0.143491 | 63.165415 |
| s_ot | opcua_all_4840 | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.303984 | 0.438929 | 0.134945 | 44.392157 |
| s_ot | opcua_all_4840 | latency_p95_ms | extraction - opcua_forward | 1 | 0.438929 | 0.697851 | 0.258923 | 58.989680 |
| s_ot | opcua_all_4840 | latency_p95_ms | extraction - ip_forward | 1 | 0.303984 | 0.697851 | 0.393867 | 129.568627 |
| s_ot | opcua_all_4840 | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_all_4840 | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 6.000000 | 6.000000 | nan |
| s_ot | opcua_all_4840 | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 6.000000 | 6.000000 | nan |
| s_ot | opcua_all_4840 | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_ot | opcua_all_4840 | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.403226 | 0.403226 | nan |
| s_ot | opcua_all_4840 | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.403226 | 0.403226 | nan |
| s_plc | opcua_opn_cert | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.192713 | 0.371015 | 0.178302 | 92.521994 |
| s_plc | opcua_opn_cert | latency_mean_ms | extraction - opcua_forward | 1 | 0.371015 | 0.707384 | 0.336369 | 90.661891 |
| s_plc | opcua_opn_cert | latency_mean_ms | extraction - ip_forward | 1 | 0.192713 | 0.707384 | 0.514671 | 267.066074 |
| s_plc | opcua_opn_cert | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.209093 | 0.402927 | 0.193834 | 92.702395 |
| s_plc | opcua_opn_cert | latency_p95_ms | extraction - opcua_forward | 1 | 0.402927 | 0.754118 | 0.351191 | 87.159763 |
| s_plc | opcua_opn_cert | latency_p95_ms | extraction - ip_forward | 1 | 0.209093 | 0.754118 | 0.545025 | 260.661345 |
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
| s_plc | opcua_other | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.220530 | 0.430753 | 0.210223 | 95.326504 |
| s_plc | opcua_other | latency_mean_ms | extraction - opcua_forward | 1 | 0.430753 | 0.401803 | -0.028950 | -6.720831 |
| s_plc | opcua_other | latency_mean_ms | extraction - ip_forward | 1 | 0.220530 | 0.401803 | 0.181273 | 82.198939 |
| s_plc | opcua_other | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.287056 | 0.586033 | 0.298977 | 104.152824 |
| s_plc | opcua_other | latency_p95_ms | extraction - opcua_forward | 1 | 0.586033 | 0.455141 | -0.130892 | -22.335232 |
| s_plc | opcua_other | latency_p95_ms | extraction - ip_forward | 1 | 0.287056 | 0.455141 | 0.168085 | 58.554817 |
| s_plc | opcua_other | unmatched_ingress | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_other | unmatched_ingress | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_other | unmatched_ingress | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_other | drop_rate_pct | opcua_forward - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_other | drop_rate_pct | extraction - opcua_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_other | drop_rate_pct | extraction - ip_forward | 1 | 0.000000 | 0.000000 | 0.000000 | nan |
| s_plc | opcua_all_4840 | latency_mean_ms | opcua_forward - ip_forward | 1 | 0.215934 | 0.346880 | 0.130946 | 60.641683 |
| s_plc | opcua_all_4840 | latency_mean_ms | extraction - opcua_forward | 1 | 0.346880 | 0.364859 | 0.017979 | 5.183079 |
| s_plc | opcua_all_4840 | latency_mean_ms | extraction - ip_forward | 1 | 0.215934 | 0.364859 | 0.148925 | 68.967868 |
| s_plc | opcua_all_4840 | latency_p95_ms | opcua_forward - ip_forward | 1 | 0.288010 | 0.509024 | 0.221014 | 76.738411 |
| s_plc | opcua_all_4840 | latency_p95_ms | extraction - opcua_forward | 1 | 0.509024 | 0.695944 | 0.186920 | 36.721311 |
| s_plc | opcua_all_4840 | latency_p95_ms | extraction - ip_forward | 1 | 0.288010 | 0.695944 | 0.407934 | 141.639073 |
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
