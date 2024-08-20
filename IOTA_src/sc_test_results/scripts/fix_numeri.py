import re

def sostituisci_primo_numero_con_numero_riga(file_input, file_output):
    with open(file_input, 'r') as f_in, open(file_output, 'w') as f_out:
        for i, riga in enumerate(f_in, start=1):
            # Sostituisce il primo numero trovato nella riga con il numero della riga
            nuova_riga = re.sub(r'\d+', str(i), riga, count=1)
            f_out.write(nuova_riga)

# Specifica il nome del file di input e del file di output
file_input = 'test_send_USA-AUS_txt.txt'
file_output = 'ok_test_send_USA-AUS_txt.txt'

sostituisci_primo_numero_con_numero_riga(file_input, file_output)
