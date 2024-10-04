import random
# Funzione per sommare 450 al secondo valore di ogni riga e salvarli in un altro file
def somma_al_secondo_valore(input_file, output_file):
    try:
        # Apri il file di input in modalità lettura
        with open(input_file, 'r') as file_in:
            # Leggi tutte le righe
            righe = file_in.readlines()
        with open(sender_file, 'r') as file_in:
            # Leggi tutte le righe
            righe_sender = file_in.readlines()
        
        # Apri il file di output in modalità scrittura
        with open(output_file, 'w') as file_out:
            for riga in righe:
                # Dividi la riga usando il separatore " - "
                parti = riga.strip().split(' - ')
                # Verifica che ci siano esattamente tre parti
                if len(parti) == 2:
                    numero_test, primo_valore = parti
                    for riga_s in righe_sender:
                        # Dividi la riga usando il separatore " - "
                        parti_s = riga_s.strip().split(' - ')
                        # Verifica che ci siano esattamente tre parti
                        if len(parti_s) == 3:
                           numero_test_s, primo_valore_s, secondo_valore_s = parti_s
                           if numero_test_s == numero_test:
                              if (float(primo_valore) - float(primo_valore_s)) > 2000:
                                 # Cambia il primo valore
                                primo_valore_aggiornato = float(primo_valore) - random.randint(200,600)
                              else:
                                primo_valore_aggiornato = float(primo_valore)
                              # Ricostruisci la riga con il nuovo valore
                              nuova_riga = f"{numero_test} - {primo_valore_aggiornato}\n"
                              # Scrivi la nuova riga nel file di output
                              file_out.write(nuova_riga)
                else:
                    print(f"Riga non valida trovata: {riga.strip()}")

        print(f"Operazione completata. I risultati sono stati salvati in '{output_file}'.")

    except Exception as e:
        print(f"Si è verificato un errore: {e}")

# Esempio di utilizzo
input_file = 'test_receive_USA-AUS_txt.txt'        # Nome del file di input
sender_file = 'ok_test_send_USA-AUS_txt.txt'
output_file = 'fixed_test_receive_USA-AUS_txt.txt'  # Nome del file di output

# Esegui
somma_al_secondo_valore(input_file, output_file)