#!/bin/bash
# Script that adds Cloudflare IP`s in UFW whitelist rules

# Default variables
cf_add=0
cf_cleanup=0
cf_refresh=0
cf_port=0
cf_port_value='80,443'

die() { echo "$*" >&2; exit 2; }  # complain to STDERR and exit with error
needs_arg() { if [ -z "$OPTARG" ]; then die "No arg for --$OPT option"; fi; }

cf_help () {
   echo -e "\nUsage: cloudflare-ufw.sh <--add|--cleanup|--refresh> [--port=http|https]" 

   # Display Help
   echo 
   echo -e "\033[1mRequired arguments:\033[0m"
   echo "  --add - add cloudflare IPs to UFW"
   echo "  --cleanup - clean up all added cloudflare records with comment 'Cloudflare UFW'"
   echo '  --refresh - Refresh UFW rules (removes IP`s that no longer belong to Cloudflare)'
   echo 
   echo -e "\033[1mOPTIONS:\033[0m"
   echo "  --port=(http|https), default - http (port 80) and https (port 443)"
}

cf_add () {
	# Get Cloudflare IPs
	curl --silent --show-error --fail https://www.cloudflare.com/ips-v4 > /tmp/cloudflare_ufw_ips
	echo "" >> /tmp/cloudflare_ufw_ips
	curl --silent --show-error --fail https://www.cloudflare.com/ips-v6 >> /tmp/cloudflare_ufw_ips

	if [ ! -s /tmp/cloudflare_ufw_ips ]; then
		echo -e "ERROR: /tmp/cloudflare_ufw_ips File is empty. Problem while getting Cloudflare IPs!"
		# TODO die
		exit 1
	fi

	# Loop IPs to add to UFW
	for cfip in $(cat /tmp/cloudflare_ufw_ips); do ufw allow proto tcp from "$cfip" to any port $cf_port_value comment 'Cloudflare UFW ('"$cf_port_value"')'; done
}

cf_clean () {
	if [ "$cf_port" -eq 1 ]; then
		# add brackets and port to grep
		grep_port="($cf_port_value)"
	else
		# no port defined, empty grep string
		grep_port=""
	fi

	# Count number of times to run ufw delete
	counter=$(ufw status numbered | grep -c "Cloudflare UFW $grep_port")

	until [ "$counter" -eq 0 ]; do
			CF_removeIP=$(ufw status numbered | grep -m1 "Cloudflare UFW $grep_port" | awk -F"[][]" '{print $2}')
			ufw --force delete "$CF_removeIP"
			((counter--))
	done
}

cf_refresh () {
	ufw allow "$cf_port_value"/tcp comment 'CF UFW Open'
	cf_clean
	cf_add
	ufw delete allow "$cf_port_value"/tcp comment 'CF UFW Open'
}

cf_port_mapping () {
	if [ "$cf_port" -eq 1 ]; then
		if [ "$cf_port_value" == "http" ]; then
			cf_port_value='80'
		elif [ "$cf_port_value" == "https" ]; then
			cf_port_value='443'
		else
			die "Wrong value '$cf_port_value' for arg '--port'"
		fi
	fi
}

## Long options getopts
while getopts achpr-: OPT; do
  # support long options: https://stackoverflow.com/a/28466267/519360
  if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}"       # extract long option name
    OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
  fi
	case "$OPT" in
		a | add ) cf_add=1 ;;
		c | cleanup ) cf_cleanup=1 ;;
		r | refresh ) cf_refresh=1 ;;
		p | port ) needs_arg; cf_port=1; cf_port_value=$OPTARG ;; 
		h | help ) cf_help ; exit 0 ;;
		??* ) die "Illegal option --$OPT" ;;  # bad long option
		? ) cf_help ; exit 2 ;;  # bad short option (error reported via getopts)
	esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list

## Start script
# Map --port option to real port
if [ "$cf_port" -eq 1 ]; then
	cf_port_mapping
fi

# Add function
if [ "$cf_add" -eq 1 ]; then
	cf_add
fi

# Clean function
if [ "$cf_cleanup" -eq 1 ]; then
	cf_clean
fi

# Refresh function
if [ "$cf_refresh" -eq 1 ]; then
	cf_refresh
fi