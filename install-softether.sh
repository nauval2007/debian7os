# Softether Installation Script
# installing softether for debian/centos
# copyright Shien Ikiru <nauval2007@gmail.com>
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0'`;
ETH=`ifconfig | grep Link`

if [[ $ETH == *"eth"* ]]
then
	ETH="eth0"
else
	ETH="venet0"
fi
cd 
# ppa:dajhorn/softether 
wget -O softether-vpnserver.tar.gz http://www.softether-download.com/files/softether/v4.18-9570-rtm-2015.07.26-tree/Linux/SoftEther_VPN_Server/32bit_-_Intel_x86/softether-vpnserver-v4.18-9570-rtm-2015.07.26-linux-x86-32bit.tar.gz

if [ "$OS" == "x86_64" ]; then
  wget -O softether-vpnserver.tar.gz "http://softether-download.com/files/softether/v4.18-9570-rtm-2015.07.26-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.18-9570-rtm-2015.07.26-linux-x64-64bit.tar.gz"
fi

tar -xvf softether-vpnserver.tar.gz

cd vpnserver
make
cp -R * /usr/local/vpnserver/

# wget -O /etc/init.d/vpnserver https://raw.githubusercontent.com/nauval2007/centos/master/vpnserver
# nano /etc/init.d/vpnserver


echo "### BEGIN INIT INFO" > /etc/init.d/vpnserver
echo "# Provides:          vpnserver" >> /etc/init.d/vpnserver
echo "# Required-Start:    $remote_fs $syslog" >> /etc/init.d/vpnserver
echo "# Required-Stop:     $remote_fs $syslog" >> /etc/init.d/vpnserver
echo "# Default-Start:     2 3 4 5" >> /etc/init.d/vpnserver
echo "# Default-Stop:      0 1 6" >> /etc/init.d/vpnserver
echo "# Short-Description: Start daemon at boot time" >> /etc/init.d/vpnserver
echo "# Description:       Enable Softether by daemon." >> /etc/init.d/vpnserver
echo "### END INIT INFO" >> /etc/init.d/vpnserver
echo "DAEMON=/usr/local/vpnserver/vpnserver" >> /etc/init.d/vpnserver
echo "LOCK=/var/lock/subsys/vpnserver" >> /etc/init.d/vpnserver
echo "TAP_ADDR=192.168.250.1" >> /etc/init.d/vpnserver
echo "" >> /etc/init.d/vpnserver
echo "test -x $DAEMON || exit 0" >> /etc/init.d/vpnserver
echo 'case "$1" in' >> /etc/init.d/vpnserver
echo "start)" >> /etc/init.d/vpnserver
echo "$DAEMON start" >> /etc/init.d/vpnserver
echo "touch $LOCK"  >> /etc/init.d/vpnserver
echo "sleep 1"  >> /etc/init.d/vpnserver
echo "/sbin/ifconfig tap_soft $TAP_ADDR"  >> /etc/init.d/vpnserver
echo "iptables -t nat -A POSTROUTING -s 192.168.250.0/24 -o  $ETH  -j MASQUERADE" >> /etc/init.d/vpnserver
echo "service dhcpd restart"  >> /etc/init.d/vpnserver
echo "service dnsmasq restart" >> /etc/init.d/vpnserver
echo ";;" >> /etc/init.d/vpnserver
echo "stop)" >> /etc/init.d/vpnserver
echo "iptables -t nat -D POSTROUTING -s 192.168.250.0/24 -o $ETH  -j MASQUERADE" >> /etc/init.d/vpnserver
echo "$DAEMON stop"  >> /etc/init.d/vpnserver
echo "rm $LOCK" >> /etc/init.d/vpnserver
echo ";;" >> /etc/init.d/vpnserver
echo "restart)" >> /etc/init.d/vpnserver
echo "iptables -t nat -D POSTROUTING -s 192.168.250.0/24 -o $ETH  -j MASQUERADE" >> /etc/init.d/vpnserver
echo "$DAEMON stop"  >> /etc/init.d/vpnserver
echo "sleep 3"  >> /etc/init.d/vpnserver
echo "$DAEMON start"  >> /etc/init.d/vpnserver
echo "sleep 1"  >> /etc/init.d/vpnserver
echo "/sbin/ifconfig tap_soft $TAP_ADDR" >> /etc/init.d/vpnserver
echo "iptables -t nat -A POSTROUTING -s 192.168.250.0/24 -o  $ETH  -j MASQUERADE" >> /etc/init.d/vpnserver
echo "service dhcpd restart"  >> /etc/init.d/vpnserver
echo "service dnsmasq restart" >> /etc/init.d/vpnserver
echo ";;"  >> /etc/init.d/vpnserver
echo "*)"  >> /etc/init.d/vpnserver
echo 'echo "Usage: $0 {start|stop|restart}"'  >> /etc/init.d/vpnserver
echo "exit 1" >> /etc/init.d/vpnserver
echo "esac" >> /etc/init.d/vpnserver
echo "exit 0" >> /etc/init.d/vpnserver
echo ""  >> /etc/init.d/vpnserver

chmod 755 /etc/init.d/vpnserver

sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/ipv4_forwarding.conf 
sysctl --system

