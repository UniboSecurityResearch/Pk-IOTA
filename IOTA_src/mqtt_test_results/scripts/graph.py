#!/usr/bin/python3
import numpy as np
import matplotlib.pyplot as plt
import math
import seaborn as sns
import pandas as pd

# Inizializza le liste per i dati
switch = []
transport_h = []
tunnel_h = []
tunnel_net = []

# Specifica il percorso del file di testo
file_path = "../diff_mqtt_EU-AUS_txt.txt"
with open(file_path, 'r') as file:
    for line in file:
        line = line.strip()  # Rimuovi spazi bianchi e caratteri di nuova riga
        text = line.split(' - ')[1]
        if line: 
            switch.append(float(text))

# Specifica il percorso del file di testo
file_path = "../diff_mqtt_EU-EU_txt.txt"
with open(file_path, 'r') as file:
    for line in file:
        line = line.strip()  # Rimuovi spazi bianchi e caratteri di nuova riga
        text = line.split(' - ')[1]
        if line: 
            transport_h.append(float(text))

# Specifica il percorso del file di testo
file_path = "../diff_mqtt_USA-AUS_txt.txt"
with open(file_path, 'r') as file:
    for line in file:
        line = line.strip()  # Rimuovi spazi bianchi e caratteri di nuova riga
        text = line.split(' - ')[1]
        if line: 
            tunnel_h.append(float(text))



#round all values to 9 decimal places
factor = 10.0 ** 9
for i in range(len(switch)):
    switch[i] = math.trunc(switch[i] * factor) / factor
    switch[i] = switch[i] * 1000
for i in range(len(transport_h)):
    transport_h[i] = math.trunc(transport_h[i] * factor) / factor
    transport_h[i] = transport_h[i] * 1000
for i in range(len(tunnel_h)):
    tunnel_h[i] = math.trunc(tunnel_h[i] * factor) / factor
    tunnel_h[i] = tunnel_h[i] * 1000

        
#Rimuovi i valori anomali
# Q3, Q1 = np.percentile(switch, [75, 25])
# IQR = Q3 - Q1
# upper_bound = Q3 + 1.5 * IQR
# lower_bound = Q1 - 1.5 * IQR
# for el in switch:
#     if el < upper_bound and el > lower_bound:
#         switch.remove(el)


# Calcola la media
mean_switch = np.mean(switch)
mean_switch = math.trunc(mean_switch * factor) / factor
mean_transport_h = np.mean(transport_h)
mean_transport_h = math.trunc(mean_transport_h * factor) / factor
mean_tunnel_h = np.mean(tunnel_h)
mean_tunnel_h = math.trunc(mean_tunnel_h * factor) / factor


# Stampa le medie
print("Mean switch: ", mean_switch)
print("Mean transport host-to-host: ", mean_transport_h)
print("Mean tunnel host-to-host: ", mean_tunnel_h)

# Calcola la deviazione standard
std_dev_switch = np.std(switch)
std_dev_switch = math.trunc(std_dev_switch * factor) / factor
std_dev_transport_h = np.std(transport_h)
std_dev_transport_h = math.trunc(std_dev_transport_h * factor) / factor
std_dev_tunnel_h = np.std(tunnel_h)
std_dev_tunnel_h = math.trunc(std_dev_tunnel_h * factor) / factor

# Crea una lista con i valori sull'asse x
x_labels = ['In-Network\nEncryption', 'Transport\nHost-to-Host', 'Tunnel\nHost-to-Host']

sns.set()
sns.set_palette("colorblind")
sns.set_context("notebook")

# Crea una lista di stringhe per i valori sull'asse delle x
x_val = np.arange(len(x_labels))

# Crea un grafico a barre con le deviazioni standard
bar_width = 0.35
plt.bar(x_labels, [mean_switch, mean_transport_h, mean_tunnel_h], yerr=[std_dev_switch, std_dev_transport_h, std_dev_tunnel_h], ecolor='red', capsize=5)


# Metti la legenda su una sola linea
#plt.legend(fontsize=15, loc='upper center', bbox_to_anchor=(0.5, 1.15), ncol=3, fancybox=True, shadow=True)

# Aggiungi barre di errore
#plt.errorbar(x_val, y_val, yerr=[std_dev_r_chipher, std_dev_r_tls, std_dev_w_chipher, std_dev_w_tls], fmt='none', ecolor='red', capsize=3)

#Aggiungi label sull'asse y
plt.ylabel('Avg Time (ms)', fontsize=20)

plt.gca().tick_params(axis='y', which='both', left=True, labelleft=True)
plt.gca().tick_params(axis='x', which='both', bottom=True, labelbottom=True)
plt.gca().spines['left'].set_color('black')
plt.gca().spines['left'].set_linewidth(1)
plt.gca().spines['bottom'].set_color('black')
plt.gca().spines['bottom'].set_linewidth(1)

avg = [mean_switch, mean_transport_h, mean_tunnel_h]

# Aggiungi i valori delle medie sopra le barre
plt.text(0 + 0.055, avg[0], f"{avg[0]:.2f}", ha='left', va='bottom', fontsize=16)
plt.text(1 + 0.055, avg[1], f"{avg[1]:.2f}", ha='left', va='bottom', fontsize=16)
plt.text(2 + 0.055, avg[2], f"{avg[2]:.2f}", ha='left', va='bottom', fontsize=16)
plt.text(3 + 0.055, avg[3], f"{avg[3]:.2f}", ha='left', va='bottom', fontsize=16)

# Metti i margini right e top del subplot a 0.99
plt.subplots_adjust(right=0.99, top=0.99)

# Modifica la dimensione della finestra del grafico
fig = plt.gcf()
fig.set_size_inches(10, 9)

# Modifica la dimensione dei numeri sull'asse delle x e delle y
plt.xticks(fontsize=18)  # Imposta la dimensione dei numeri sull'asse delle x a 20
plt.yticks(fontsize=18)  # Imposta la dimensione dei numeri sull'asse delle y a 20

# Mostra il grafico
plt.show()