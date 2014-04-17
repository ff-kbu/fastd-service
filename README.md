# Fastd-Service
Webservices, offered by fastd-VPN-servers within Freifunk-KBU. Including

* http-based key-upload
* batman-adv graph rendering
* processing of watchdog-data
* notifying other hosts (statistics, register) on new hosts

_Please note_: Almost all code (especially http-requests) is Freifunk-KBU specific and may be modified for other networks.

## Deployment
Sinatra APP, deploy it using your favorite application-server. 
Dependencies (gem):
* sinatra
* sinatra-contrib
* netaddr

## Configuration
See config.yml.template for valid configuration options


