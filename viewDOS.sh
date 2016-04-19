#!/usr/bin/env bash

#############################################################################
#
# viewDOS is a simple script to quickly generate an ordered list of all IPs
# connected to multiple servers in X ports showing the amount of connections
# detailed with geolocation. It is intended to quickly get a report of
# suspicious IP addresses of several clusters under different types of DOS
# attacks. It just connects by SSH to different servers and uses netstat to
# obtain the desired information, as the ports and options defined in the
# script. ViewDOS only shows connections, no Bandwidth !.
#
# IP - Bandwidth Tools: iptraf, iftop, tcptrack, trafshow, pktstat, etc...
#
################################ Links ######################################
#
# Recommended IPs Blacklist: https://www.blocklist.de/en/export.html
#                            https://github.com/firehol/blocklist-ipsets
#
############################ Configuration ##################################

file_tmp="/tmp/viewDOS.$(date +%Y_%m_%d-%H_%M_%S).txt" # Temporary file
ports=":80 \|:443"                     		       # Filter IPs using any of the defined tcp/udp ports. Only UDP connections (ports="udp").
ignoreip="127.0.0.1\|localhost"          	       # IPs that will be ignored and will not be counted (whitelist) / Type "NO_filter" if you do not want to ignore any IP.

red=10                      # Red mark on hosts that have more than X connections.
red_tcp_state=2		    # Red mark on hosts that have more than X tcp connections to a particular state.

min_conn=0		    # Show only IPs that have more than X connections. (NO effect on IPs / TCP States counters).
min_state_conn=0	    # Show only IPs that have more than X tcp connections. (NO effect on IPs / TCP States counters).

netstat_cmd="netstat -ptun" # Netstat command and options that will run on the destination hosts to list connections (TCP / UDP / PID).
geoip_cmd="geoiplookup"     # Command geolocation + options, necessary to display geopositioned data.

tcp_state="SYN_RECV"  # tcp_state="SYN_RECV\|TIME_WAIT\|LAST_ACK\|CLOSE_WAIT"
		      # state TCP connections (FIN_WAIT2, SYN_RECV, UNKNOW, etc.)
                      # Multiple TCP states example: tcp_state="SYN_RECV\|TIME_WAIT\|CLOSE_WAIT".
                      # Multiple TCP states with separate output, check line 149.

date=$(date)
START=$(date +%s);

################################# Hosts ####################################
#
# Define the SSH commands as desired but always with '"$netstat_cmd" >> $file_tmp'
# You can add extra information if you want to see the raw output of netstat ($ file_tmp).

# ssh USER@DOMAIN "$netstat_cmd" >> $file_tmp
# ssh USER@DOMAIN -i /bla/bla/id_rsa -p 222  "$netstat_cmd" >> $file_tmp
# ...
################################# Code #####################################

# Show the whole list.
function global {	
        printf "\n %-5s  %-15s  %-30s\n" "TIMES" "   IP SOURCE" "   GEO - INFORMATION"
        printf " %-5s   %-15s   %-30s\n"

        for (( i=0; i<${arraylength}; i++ ));
        do
         total_conni=$((total_conni+array[$i]))

	if [ "${array[$i]}" -gt "$min_conn" ]; then

              geoip=$($geoip_cmd ${array[$i+1]} 2>/dev/null | sed -e s'/GeoIP Country Edition://' -e  s'/GeoIP ASNum Edition//' -e s'/GeoIP City Edition/ - City:/' -e s'/GeoIP City Edition, Rev 1://' -e s'/- City:, Rev 1://')

          if [ "${array[$i]}" -gt "$red" ]; then
                printf " $(tput bold)$(tput setaf 1)%-5s$(tput sgr 0) | $(tput bold)%-15s$(tput sgr 0) | $(tput bold)%-150s$(tput sgr 0)\n" ${array[$i]} ${array[$i+1]} "$geoip"

          else
                printf " %-5s | %-15s | %-150s\n" ${array[$i]} ${array[$i+1]} "$geoip"
          fi
	fi
        i=$((i+1))
       done
       echo -e "\n Total unique IPs: $((arraylength / 2))  Total connections: $total_conni"
       echo -e " IPs not included in the summation: $ignoreip" | sed -e s'/\\|/, /g'

	
       }

###################################
# Show TCP states total

function states_count {
        printf "\n %-5s  %-12s  %-11s\n" "TOTAL" " TCP STATE" "PERCENTAGE"
        printf " %-5s  %-12s %-11s\n"

        for (( i=0; i<${arraylength}; i++ ));
        do
                printf " %-5s | %-11s | %-11s\n" ${array[$i]} ${array[$i+1]} $(awk "BEGIN { pc=100*${array[$i]}/${total_conni}; i=int(pc); print (pc-i<0.5)?i:i+1 }")%
          i=$((i+1))
       done
       }