iptables -t nat -A POSTROUTING -s 192.168.250.0/24 -j SNAT --to-source $MYIP
# apt-get install iptables-persistent
iptables-save
 
# debian 7.8 fix, /var/lock link to /run/lock, but it seem deleted on reboot
# create dir every reboot
# echo '@reboot root mkdir /var/lock/subsys' >> /etc/crontab
# unfortune this seem not fast enough
echo '@reboot root mkdir /var/lock/subsys' > /etc/cron.d/vpnserver
echo '@reboot root touch /var/lock/subsys/vpnserver' >> /etc/cron.d/vpnserver
echo '@reboot root /usr/local/vpnserver/vpnserver start' >> /etc/cron.d/vpnserver 


# mkdir /var/locked
mkdir /var/lock/subsys

# creating vpn_server.config
service vpnserver start
service vpnserver stop

# edit/disable port 443/1194
# nano /usr/local/vpnserver/vpn_server.config
sed -i 's/443/444/g' /usr/local/vpnserver/vpn_server.config
sed -i 's/1194/1195/g' /usr/local/vpnserver/vpn_server.config

if [ -f /etc/debian_version ]; then
    DISTRO=Debian
    # debian
	sysv-rc-conf vpnserver on
	# install dnsmasq
	apt-get install -y dhcp dnsmasq
	sysv-rc-conf dnsmasq on
	# startup fix debian 7.8 /usr/sbin/dnsmasq
	echo '@reboot root  /etc/init.d/dnsmasq start ' > /etc/cron.d/dnsmasq


elif [ -f /etc/redhat-release ]; then
    DISTRO="Red Hat"
    # centos
	# XXX or CentOS or Fedora
	chkconfig –add vpnserver 
	yum install dhcp dnsmasq -y
	
fi

cp /etc/dnsmasq.conf /etc/dnsmasq.conf.org
echo "interface=tap_soft" > /etc/dnsmasq.conf
echo "dhcp-range=tap_soft,192.168.250.10,192.168.250.100,12h" >> /etc/dnsmasq.conf
echo "dhcp-option=tap_soft,3,192.168.250.1" >> /etc/dnsmasq.conf

sed -i 's/DHCPDARGS=/#DHCPDARGS=/g' /etc/sysconfig/dhcpd
echo "DHCPDARGS=tap_soft" >> /etc/sysconfig/dhcpd

# wget -O /etc/dhcp/dhcpd.conf.add https://raw.githubusercontent.com/nauval2007/centos/master/dhcpd.conf
#
# DHCP Server Configuration file.
# see /usr/share/doc/dhcp*/dhcpd.conf.sample
# see ‘man 5 dhcpd.conf’
echo 'option domain-name “gigel.eu”;' > /etc/dhcp/dhcpd.conf.add
echo 'option domain-name-servers 192.168.250.1, 8.8.8.8;' >> /etc/dhcp/dhcpd.conf.add
echo '' >> /etc/dhcp/dhcpd.conf.add
echo 'default-lease-time 600;' >> /etc/dhcp/dhcpd.conf.add
echo 'max-lease-time 7200;' >> /etc/dhcp/dhcpd.conf.add
echo '' >> /etc/dhcp/dhcpd.conf.add
echo 'option ms-classless-static-routes code 249 = array of integer 8;' >> /etc/dhcp/dhcpd.conf.add
echo '#option rfc3442-classless-static-routes code 121 = array of integer 8;'  >> /etc/dhcp/dhcpd.conf.add
echo '' >> /etc/dhcp/dhcpd.conf.add
echo 'subnet 192.168.250.0 netmask 255.255.255.0 {' >> /etc/dhcp/dhcpd.conf.add
echo 'range 192.168.250.10 192.168.250.100;' >> /etc/dhcp/dhcpd.conf.add
echo ''
echo 'option ms-classless-static-routes 24, 172, 17, 18, 192, 168, 250,1;' >> /etc/dhcp/dhcpd.conf.add
echo '#route add 172.17.18.0/24 192.168.250.1 above line pushes this route to the client' >> /etc/dhcp/dhcpd.conf.add
echo '}' >> /etc/dhcp/dhcpd.conf.add

cat /etc/dhcp/dhcpd.conf >> /etc/dhcp/dhcpd.conf.add
mv /etc/dhcp/dhcpd.conf.add /etc/dhcp/dhcpd.conf

# centos 7
# revert firewalld to iptables
VERSION=`cat /etc/centos-release`
if [[ $VERSION == *"7"* ]]
then
	VERSION=[cat /etc/centos_release]
	yum install -y iptables-services
	systemctl mask firewalld
	systemctl enable iptables
	systemctl stop firewalld
	systemctl start iptables
fi

echo "-A INPUT -p udp -m udp --dport 53 -j ACCEPT" >> /etc/sysconfig/iptables
echo "-A INPUT -p tcp -m state --state NEW -m tcp --dport 53 -j ACCEPT" >> /etc/sysconfig/iptables
echo "-A INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT" >> /etc/sysconfig/iptables




echo "Instalasi sukses!"
echo "Silahkan gunakan Softether Server Manager GUI untuk melanjutkan."
echo "Pastikan matikan secure nat dan udp vpn over dns service"
echo "Shien Ikiru (c) 2015"