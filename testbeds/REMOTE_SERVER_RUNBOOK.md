# Runbook Unico per Server Remoto

Questo runbook automatizza le campagne overhead su:
- `Maynard`
- `MOTRA`
- `OTSEC`
- `1client_1server` (sweep dimensioni certificato)

Più la parte di verifica formale (`pk-iota`, `attacks`, confronto GDS a lemmi singoli).

Lo script principale è:
- `testbeds/run_remote_campaigns.sh`

## 1) Setup rapido
```bash
export ROOT="$HOME/Pk-IOTA"
git clone <URL_DEL_TUO_REPO> "$ROOT"
cd "$ROOT"
```

## 2) Campagna smoke (validazione pipeline)
```bash
./testbeds/run_remote_campaigns.sh --root "$ROOT" --profile smoke --tag smoke
```

## 3) Campagna main (profilo paper)
```bash
./testbeds/run_remote_campaigns.sh --root "$ROOT" --profile main --tag main
```

Output principali in:
- `"$ROOT/results/maynard_overhead_<tag>"`
- `"$ROOT/results/motra_overhead_<tag>"`
- `"$ROOT/results/otsec_overhead_<tag>"`
- `"$ROOT/results/cert_size_overhead_<tag>"`
- log formali: `"$ROOT/results/*.txt"`
- summary rapido formale: `"$ROOT/results/formal_quick_summary.txt"`

## 4) Stato runtime e completezza
Per controllare se ci sono lab attivi, artifact presenti e risultati disponibili:

```bash
./testbeds/run_remote_campaigns.sh --root "$ROOT" --status-only
```

## 5) Esecuzione selettiva (skip step)
Esempi utili:

```bash
# Salta build immagini e salta prove formali
./testbeds/run_remote_campaigns.sh \
  --root "$ROOT" \
  --profile main \
  --skip-build-motra \
  --skip-build-otsec \
  --skip-formal

# Solo prove formali (skip tutte le campagne overhead)
./testbeds/run_remote_campaigns.sh \
  --root "$ROOT" \
  --skip-maynard \
  --skip-motra \
  --skip-otsec \
  --skip-cert-size
```

## 6) Override dei parametri
Puoi sovrascrivere i default del profilo:
- `--maynard-runs`
- `--maynard-timeout`
- `--maynard-start-timeout`
- `--motra-runs`
- `--motra-duration`
- `--otsec-runs`
- `--otsec-duration`
- `--cert-runs`
- `--cert-sessions`
- `--cert-timeout`
- `--cert-key-bits`

Esempio:
```bash
./testbeds/run_remote_campaigns.sh \
  --root "$ROOT" \
  --profile main \
  --cert-key-bits 2048,4096 \
  --cert-sessions 50
```

## 7) Nota su Tamarin/Maude
Se `tamarin-prover` segnala warning su `maude 3.2`, è consigliato usare una versione supportata (es. `3.2.2`, `3.3`, `3.4`, `3.5`) per maggiore robustezza riproducibile.
