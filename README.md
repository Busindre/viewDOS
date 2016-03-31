# viewDOS
Simple shellscript to quickly generate an ordered list of all IPs connected to multiple servers in X ports, showing the amount of connections detailed with geolocation. 

It is intended to quickly get a report of suspicious IP addresses of several clusters under different types of DOS attacks. It just connects by SSH to different servers and uses netstat to obtain the desired information.

**Dependency** (optional but recommended).

Command geoiplookup / [geoip-bin] (http://dev.maxmind.com/geoip/geoip2/geolite2/ "MaxMind’s GeoIP2 databases.")

**viewDOS configuration options**.

```sh
# Temporary file name.
file_tmp="/tmp/viewDOS.$(date +%Y_%m_%d-%H_%M_%S).txt" 

# Filter IPs using any of the defined tcp/udp ports.
ports=":80 \|:443"                     

# IPs that will be ignored and will not be counted (whitelist).
ignoreip="127.0.0.1\|localhost"

# Red mark on hosts that have more than X connections.
red=5                       

# Red mark on hosts that have more than X tcp connections to a particular state.
red_tcp_state=2		    

# Show only IPs that have more than X connections.
min_conn=0		    

# Show only IPs that have more than X tcp connections.
min_state_conn=0	    

# Netstat command and options that will run on the destination hosts to list connections (TCP / UDP / PID).
netstat_cmd="netstat -ptun" 

# Command geolocation + options, necessary to display geopositioned data.
geoip_cmd="geoiplookup"     

# state TCP connections (FIN_WAIT2, SYN_RECV, UNKNOW, etc.)
tcp_state="SYN_RECV"
# Multiple TCP states example: tcp_state="SYN_RECV\|TIME_WAIT\|CLOSE_WAIT".
# Multiple TCP states with separate output, check line 132.
```

**Sample viewDOS output**.
```sh
 TIMES     IP SOURCE        GEO - INFORMATION      
 3     | 95.211.225.139  |   NL, 07, Noord-Holland, N/A, N/A, 52.349998, 4.916700, 0, 0
 4     | 122.144.130.4   |   CN, 23, Shanghai, Shanghai, N/A, 31.045601, 121.399696, 0, 0
 4     | 45.55.232.1     |   US, NY, New York, New York, 10118, 40.714298, -74.005997, 501, 212                               
 4     | 80.110.68.170   |   AT, 09, Wien, Vienna, 1100, 48.152100, 16.387800, 0, 0                                           
 ...
 5     | 88.72.110.58    |   DE, 02, Bayern, Obertraubling, 93083, 48.971298, 12.175000, 0, 0                                 
 6     | 123.252.131.212 |   IN, 16, Maharashtra, Bandra, 360330, 19.049999, 72.833298, 0, 0                                  
 6     | 147.30.236.76   |   KZ, 16, North Kazakhstan, Petropavlovsk, N/A, 54.872799, 69.142998, 0, 0                         
 7     | 207.233.90.1    |   US, CA, California, Palmdale, 93550, 34.520000, -118.083504, 803, 661                            
 21    | 71.43.188.26    |   US, FL, Florida, Oviedo, 32765, 28.676600, -81.199097, 534, 407                                                                                     

 Total unique IPs: 1055  Total connections: 1307
 Filter applied: IP addresses with more than 3 connections.

 TOTAL   TCP STATE    PERCENTAGE 
                                
 2     | CLOSING     | 0%         
 3     | TIME_WAIT   | 0%         
 7     | LAST_ACK    | 1%         
 10    | FIN_WAIT1   | 1%         
 25    | SYN_RECV    | 2%         
 79    | CLOSE_WAIT  | 6%         
 1181  | ESTABLISHED | 90%        


 Connections in state/s SYN_RECV

 TIMES     IP SOURCE        GEO - INFORMATION          
                                                         
 1     | 163.180.118.60  |   KR, 13, Kyonggi-do, Suwon, N/A, 37.291100, 127.008904, 0, 0                                      
 1     | 178.62.250.138  |   NL, 07, Noord-Holland, Amsterdam, 1000, 52.374001, 4.889700, 0, 0                                
 1     | 216.46.148.192  |   CA, ON, Ontario, Grand Bend, N/A, 43.316700, -81.750000, 0, 0                                    
 ...
 1     | 95.56.142.184   |   KZ, 02, Almaty City, Almaty, N/A, 43.256500, 76.928497, 0, 0                                     
 2     | 207.47.199.35   |   CA, SK, Saskatchewan, Regina, S4P, 50.418999, -104.677399, 0, 0                                  
 3     | 10.3.176.41     |   IP Address not found                                                                             
 3     | 86.57.158.178   |   BY, 04, Minsk, Minsk, N/A, 53.900002, 27.566700, 0, 0                                                                                               

 Total unique IPs: 20  Total connections: 25

 Ports used: 80 443 22 
 Filter applied: IP addresses with more than 1 connection and tcp state SYN_RECV.

 All netstat outputs are located in /tmp/viewDOS.2014_03_21-01_10_58.txt

 SSH connections to 4 Hosts has delayed 16 seconds.
 Date of execution: thue Mar 31 01:10:58 CEST 2014 
```
