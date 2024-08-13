# Funzione per sommare 450 a ciascun numero in un file e salvarli in un altro file
def somma_a_file(input_file, output_file):
    try:
        # Apri il file di input in modalità lettura
        with open(input_file, 'r') as file_in:
            # Leggi tutte le righe e convertili in numeri
            numeri = file_in.readlines()
        
        # Apri il file di output in modalità scrittura
        with open(output_file, 'w') as file_out:
            for numero in numeri:
                # Rimuovi eventuali spazi bianchi e converti in intero
                numero_intero = int(numero.strip())
                # Somma 450 al numero
                risultato = numero_intero - 30
                # Scrivi il risultato nel file di output
                file_out.write(f"{risultato}\n")

        print(f"Operazione completata. I risultati sono stati salvati in '{output_file}'.")

    except Exception as e:
        print(f"Si è verificato un errore: {e}")

# Esempio di utilizzo
input_file = 'test_send_EU-AUST_pem.txt'      # Nome del file di input
output_file = 'risultato_test_send_EU-AUST_pem.txt'  # Nome del file di output

# Esegui la funzione
somma_a_file(input_file, output_file)
