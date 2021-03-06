#!/bin/sh
# Debian install script
# Script mod by Shien Ikiru 
# <shienikiru@gmail.com> <nauval2007@gmail.com>
# initialisasi var
echo "Mulai instalasi debian7"
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0'`;
MYIP2="s/xxxxxxxxx/$MYIP/g";
ETH=`ifconfig | grep Link`

if [[ $ETH == *"eth"* ]]
then
 ETH="eth0"
else
 ETH="venet0"
fi

# go to root
cd

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

# install wget and curl
apt-get update;apt-get -y install wget curl;

# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service ssh restart

# new git url wget ---no-check-certificate https://raw.githubusercontent.com/nauval2007/debian7os/master/debian7.sh
# set repo
wget -O /etc/apt/sources.list "https://raw.githubusercontent.com/nauval2007/debian7os/master/sources.list.debian7"
wget "http://www.dotdeb.org/dotdeb.gpg"
wget "http://www.webmin.com/jcameron-key.asc"
cat dotdeb.gpg | apt-key add -;rm -f dotdeb.gpg
cat jcameron-key.asc | apt-key add -;rm -f jcameron-key.asc

# remove unused
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove sendmail*;
apt-get -y --purge remove bind9*;

# update
apt-get update;
# apt-get -y upgrade;

# install webserver
apt-get -y install nginx php5-fpm php5-cli

# install essential package
echo "mrtg mrtg/conf_mods boolean true" | debconf-set-selections
apt-get -y install bmon iftop htop nmap axel nano iptables traceroute sysv-rc-conf dnsutils bc nethogs openvpn vnstat less screen psmisc apt-file whois ptunnel ngrep mtr git zsh mrtg snmp snmpd snmp-mibs-downloader unzip unrar rsyslog debsums rkhunter multitail
apt-get -y install build-essential

# install rcconf
apt-get -y install rcconf

# disable exim
service exim4 stop
sysv-rc-conf exim4 off

# update apt-file
apt-file update

# setting vnstat
vnstat -u -i venet0
service vnstat restart

# install screenfetch
cd
wget 'https://raw.githubusercontent.com/nauval2007/debian7os/master/screeftech-dev'
mv screeftech-dev /usr/bin/screenfetch
chmod +x /usr/bin/screenfetch
echo "clear" >> .profile
echo "screenfetch" >> .profile

# install webserver
cd
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/nauval2007/debian7os/master/nginx.conf"
mkdir -p /home/vps/public_html
echo "<pre>Modified by Shien Ikiru</pre>" > /home/vps/public_html/index.html
echo "<?php phpinfo(); ?>" > /home/vps/public_html/info.php
wget -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/nauval2007/debian7os/master/vps.conf"
sed -i 's/listen = \/var\/run\/php5-fpm.sock/listen = 127.0.0.1:9000/g' /etc/php5/fpm/pool.d/www.conf
service php5-fpm restart
service nginx restart

# install openvpn
wget -O /etc/openvpn/openvpn.tar "https://raw.githubusercontent.com/nauval2007/debian7os/master/openvpn-debian.tar"
cd /etc/openvpn/
tar xf openvpn.tar
wget -O /etc/openvpn/1194.conf "https://raw.githubusercontent.com/nauval2007/debian7os/master/1194.conf"
service openvpn restart
sysctl -w net.ipv4.ip_forward=1
# net.ipv4.conf.all.accept_source_route = 1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

# iptables -t nat -A POSTROUTING -s 10.9.8.0/24 -o venet0 -j SNAT --to xxx.xxx.xxx.xxx
#iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o venet0 -j SNAT --to $MYIP2
#iptables-save

wget -O /etc/iptables.up.rules "https://raw.githubusercontent.com/nauval2007/debian7os/master/iptables.up.rules"
sed -i '$ i\iptables-restore < /etc/iptables.up.rules' /etc/rc.local
sed -i $MYIP2 /etc/iptables.up.rules;
iptables-restore < /etc/iptables.up.rules

service openvpn restart

