
tot_times = 0
num = 0
with open("test_receive_EU-EU_pem.txt") as test_receive, open("test_send_EU-EU_pem.txt") as test_sender: 
        for x, y in zip(test_receive, test_sender):
            x = x.strip()
            y = y.strip()
            y_splitted = y.split(' - ');
            arrivo = float(x.split('\n')[0])
            invio_completo = float(y_splitted[2].split(' ')[1].strip())
            invio_iniziato = float(y_splitted[1].split(' ')[0])
            print("Total time:" + str(arrivo-invio_iniziato) + "  Spread time:" + str(arrivo-invio_completo))
            tot_times += arrivo-invio_iniziato
            num+=1
print(str(num) + " tests, with mean of total time: " + str (tot_times/num))