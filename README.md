# ARGS
$1 $2 $3 = subnet1 subnet2 subnet3 ...

# NOTES
This script uses nmap to list IP addresses available on the given subnets (nmap -sn).
IP addresses found are first looked up in /etc/hosts and if not found a DNS query is done

# CONFIG
Default network: 192.168
Use config file to change the default network where the subnets are appended.