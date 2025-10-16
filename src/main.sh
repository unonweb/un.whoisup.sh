#!/bin/bash

# ARGS
# ----
# $1 $2 $3 = subnet1 subnet2 subnet3 ...

# NOTES
# -----
# This script uses nmap to list IP addresses available on the given subnets (nmap -sn).
# IP addresses found are first looked up in /etc/hosts and if not found a DNS query is done

# CONFIG
# ------
# Default network: 192.168
# Use config file to change the default network where the subnets are appended.

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
FILE_CONFIG="${SCRIPT_DIR}/config.cfg"
declare -A CONFIG

function main() {
	
	local _net=""
	local _subnets=()
	local _subnet=""
	local _network=""
	local _col1=20 # ip
	local _col2=50 # host

	readFileToMap CONFIG ${FILE_CONFIG}

	# ARGS
	if [[ ${#} -gt 0 ]]; then
		_subnets=(${@}) # set subnets to args
	else
		_subnets=(${CONFIG[DEFAULT_SUBNETS]})
	fi	

	for _subnet in ${_subnets[@]}; do
		_network="${CONFIG[DEFAULT_NET]}.${_subnet}.0/24"

		# Use nmap to scan for live hosts and save their IP addresses
		# `-sn` does a ping scan (host discovery only)
		# `grep` extracts lines with "Nmap scan report for" and `awk` extracts the IP address
		echo -e "Scanning network: ${BOLD}${_network}${RESET} ..."
		
		local _available_ips=()
		local _ip

		for _ip in $(nmap -sn "${_network}" -oG - | grep "Up" | awk '{print $2}'); do
			_available_ips+=("${_ip}")
		done

		# Print out the array of available IP addresses
		# %-15s Left-align a string with a width of 15 characters
		# %-5d: Left-align an integer with a width of 5 characters
		echo ""
		printf "%-${_col1}s %-${_col2}s\n" "IP" "Host"
		printf "%-${_col1}s %-${_col2}s\n" "----" "----"

		for _ip in "${_available_ips[@]}"; do
			
			# get host - ask /etc/hosts
			local _getent=$(getent hosts ${_ip})
			local _host=${_getent#* } # Removes the part before the first space
			local _dns=false

			# if host is empty ask the dns
			if [[ -z ${_host} ]]; then
				_host=$(dig -x ${_ip} +short) # _dns reverse lookup if _host still empty
				_dns=true
			fi

			# set dns flag
			if [[ -n ${_host} && ${_dns} == true ]]; then
				_host+=" (dns)"
			fi

			# print resulting line
			printf "%-${_col1}s %-${_col2}s\n" "${_ip}" "${_host}"
		done

		echo ""

	done
}

main ${@}
