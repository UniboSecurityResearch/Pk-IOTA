#!/usr/bin/python3
import numpy as np
import matplotlib.pyplot as plt
import math
import seaborn as sns
import pandas as pd

# Inizializza le liste per i dati
conn = []
vpn_conn = []
DH = []

# Specifica il percorso del file di testo
file_path = "../test/results_conn.txt"
with open(file_path, 'r') as file:
    for line in file:
        line = line.strip()  # Rimuovi spazi bianchi e caratteri di nuova riga
        if line:
            conn.append(float(line))

file_path = "../test/vpn_tot_times_1.csv"
with open(file_path, 'r') as file:
    for line in file:
        line = line.strip()
        if line:
            vpn_conn.append(float(line))

file_path = "../test/results_DH.txt"
with open(file_path, 'r') as file:
    for line in file:
        line = line.strip()
        if line:
            DH.append(float(line))

# Trunc all values to 9 decimal places
factor = 10**9
conn = [math.trunc(element * factor) / factor for element in conn]
conn = [element * 1000 for element in conn]
vpn_conn = [math.trunc(element * factor) / factor for element in vpn_conn]
vpn_conn = [element * 1000 for element in vpn_conn]
DH = [math.trunc(element * factor) / factor for element in DH]
DH = [element * 1000 for element in DH]

# Calcola la media dei valori
conn_avg = np.mean(conn)
vpn_conn_avg = np.mean(vpn_conn)

conn_DH = []
for i in range(len(conn)):
    conn_DH.append(conn[i] + DH[i])
DH_avg = np.mean(conn_DH)

# Stampa le medie
print("Avg conn: ", conn_avg)
print("Avg vpn_conn: ", vpn_conn_avg)
print("Avg conn_DH: ", DH_avg)
print("Avg DH: ", np.mean(DH))

# Calcola la deviazione standard
conn_std = np.std(conn)
vpn_conn_std = np.std(vpn_conn)
DH_std = np.std(conn_DH)

# Crea una lista con le medie
avg = [conn_avg, DH_avg, vpn_conn_avg]
# Crea una lista con le deviazioni standard
std = [conn_std, DH_std, vpn_conn_std]

# Crea una lista di stringhe per i valori sull'asse delle x
x_val = ['Connection with\npre-shared keys', 'Connection\nwith DH', 'IPsec setup\nand connection']

sns.set()
sns.set_palette("colorblind")
sns.set_context("notebook")

# Crea un grafico a barre
ax = plt.bar(x_val, avg, color='tab:blue', yerr=std, ecolor='red', capsize=5)

# Aggiungi label sull'asse y
plt.ylabel('Avg Time (ms)', fontsize=18)

# Metti l'asse y in scala logaritmica
plt.yscale('log')

# Mostra scala logaritmica sull'asse y
plt.gca().tick_params(axis='y', which='both', left=True, labelleft=True)
plt.gca().tick_params(axis='x', which='both', bottom=True, labelbottom=True)
plt.gca().spines['left'].set_color('black')
plt.gca().spines['left'].set_linewidth(1)
plt.gca().spines['bottom'].set_color('black')
plt.gca().spines['bottom'].set_linewidth(1)

plt.text(0 + 0.12, avg[0], f"{avg[0]:.2f}", ha='left', va='bottom', fontsize=16)
plt.text(1 + 0.12, avg[1], f"{avg[1]:.2f}", ha='left', va='bottom', fontsize=16)
plt.text(2 + 0.055, avg[2], f"{avg[2]:.2f}", ha='left', va='bottom', fontsize=16)

# Metti i margini right e top del subplot a 0.99
plt.subplots_adjust(right=0.99, top=0.99)

# Modifica la dimensione della finestra del grafico
fig = plt.gcf()
fig.set_size_inches(10, 9)

plt.xticks(fontsize=18)  # Imposta la dimensione dei numeri sull'asse delle x a 18
plt.yticks(fontsize=18)  # Imposta la dimensione dei numeri sull'asse delle y a 18

# Mostra il grafico
plt.show()