# cloudflare-ufw v2

Whitelist and manage Cloudflare IPs using UFW

|Argument|Comment|
|----------------------|---------------------------------------------------|
| --add                | Add CloudFlare IP`s to whitelist                  |
| --port=(http\|https) | Add CloudFlare IP`s to whitelist (specific port)  |
| --cleanup            | Delete UFW rules                                  |
| --help               | Print script help                                 |


## Examples:
Default usage (add all CloudFlare IP`s (IPv4 + IPv6) to Whitelist on all web ports (80+443)
```console
~/.cloudflare-ufw.sh --add
```
Allow CloudFlare IP`s only to HTTPS port (443)
```console
~/.cloudflare-ufw.sh --add --port=https
````
Clean all UFW rules, created with comment 'Cloudflare UFW'
```console
~/.cloudflare-ufw.sh --cleanup
```

## TODO list:
- ADD option --public
- ADD option --port to work with --cleanup
- ADD output: progress on adding or deleting ufw rules
- ADD output: Total CF rules from script: XXX
- ADD output: rules added, rule deleted
- ADD output when it's done
- ADD option --cron - Add cronjob to the current user
- ADD option --dry-run - Show output of commands that will be run
- Catch exit codes on command errors
- Logging
- Sent mails - verbose types, warning, error, etc. (on future version)