###################################
# Check SSH connections.

if [ ! -f $file_tmp ]; then
    echo "File $file_tmp not found, SSH commands configured correctly? [ ERROR ]" && exit
fi

###################################
# Calculate the total connections per IP address sorting the output.
END=$(date +%s);
ssh_duration=$((END-START))

times=$(grep "$ports" $file_tmp | awk '{print $5}' | grep -v "$ignoreip" |cut -d: -f1 | sort | uniq -c | sort -n )

array=($times)
arraylength=${#array[@]}

if [ "$arraylength" -lt "1" ]; then
        echo "$0: No connections are found, please check possible configuration errors. [ ERROR ]" && exit
fi

global $array[@] 


###################################
# Calculates TCP states totals (All IPs)

if [ "$min_conn" -ne 0 ];then
        echo " Filter applied: IP addresses with more than $min_conn connections."
fi

session_states=$(grep "$ports" $file_tmp | awk '{print $6}' | cut -d: -f1 | sort | uniq -c | sort -n )
array=($session_states)
arraylength=${#array[@]}
states_count $array[@]
echo -e "\n Filter 'ignoreip' is not applied here, only 'ports'"

###################################
# Calculate a list of IPs filtered by the TCP state defined in $ tcp_state and sorts the output.

## TCP state defined in the variable $tcp_state
state=$(grep "$ports" $file_tmp | grep $tcp_state | awk '{print $5}' | grep -v "$ignoreip" | cut -d: -f1 | sort | uniq -c | sort -n)
array=($state)
arraylength=${#array[@]}
total_conni=0
if [ "$arraylength" -lt "1" ]; then
	echo -e "\n\n Connections in state/s" $(echo $tcp_state | grep -o '[A-Z]*\|[A-Z]*_[A-Z]*'): "0\n" 
else
	echo -e "\n\n Connections in state/s" $(echo $tcp_state | grep -o '[A-Z]*\|[A-Z]*_[A-Z]*') 
	
        red=$red_tcp_state
	min_conn=$min_state_conn
        global $array[@]
fi

## Do you need more TCP states at the output? Easy, CLOSE_WAIT and FIN_WAIT1 examples. 
## Just copy and edit the three lines with the tcp state name 

## CLOSE_WAIT
#state=$(grep "$ports" $file_tmp | grep "CLOSE_WAIT" | awk '{print $5}' | grep -v "$ignoreip" | cut -d: -f1 | sort | uniq -c | sort -n)
#array=($state)
#arraylength=${#array[@]}
#total_conni=0
#if [ "$arraylength" -lt "1" ]; then
#        echo -e "\n\n Connections filtered by tcp state CLOSED: 0\n" 
#else
#        echo -e "\n\n Connections filtered by tcp state CLOSED"
#        red=$red_tcp_state
#	min_conn=$min_state_conn
#        global $array[@]
#fi

## FIN_WAIT1
#state=$(grep "$ports" $file_tmp | grep "FIN_WAIT1" | awk '{print $5}' | grep -v "$ignoreip" | cut -d: -f1 | sort | uniq -c | sort -n)
#array=($state)
#arraylength=${#array[@]}
#total_conni=0
#if [ "$arraylength" -lt "1" ]; then
#        echo -e "\n\n Connections filtered by tcp state FIN_WAIT1: 0\n"
#else
#        echo -e "\n\n Connections filtered by tcp state FIN_WAIT1"
#        red=$red_tcp_state
#	min_conn=$min_state_conn
#        global $array[@]
#fi

###############
# Useful information about the execution performed.

puertos=$(echo $ports | grep -o '[0-9]*')
echo -e "\n Ports used:" $puertos

if [ "$min_state_conn" -ne 0 ];then
        echo -e " Filter applied: IP addresses with more than $min_state_conn connections and tcp state $tcp_state.\n"
fi


echo -e " All netstat outputs are located in $file_tmp\n"
echo -e " The filter 'ignoreip' is ignored in the section 'Total TCP states'."
echo -e " SSH connections to `grep -i Address $file_tmp  | wc -l` Hosts has delayed $ssh_duration seconds."
echo -e " Date of execution: $date \n"
if [ -z "$geoip" ];then
	echo -e " IP geolocation not possible, 'min_conn' value too large or geoiplookup command not installed / configured in $0\n"
fi

# Date: 01/04/2016 (Author: Busindre).
# Network Abuse: http://www.x-arf.org/index.html
# How to report a DDOS attack: https://www.icann.org/news/blog/how-to-report-a-ddos-attack
# DDoS attacks worldwide http://www.digitalattackmap.com/
# DDoS latest News: http://www.ddosattacks.net/
