
test_listen = open("test_pem_listener_USA.txt", "r") 
lines_listen = test_listen.readlines()
tot_times = 0
num = 0
test_sender = open("./sender/test_pem_sender_USA.txt", "r")
lines_sender = test_sender.readlines()

for line_l in lines_listen:
   line_l_splitted = line_l.split(' - ')
   #print(line_l_splitted[0])
   #print(line_l_splitted[2].split('\n')[0])
   for line_s in lines_sender:
      line_s_splitted = line_s.split(' - ')
      if line_s_splitted[0] == line_l_splitted[0]:
         #print(line_s_splitted[4])
         arrivo = float(line_l_splitted[2].split('\n')[0])
         invio_completo = float(line_s_splitted[4].split('\n')[0])
         invio_iniziato = float(line_s_splitted[3].split('\n')[0])
         print("Total time:" + str(arrivo-invio_iniziato) + "  Spread time:" + str(arrivo-invio_completo))
         tot_times += arrivo-invio_iniziato
         num+=1
         break

print(str(num) + " tests, with mean of total time: " + str (tot_times/num))
    
