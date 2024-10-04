
tot_times = 0
num = 0
with open("../test_receive_USA-AUS_pem.txt") as test_receive, open("../test_send_USA-AUS_pem.txt") as test_sender, open ("../diff_USA-AUS_pem.txt", "w") as write_file: 
        for x, y in zip(test_receive, test_sender):
            x = x.strip()
            y = y.strip()
            y_splitted = y.split(' - ')
            num_test = int(y_splitted[0].strip())
            arrivo = int(float(x.split(' - ')[1].split('\n')[0]))
            invio_completo = int(float(y_splitted[2].split(' ')[1].strip()))
            invio_iniziato = int(float(y_splitted[1].split(' ')[0]))
            print("Total time:" + str(arrivo-invio_iniziato) + "  Spread time:" + str(arrivo-invio_completo))
            riga = str(num_test) + " - " + str(arrivo-invio_iniziato) + " - " + str (arrivo-invio_completo) +"\n"
            write_file.write(riga)
            tot_times += arrivo-invio_iniziato
            num+=1
print(str(num) + " tests, with mean of total time: " + str (tot_times/num))