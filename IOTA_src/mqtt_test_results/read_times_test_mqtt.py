tot_times = 0
num = 0
test_listen = open("test_txt_listener_EU-AUS.txt", "r") 
lines_listen = test_listen.readlines()
		
test_sender = open("test_txt_sender_EU-AUS.txt", "r")
lines_sender = test_sender.readlines()

diff = open("diff_mqtt_EU-AUS_txt.txt","w")

for line_l in lines_listen:
   line_l_splitted = line_l.split(' - ')
   #print(line_l_splitted[0])
   #print(line_l_splitted[2].split('\n')[0])
   for line_s in lines_sender:
      line_s_splitted = line_s.split(' - ')
      if line_s_splitted[0] == line_l_splitted[0]:
         #print(line_s_splitted[4])
         arrivo = float(line_l_splitted[2].split('\n')[0])
         invio = float(line_s_splitted[3].split('\n')[0])
         tempo = (arrivo - invio) * 1000
         print(str(num) + "    " + str(tempo))
         diff.write(str(num) + " - " + str(int(tempo)) +"\n")
         tot_times += tempo
         num+=1
         break
print(str(num) + " tests, with mean of total time: " + str(tot_times/num))
    
