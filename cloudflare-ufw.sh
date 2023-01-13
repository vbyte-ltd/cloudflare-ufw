#!/bin/bash
# Script that adds Cloudflare IP`s in UFW whitelist rules

# Default variables
cf_add=0
cf_cleanup=0
cf_refresh=0
cf_port=0
cf_port_value='80,443'

# Colours
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD_GREEN='\033[1;32m'
NC='\033[0m' # No Color

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

	counter_added=0
	counter_skipped=0
	add_output_counter=$(wc -l < /tmp/cloudflare_ufw_ips)
	((add_output_counter++))

	# Loop IPs to add to UFW
	echo -e "Total number of Cloudflare entries: $add_output_counter"
	for cfip in $(cat /tmp/cloudflare_ufw_ips); do
		result_add=$(ufw allow proto tcp from "$cfip" to any port "$cf_port_value" comment 'Cloudflare UFW ('"$cf_port_value"')')
		#sleep 0.2
		if [ "$result_add" = 'Rule added' ] || [ "$result_add" = 'Rule added (v6)' ]; then
			((counter_added++))
            echo -n -e "Rules added: ${GREEN}"$counter_added"${NC}\r"
        else
			((counter_skipped++))
		fi
	done

	# Erase the line and move cursor 2 lines up
	echo -e "\033[K\033[2A\n"
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
	clean_output_counter=$counter

	until [ "$counter" -eq 0 ]; do
			CF_removeIP=$(ufw status numbered | grep -m1 "Cloudflare UFW $grep_port" | awk -F"[][]" '{print $2}')
			ufw --force delete "$CF_removeIP" &> /dev/null
			((counter--))
			echo -n -e "Remaining rules to delete: ${RED}"$counter"${NC} of $clean_output_counter \r"
	done

	# Erase the line and move cursor 2 lines up
	echo -e "\033[K\033[2A\n"
}

cf_refresh () {
	ufw allow "$cf_port_value"/tcp comment 'CF UFW Open' &> /dev/null
	cf_clean; cf_cleanup=1
	cf_add; cf_add=1
	ufw delete allow "$cf_port_value"/tcp comment 'CF UFW Open' &> /dev/null
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
		??* ) die "Illegal option --$OPT" ;;  # bad long option # TODO call help somehow
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
	# restrict combining main arguments
	if [ "$cf_cleanup" -eq 1 ] || [ "$cf_refresh" -eq 1 ]; then
		cf_help;
		echo -e "\n${RED}Error:${NC}"
		die "Conflicting functions. Can't run --add with --cleanup or --refresh"
	fi
	cf_add
fi

# Clean function
if [ "$cf_cleanup" -eq 1 ]; then
	# restrict combining main arguments
	if [ "$cf_add" -eq 1 ] || [ "$cf_refresh" -eq 1 ]; then
		cf_help;
		echo -e "\n${RED}Error:${NC}"
		die "Conflicting functions. Can't run --cleanup with --add or --refresh"
	fi
	cf_clean
fi

# Refresh function
if [ "$cf_refresh" -eq 1 ]; then
	# restrict combining main arguments
	if [ "$cf_add" -eq 1 ] || [ "$cf_cleanup" -eq 1 ]; then
		cf_help;
		echo -e "\n${RED}Error:${NC}"
		die "Conflicting functions. Can't run --refresh with --add or --cleanup"
	fi
	cf_refresh
fi

## Output results
echo -e "\n${BOLD_GREEN}Result:${NC}"

if [ "$cf_cleanup" -eq 1 ]; then
	echo -e "UFW rules deleted: ${RED}$clean_output_counter${NC}"
fi

if [ "$cf_add" -eq 1 ]; then
	echo -e "UFW rules added: ${GREEN}$counter_added${NC}"
	if [ "$cf_refresh" -eq 0 ]; then
		echo -e "UFW rules skipped: ${BLUE}$counter_skipped${NC}"
	fi
fi