#!/bin/bash
# Script that adds Cloudflare IP`s in UFW whitelist rules


## TODO
# Function to add, list and remove IPs
# catch exit codes
# Logging

rm -f /tmp/cf_ips

# Get Cloudflare IPs
curl --silent --show-error --fail https://www.cloudflare.com/ips-v4 > /tmp/cf_ips
echo "" >> /tmp/cf_ips
curl --silent --show-error --fail https://www.cloudflare.com/ips-v6 >> /tmp/cf_ips

if [ ! -s /tmp/cf_ips ]; then
	echo -e "ERROR: /tmp/cf_ips File is empty. Problem while getting Cloudflare IPs!"
	exit 1
fi

CF_ips=$(ufw status numbered | grep "Cloudflare IP")
# Allow all 443 before loop remove
if [ ! -z "$CF_ips" ]; then
	echo -e "\nallow 443"
	ufw allow 443
	echo -e "\n$(echo "$CF_ips" | wc -l) IPs to delete!\n"
fi

# Loop remove CF Ips
while [ ! -z "$CF_ips" ]; do
	CF_removeIP=$(ufw status numbered | grep -m1 "Cloudflare IP" | awk -F"[][]" '{print $2}')
	ufw --force delete $CF_removeIP
	CF_ips=$(ufw status numbered | grep "Cloudflare IP")
done

# Loop to add IPS
for cfip in `cat /tmp/cf_ips`; do ufw allow proto tcp from $cfip to any port 443 comment 'Cloudflare IP'; done

# Delete allow all 443 after
ufw delete allow 443 > /dev/null 2>&1