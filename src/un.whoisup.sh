#!/bin/bash

# ARGS
# ----
# $1 = SUBNET

# USE
# ---
# fk.whoisup 5
# fk.whoisup 10
# fk.whoisup 222

# BOILERPLATE
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
SCRIPT_NAME=$(basename -- "$(readlink -f "${BASH_SOURCE}")")

ESC=$(printf "\e")
BOLD="${ESC}[1m"
RESET="${ESC}[0m"
RED="${ESC}[31m"
GREEN="${ESC}[32m"
BLUE="${ESC}[34m"
UNDERLINE="${ESC}[4m"

# FUNCTIONS
source "${SCRIPT_DIR}/lib/readFileToMap.sh"

# CONSTANTS
FILE_IPS_HOSTS="${SCRIPT_DIR}/ips_hosts.txt"
FILE_HOSTS_USERS="${SCRIPT_DIR}/hosts_users.txt"
SUBNETS=(10 222) # default

# ARGS
if [[ ${1} ]]; then
	SUBNETS=${1}
fi

function main() {

	declare -A hostsUsers
	declare -A ipsHosts
	readFileToMap ipsHosts ${FILE_IPS_HOSTS}
	readFileToMap hostsUsers ${FILE_HOSTS_USERS}

	local -n subnets=SUBNETS

	local col1=20 # ip address
	local col2=35 # host
	local col3=25 # user

	for subnet in ${subnets[@]}; do
		network="192.168.${subnet}.0/24"

		# Use nmap to scan for live hosts and save their IP addresses
		# `-sn` does a ping scan (host discovery only)
		# `grep` extracts lines with "Nmap scan report for" and `awk` extracts the IP address
		echo -e "Scanning network: \e[1m${network}\e[0m..."
		availableIPs=()
		for ip in $(nmap -sn "$network" -oG - | grep "Up" | awk '{print $2}'); do
			availableIPs+=("${ip}")
		done

		# Print out the array of available IP addresses
		echo ""
		printf "%-${col1}s %- ${col2}s %- ${col3}s\n" "IP" "Host" "User"
		echo "----------------------------------------------------------------------------"

		for ip in "${availableIPs[@]}"; do
			# get host
			host=${ipsHosts[${ip}]}
			dns=false
			if [[ -z ${host} ]]; then
				host=$(dig -x ${ip} +short) # dns reverse lookup if host still empty
				dns=true
			fi
			# get user
			if [[ -n $host ]]; then
				host="${host//$'\n'/ }"  # replace newlines with spaces
				host="${host//.fknet./}" # replace .fknet. with nothing
				user=${hostsUsers[$host]}
			fi
			if [[ -n ${host} && ${dns} == true ]]; then
				host+=" (dns)"
			fi
			# Loop through the keys and check if each is a substring of the value
			#for key in "${!hostsUsers[@]}"; do
			#    if [[ "$host" == *"$key"* ]]; then
			#        user=${hostsUsers[$key]}
			#        break
			#    fi
			#done
			printf "%-${col1}s %- ${col2}s %- ${col3}s\n" "${ip}" "${host}" "${user}"
		done

		echo ""

	done
}

main
