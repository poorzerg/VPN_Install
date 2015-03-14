#!/bin/bash

function installVPN(){
	echo "begin to install VPN services";
	#check wether vps suppot ppp and tun
	
	yum remove -y pptpd ppp
	iptables --flush POSTROUTING --table nat
	iptables --flush FORWARD
	rm -rf /etc/pptpd.conf
	rm -rf /etc/ppp
	
	arch=`uname -m`

	yum -y install make libpcap iptables gcc-c++ logrotate tar cpio perl pam tcp_wrappers ppp pptpd

	mknod /dev/ppp c 108 0 
	echo 1 > /proc/sys/net/ipv4/ip_forward 
	echo "mknod /dev/ppp c 108 0" >> /etc/rc.local
	echo "echo 1 > /proc/sys/net/ipv4/ip_forward" >> /etc/rc.local
	echo "localip 172.168.15.1" >> /etc/pptpd.conf
	echo "remoteip 172.168.15.2-254" >> /etc/pptpd.conf
	echo "ms-dns 8.8.8.8" >> /etc/ppp/options.pptpd
	echo "ms-dns 8.8.4.4" >> /etc/ppp/options.pptpd

	pass=`openssl rand 6 -base64`
	if [ "$1" != "" ]
	then pass=$1
	fi

	echo "vpn pptpd ${pass} *" >> /etc/ppp/chap-secrets

	iptables -t nat -A POSTROUTING -s 172.168.15.0/24 -j SNAT --to-source `ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk 'NR==1 { print $1}'`
	iptables -A FORWARD -p tcp --syn -s 172.168.15.0/24 -j TCPMSS --set-mss 1356
	service iptables save

	chkconfig iptables on
	chkconfig pptpd on

	service iptables start
	service pptpd start

	echo "VPN service is installed, your VPN username is vpn, VPN password is ${pass}"
	
}

function restartVPN(){
	echo "begin to restart VPN";
	mknod /dev/ppp c 108 0
	service iptables restart
	service pptpd restart
}

function addVPNuser(){
	echo "input user name:"
	read username
	echo "input password:"
	read userpassword
	echo "${username} pptpd ${userpassword} *" >> /etc/ppp/chap-secrets
	service iptables restart
	service pptpd start
}

echo "which do you want to?input the number."
echo "1. install VPN service"
echo "2. restart VPN service"
echo "3. add VPN user"
read num

case "$num" in
[1] ) (installVPN);;
[2] ) (restartVPN);;
[3] ) (addVPNuser);;
*) echo "nothing,exit";;
esac
