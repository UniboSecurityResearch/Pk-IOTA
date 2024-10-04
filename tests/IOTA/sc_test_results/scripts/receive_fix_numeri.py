def aggiungi_numero_riga(file_input, file_output):
    with open(file_input, 'r') as f_in, open(file_output, 'w') as f_out:
        for i, riga in enumerate(f_in, start=1):
            nuova_riga = f"{i} - {riga}"
            f_out.write(nuova_riga)

# Specifica il nome del file di input e del file di output
file_input = 'test_receive_USA-AUS_txt.txt'
file_output = 'ok_test_receive_USA-AUS_txt.txt'

aggiungi_numero_riga(file_input, file_output)