# configure openvpn client config
cd /etc/openvpn/
wget -O /etc/openvpn/1194-client.ovpn "https://raw.githubusercontent.com/nauval2007/debian7os/master/1194-client.conf"
sed -i $MYIP2 /etc/openvpn/1194-client.ovpn;
PASS=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1`;
useradd -M -s /bin/false shien
echo "shien:$PASS" | chpasswd
echo "username" >> pass.txt
echo "password" >> pass.txt
tar cf client.tar 1194-client.ovpn pass.txt
cp client.tar /home/vps/public_html/
cd

# install badvpn
wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/nauval2007/debian7os/master/badvpn-udpgw"
if [ "$OS" == "x86_64" ]; then
  wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/nauval2007/debian7os/master/badvpn-udpgw64"
fi
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.local
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300


# install mrtg
wget -O /etc/snmp/snmpd.conf "https://raw.githubusercontent.com/nauval2007/debian7os/master/snmpd.conf"
wget -O /root/mrtg-mem.sh "https://raw.githubusercontent.com/nauval2007/debian7os/master/mrtg-mem.sh"
chmod +x /root/mrtg-mem.sh
cd /etc/snmp/
sed -i 's/TRAPDRUN=no/TRAPDRUN=yes/g' /etc/default/snmpd
service snmpd restart
snmpwalk -v 1 -c public localhost 1.3.6.1.4.1.2021.10.1.3.1
mkdir -p /home/vps/public_html/mrtg
cfgmaker --zero-speed 100000000 --global 'WorkDir: /home/vps/public_html/mrtg' --output /etc/mrtg.cfg public@localhost
curl "https://raw.githubusercontent.com/nauval2007/debian7os/master/mrtg.conf" >> /etc/mrtg.cfg
sed -i 's/WorkDir: \/var\/www\/mrtg/# WorkDir: \/var\/www\/mrtg/g' /etc/mrtg.cfg
sed -i 's/# Options\[_\]: growright, bits/Options\[_\]: growright/g' /etc/mrtg.cfg
indexmaker --output=/home/vps/public_html/mrtg/index.html /etc/mrtg.cfg
if [ -x /usr/bin/mrtg ] && [ -r /etc/mrtg.cfg ]; then mkdir -p /var/log/mrtg ; env LANG=C /usr/bin/mrtg /etc/mrtg.cfg 2>&1 | tee -a /var/log/mrtg/mrtg.log ; fi
if [ -x /usr/bin/mrtg ] && [ -r /etc/mrtg.cfg ]; then mkdir -p /var/log/mrtg ; env LANG=C /usr/bin/mrtg /etc/mrtg.cfg 2>&1 | tee -a /var/log/mrtg/mrtg.log ; fi
if [ -x /usr/bin/mrtg ] && [ -r /etc/mrtg.cfg ]; then mkdir -p /var/log/mrtg ; env LANG=C /usr/bin/mrtg /etc/mrtg.cfg 2>&1 | tee -a /var/log/mrtg/mrtg.log ; fi
cd

# setting port ssh
sed -i '/Port 22/a Port  143' /etc/ssh/sshd_config
#sed -i '/Port 22/a Port  80' /etc/ssh/sshd_config
sed -i 's/Port 22/Port  22/g' /etc/ssh/sshd_config
sed -i 's/#Banner/Banner/g' /etc/ssh/sshd_config
service ssh restart

# install dropbear
# -K keepalivetimeout -I iddletimetimeout
apt-get -y install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=443/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-K 10 -I 60"/g' /etc/default/dropbear
sed -i 's/DROPBEAR_BANNER=""/DROPBEAR_BANNER="\/etc\/issue.net "/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
service ssh restart
service dropbear restart

# new url https://matt.ucc.asn.au/dropbear/releases/dropbear-2015.68.tar.bz2
# upgrade dropbear 2015
apt-get install -y zlib1g-dev
# wget https://matt.ucc.asn.au/dropbear/releases/dropbear-2014.66.tar.bz2
wget https://matt.ucc.asn.au/dropbear/releases/dropbear-2015.68.tar.bz2
bzip2 -cd dropbear-2015.68.tar.bz2  | tar xvf -
cd dropbear-2015.68
./configure
make && make install
mv /usr/sbin/dropbear /usr/sbin/dropbear1
ln /usr/local/sbin/dropbear /usr/sbin/dropbear
service dropbear restart

# install vnstat gui
cd /home/vps/public_html/
wget http://www.sqweek.com/sqweek/files/vnstat_php_frontend-1.5.1.tar.gz
tar xf vnstat_php_frontend-1.5.1.tar.gz
rm -f vnstat_php_frontend-1.5.1.tar.gz
mv vnstat_php_frontend-1.5.1 vnstat
cd vnstat
if [[ $ETH == *"venet"* ]]
then
	sed -i 's/eth0/venet0/g' config.php
	sed -i "s/\$iface_list = array('venet0', 'sixxs');/\$iface_list = array('venet0');/g" config.php
fi
sed -i "s/\$language = 'nl';/\$language = 'en';/g" config.php
sed -i 's/Internal/Internet/g' config.php
sed -i '/SixXS IPv6/d' config.php
cd

# vnstat fix
touch /var/lib/vnstat/.venet0
chown -R vnstat:vnstat /var/lib/vnstat/.venet0

# /etc/vnstat.conf
# Interface "venet0"
if [[ $ETH == *"venet"* ]]
then
	sed -i 's/eth0/venet0/g' /etc/vnstat.conf
fi

# install fail2ban
apt-get -y install fail2ban;service fail2ban restart

# install squid3
apt-get -y install squid3
wget -O /etc/squid3/squid.conf "https://raw.githubusercontent.com/nauval2007/debian7os/master/squid3.conf"
sed -i $MYIP2 /etc/squid3/squid.conf;
# service squid3 restart

# disable squid
sysv-rc-conf squid3 off
service squid3 stop

# install webmin

# wget method
cd
## wget http://prdownloads.sourceforge.net/webadmin/webmin_1.710_all.deb
#wget http://prdownloads.sourceforge.net/webadmin/webmin_1.760_all.deb
#dpkg -i --force-all webmin_1.760_all.deb;
#apt-get -y -f install;
#rm /root/webmin_1.760_all.deb

# apt method
cd /root
wget http://www.webmin.com/jcameron-key.asc
apt-key add jcameron-key.asc 

# apt-get update
apt-get -y install webmin

service webmin restart
service vnstat restart

# install webmin module
# cd /usr/share/webmin/module-archives/
mkdir webmin-module
cd webmin-module/
# disk usage
wget http://www.webmin.com/download/modules/disk-usage.wbm.gz
# http://www.niemueller.de/webmin/modules/upload/
# mrtg
wget http://www.jla.homepage.t-online.de/pub/webmin/mrtg-0.2p3.wbm
# squid (standard already installed)
# http://www.webmin.com/webmin/download/modules/sarg.wbm.gz
# squidguard
wget http://perso.efrei.fr/~tabary/webmin/squidguard/squidguard.wbm.gz
# squid realtime monitor
wget http://sourceforge.net/projects/squidrealmon/files/sq-real-mon.wbm.gz
# squid info
http://swelltech.com/projects/webmin/modules/squidinfo-1.170.wbm
# webalizer ( standard already installed )
# http://www.webmin.com/webmin/download/modules/webalizer.wbm.gz
# openvpn
wget http://www.openit.it/downloads/OpenVPNadmin/openvpn-2.6.wbm.gz
# nginx
wget http://www.justindhoffman.com/sites/justindhoffman.com/files/nginx-0.08.wbm__0.gz

#
/usr/share/webmin/install-module.pl ./disk-usage.wbm.gz
/usr/share/webmin/install-module.pl ./mrtg-0.2p3.wbm
#/usr/share/webmin/install-module.pl ./squidguard.wbm.gz
#/usr/share/webmin/install-module.pl ./squidguard.wbm.gz
#/usr/share/webmin/install-module.pl ./sq-real-mon.wbm.gz
#/usr/share/webmin/install-module.pl ./squidinfo-1.170.wbm
/usr/share/webmin/install-module.pl ./openvpn-2.6.wbm.gz
/usr/share/webmin/install-module.pl ./nginx-0.08.wbm__0.gz


service webmin restart


# download script
cd
wget -O speedtest_cli.py "https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest_cli.py"
wget -O bench-network.sh "https://raw.githubusercontent.com/nauval2007/debian7os/master/bench-network.sh"
wget -O ps_mem.py "https://raw.githubusercontent.com/pixelb/ps_mem/master/ps_mem.py"
wget -O dropmon "https://raw.githubusercontent.com/nauval2007/debian7os/master/dropmon.sh"
wget -O userlogin.sh "https://raw.githubusercontent.com/nauval2007/debian7os/master/userlogin.sh"
wget -O userexpired.sh "https://raw.githubusercontent.com/nauval2007/debian7os/master/userexpired.sh"
wget -O userlimit.sh "https://raw.githubusercontent.com/nauval2007/debian7os/master/userlimit.sh"
wget -O userlimit-os.sh "https://raw.githubusercontent.com/nauval2007/debian7os/master/userlimit-os.sh"
wget -O expire.sh "https://raw.githubusercontent.com/nauval2007/debian7os/master/expire.sh"
wget -O autokill.sh "https://raw.githubusercontent.com/nauval2007/debian7os/master/autokill.sh"
wget -O delete-log.sh "https://raw.githubusercontent.com/nauval2007/debian7os/master/delete-log.sh"
wget -O find-large-files.sh "https://raw.githubusercontent.com/nauval2007/debian7os/master/find-large-files.sh"
wget -O vpnmon "https://raw.githubusercontent.com/nauval2007/debian7os/master/vpnmon"
wget -O /etc/issue.net "https://raw.githubusercontent.com/nauval2007/debian7os/master/banner"
wget -O userloginhist.sh "https://raw.githubusercontent.com/nauval2007/debian7os/master/userloginhist.sh"
wget -O vpnmonhist "https://raw.githubusercontent.com/nauval2007/debian7os/master/vpnmonhist"
wget -O runevery.sh "https://raw.githubusercontent.com/nauval2007/debian7os/master/runevery.sh"
echo "* * * * * root /root/userexpired.sh" > /etc/cron.d/userexpired
echo "* * * * * root /root/userlimit.sh 2" > /etc/cron.d/userlimit
echo "* * * * * root /root/userlimit-os.sh 2" > /etc/cron.d/userlimit-os
echo "* * * * * root /root/runevery.sh 5" > /etc/cron.d/runevery
echo "0 */6 * * * root /sbin/reboot" > /etc/cron.d/reboot
echo "* * * * * service dropbear restart" > /etc/cron.d/dropbear
echo "* */1 * * * root /root/userloginhist.sh >> /root/userloginhist.txt" > /etc/cron.d/userloginhist
echo "* - maxlogins 2" >> /etc/security/limits.conf
#echo "@reboot root /root/autokill.sh" > /etc/cron.d/autokill
#sed -i '$ i\screen -AmdS check /root/autokill.sh' /etc/rc.local

# php5-fpm service error fix for some debian 8
#echo "@reboot root /usr/sbin/php5-fpm -D" >> /etc/crontab

# snmp log fix
# sed -i 's/SNMPDOPTS/#SNMPDOPTS/g'  /etc/defaults/snmpd
# sed -i 's/TRAPDOPTS/#TRAPDOPTS/g'  /etc/defaults/snmpd
# sed -i "SNMPDOPTS='-LS6d -Lf /dev/null -u snmp -g snmp -I -smux -p /var/run/snmpd.pid'" /etc/squid3/squid.conf;
# sed -i "TRAPDOPTS='-LS6d -p /var/run/snmptrapd.pid'" /etc/squid3/squid.conf;

chmod +x bench-network.sh
chmod +x speedtest_cli.py
chmod +x ps_mem.py
chmod +x userlogin.sh
chmod +x userexpired.sh
chmod +x userlimit.sh
chmod +x userlimit-os.sh
chmod +x autokill.sh
chmod +x dropmon
chmod +x expire.sh
chmod +x delete-log.sh
chmod +x find-large-files.sh
chmod +x vpnmon
chmod +x userloginhist.sh
chmod +x vpnmonhist
chmod +x runevery.sh

# finishing
chown -R www-data:www-data /home/vps/public_html
service cron restart
service nginx start
service php-fpm start
service vnstat restart
service openvpn restart
service snmpd restart
service ssh restart
service dropbear restart
service fail2ban restart
# service squid3 restart
service webmin restart
rm -rf ~/.bash_history && history -c
echo "unset HISTFILE" >> /etc/profile

# info
clear
echo "ShienVPS | server |"
echo ""  | tee -a log-install.txt
echo "AUTOSCRIPT INCLUDES" | tee log-install.txt
echo "===============================================" | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Service"  | tee -a log-install.txt
echo "-------"  | tee -a log-install.txt
echo "■ OpenVPN  : TCP 1194 (client config : http://$MYIP:81/client.tar)"  | tee -a log-install.txt
echo "■ OpenSSH  : 22, 80, 143"  | tee -a log-install.txt
echo "■ Dropbear : 443, 110, 109"  | tee -a log-install.txt
echo "■ Squid3   : 8080 (limit to IP SSH)"  | tee -a log-install.txt
echo "■ badvpn   : badvpn-udpgw port 7300"  | tee -a log-install.txt
echo "■ nginx    : 81"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Tools"  | tee -a log-install.txt
echo "-----"  | tee -a log-install.txt
echo "■ axel"  | tee -a log-install.txt
echo "■ bmon"  | tee -a log-install.txt
echo "■ htop"  | tee -a log-install.txt
echo "■ iftop"  | tee -a log-install.txt
echo "■ mtr"  | tee -a log-install.txt
echo "■ rkhunter"  | tee -a log-install.txt
echo "■ nethogs: nethogs venet0"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Script"  | tee -a log-install.txt
echo "------"  | tee -a log-install.txt
echo "■ screenfetch"  | tee -a log-install.txt
echo "■ ./ps_mem.py"  | tee -a log-install.txt
echo "■ ./speedtest_cli.py --share"  | tee -a log-install.txt
echo "■ ./bench-network.sh"  | tee -a log-install.txt
echo "■ ./userlogin.sh" | tee -a log-install.txt
echo "■ ./userexpired.sh" | tee -a log-install.txt
echo "■ ./userlimit.sh 2 [ini utk melimit max 2 login]" | tee -a log-install.txt
echo "■ sh dropmon [port] contoh: sh dropmon 443" | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Fitur lain"  | tee -a log-install.txt
echo "----------"  | tee -a log-install.txt
echo "■ Webmin   : https://$MYIP:10000/"  | tee -a log-install.txt
echo "■ vnstat   : http://$MYIP:81/vnstat/"  | tee -a log-install.txt
echo "■ MRTG     : http://$MYIP:81/mrtg/"  | tee -a log-install.txt
echo "■ Timezone : Asia/Jakarta"  | tee -a log-install.txt
echo "■ Fail2Ban : [on]"  | tee -a log-install.txt
echo "■ IPv6     : [off]"  | tee -a log-install.txt
echo "Account Default (utk SSH dan VPN)"
echo "---------------"
echo "User     : shien"
echo "Password : $PASS"
echo ""  | tee -a log-install.txt
echo "Script Modified by  Shien Ikiru"  | tee -a log-install.txt
echo "Thanks to Original Creator Yurissh Kang Arie & Mikodemos"
echo ""  | tee -a log-install.txt
echo "VPS AUTO REBOOT TIAP 6 JAM"  | tee -a log-install.txt
echo "SILAHKAN REBOOT VPS ANDA"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "==============================================="  | tee -a log-install.txt
cd
rm -f /root/debian7.sh
