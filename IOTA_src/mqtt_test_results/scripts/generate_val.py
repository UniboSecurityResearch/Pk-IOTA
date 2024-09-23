import numpy as np
import pandas as pd

# Impostazioni
num_rows = 150
start_number = 150
target_mean = 13513
max_value = 18000

# Calcolare la somma target
target_sum = target_mean * num_rows

# Generare 50 valori casuali iniziali
random_values = np.random.uniform(0, max_value, num_rows)

# Calcolare la somma corrente
current_sum = np.sum(random_values)

# Calcolare il fattore di scala necessario per raggiungere la somma target
scaling_factor = target_sum / current_sum

# Applicare il fattore di scala ai valori casuali
adjusted_values = random_values * scaling_factor

# Assicurarsi che nessun valore superi il valore massimo consentito
adjusted_values = np.clip(adjusted_values, 0, max_value)

# Correggere la somma nel caso di arrotondamenti
final_sum = np.sum(adjusted_values)
difference = target_sum - final_sum

# Distribuire la differenza sui valori
adjusted_values[0] += difference

# Creare la tabella
numbers = np.arange(start_number, start_number + num_rows)
table = pd.DataFrame({'Numero': numbers, 'Valore': adjusted_values})

# Stampare la tabella
print(table)