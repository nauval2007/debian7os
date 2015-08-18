echo deleting log files....
rm -f /var/log/*.*
rm -f /var/log/httpd/*.*
rm -f /var/log/squid/*.*
rm -f /var/log/messages

rm -f /usr/local/vpnserver/security_log/VPN/*.log
rm -f /usr/local/vpnserver/packet_log/VPN/*.log
rm -f /usr/local/vpnserver/server_log/*.log

