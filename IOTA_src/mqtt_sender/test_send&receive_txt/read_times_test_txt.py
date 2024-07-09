
test_listen = open("test_txt_listener.txt", "r") 
lines_listen = test_listen.readlines()
		
test_sender = open("./sender/test_txt_sender.txt", "r")
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
         invio = float(line_s_splitted[4].split('\n')[0])
         print(arrivo-invio)
         break
    
