# cloudflare-ufw v2

Whitelist and manage Cloudflare IPs using UFW

Usage: cloudflare-ufw.sh <--add|--cleanup|--refresh> [--port=http|https]

| Arguments             | Comment                                                              |
|-----------------------|----------------------------------------------------------------------|
| --add (--port)        | Add Cloudflare IP`s to whitelist                                     |
| --cleanup (--port)    | Delete UFW rules containing 'Cloudflare UFW' comment                 |
| --refresh (--port)    | Refresh UFW rules (removes IP`s that no longer belong to Cloudflare) |
| --help                | Print script help                                                    |

| Options              | Comment                                                               |
|----------------------|-----------------------------------------------------------------------|
| --port=(http\|https) | Add Cloudflare IP`s to whitelist (specific port)                      |


## Examples:
Default usage. Add all Cloudflare IP`s (IPv4 + IPv6) to Whitelist on all web ports (80+443)
```console
~/.cloudflare-ufw.sh --add
```
Allow Cloudflare IP`s only to HTTPS port (443)
```console
~/.cloudflare-ufw.sh --add --port=https
````
Clean all UFW rules, created with comment 'Cloudflare UFW'
```console
~/.cloudflare-ufw.sh --cleanup
```
Refresh UFW rules (Temporary allow all traffic to web ports (80+443), delete all existing Cloudflare rules and readd them from Cloudflare list)
```console
~/.cloudflare-ufw.sh --refresh
```
Delete all existing Cloudflare UFW rules and add Cloudflare IP`s to whitelist for defined Web ports - http (80), https (443) 
```console
~/.cloudflare-ufw.sh --refresh --port=(http|https)
```

## TODO list:
- ADD add Usage to README
- prerequirements - allowed ssh (ufw allow ssh), Set default rules incomming/outgoing, enabled UFW
- ufw status "disabled" = echo "Rules added, but UFW is disabled. Please review rules and enable UFW"
- check if ufw is installed

- ADD option --public combined with --cleanup and --port
- ADD option --cron - Add cronjob to the current user
- ADD option --dry-run - Show output of commands that will be run
- ADD option --debug - Output script variables

- ADD output: progress on adding or deleting ufw rules
- ADD output: Total CF rules from script: XXX
- ADD output: rules added, rule deleted
- ADD output when it's done

- Catch exit codes on command errors
- Logging
- Sent mails - verbose types, warning, error, etc. (on future version)