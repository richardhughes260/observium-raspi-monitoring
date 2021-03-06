#!/bin/bash -ex

#Check for root

LUID=$(id -u)
if [[ $LUID -ne 0 ]]; then
echo "$0 must be run as root"
exit 1
fi

#Include Defined Settings
. ./ConfigureMe.sh
#Install Function
install ()
{
	apt-get update
	DEBIAN_FRONTEND=noninteractive apt-get -y \
        -o DPkg::Options::=--force-confdef \
        -o DPkg::Options::=--force-confold \
        install $@
}

#Install snmpd
install snmpd

#Config /etc/default/snmpd
sed -i "s|SNMPDOPTS='-Lsd -Lf /dev/null -u snmp -g snmp -I -smux -p /var/run/snmpd.pid'|SNMPDOPTS='-Lsd -Lf /dev/null -u snmp -p /var/run/snmpd.pid'|" /etc/default/snmpd

cat > /etc/snmp/snmpd.conf <<EOF
com2sec readonly  default         $community
group MyROGroup v1         readonly
group MyROGroup v2c        readonly
group MyROGroup usm        readonly
view all    included  .1                               80
access MyROGroup ""      any       noauth    exact  all    none   none
syslocation $location
syscontact $contact
#This line allows Observium to detect the host OS if the distro script is installed
extend .1.3.6.1.4.1.2021.7890.1 distro /usr/bin/distro
EOF

#Get distro script for /usr/bin
#wget https://github.com/richardhughes260/observium-raspi-monitoring/distro
mv distro /usr/bin/distro
chmod 755 /usr/bin/distro

service snmpd restart
