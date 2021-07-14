#!/bin/bash
###############################################################################
#Script Name    : script asterisk 18                       
#Description    : Building  pbx System               
#Author         : Mr.Kien    
################################################################################
# Disabling SeLinux for installation(Remains disabled untill reboot ar manual enable). 
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
#update timzone
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime

CHOICE=-1
function menu {
   echo ""
   echo -e "\e[2;32m    Option 1: Ensure all required packages are installed  \e[0m"
   echo -e "\e[2;33m    Option 2: In1stall Asterisk                           \e[0m"
   echo -e "\e[2;32m    Option 0: Exit without taking any actions             \e[0m"
   echo "" 
   echo -en "\e[2;33m  Selection: \e[0m"

   read CHOICE
}

function update {
# Updating packages
yum -y update

# Installing needed tools and packages
yum -y groupinstall core base "Development Tools"

#Installing additional required dependencies
yum -y install automake gcc gcc-c++ ncurses-devel openssl-devel libxml2-devel unixODBC-devel libcurl-devel libogg-devel libvorbis-devel speex-devel spandsp-devel freetds-devel net-snmp-devel iksemel-devel corosynclib-devel newt-devel popt-devel libtool-ltdl-devel lua-devel sqlite-devel radiusclient-ng-devel portaudio-devel neon-devel libical-devel openldap-devel gmime-devel mysql-devel bluez-libs-devel jack-audio-connection-kit-devel gsm-devel libedit-devel libuuid-devel jansson-devel libsrtp-devel git subversion libxslt-devel kernel-devel audiofile-devel gtk2-devel libtiff-devel libtermcap-devel ilbc-devel bison php php-mysql php-process php-pear php-mbstring php-xml php-gd tftp-server httpd sox tzdata mysql-connector-odbc mariadb mariadb-server fail2ban jwhois xmlstarlet ghostscript libtiff-tools python-devel patch

#Installing php 5.6 repositories
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

# Install php5.6w
yum remove php*
yum  install -y php56w php56w-pdo php56w-mysql php56w-mbstring php56w-pear php56w-process php56w-xml php56w-opcache php56w-ldap php56w-intl php56w-soap

# Enabling and starting MariaDB
systemctl enable mariadb.service
systemctl start mariadb

# MariaDB post install configuration
#mysql_secure_installation

echo -en "\e[2;32m                 Now you need reboot to take effect (y/n):\e[0m"
   read value
   echo ""
   case $value in
        y) reboot ;;
        yes) reboot ;;
        n) exit ;;
        no) exit ;;
        *) echo -e  "\e[2;320mINVALID OPTION\e[0m" ;;
   esac
   function reboot {
   	reboot -h now
   }

}

function install_asterisk {

# Compiling and Installing jansson
cd /usr/src
wget -O jansson.zip https://codeload.github.com/akheron/jansson/zip/master
unzip jansson.zip
rm -f jansson.zip
cd jansson-*
autoreconf -i
./configure --libdir=/usr/lib64
make
make install

#Compile and install DAHDI if needed

cd /usr/src
wget http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-2.10.2+2.10.2.tar.gz
tar zxvf dahdi-linux-complete-2.10*
cd /usr/src/dahdi-linux-complete-2.10*/
make all && make install && make config
systemctl restart dahdi 
echo -e "\e[32mDAHDI Install OK!\e[m"

#Compile and install Libpri if needed
cd /usr/src
wget http://downloads.asterisk.org/pub/telephony/libpri/libpri-current.tar.gz
tar xvfz libpri-current.tar.gz
cd /usr/src/libpri-*
make
make install
echo -e "\e[32mLibpri Install OK!\e[m"

# Create Asterisk usser for system
adduser asterisk -m -c "Asterisk User"

# Downloading Asterisk source files.
cd /usr/src
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-18-current.tar.gz

# Compiling and installing Asterisk
cd /usr/src
tar xvfz asterisk-18-current.tar.gz
rm -f asterisk-18-current.tar.gz
cd asterisk-*
contrib/scripts/install_prereq install
./configure --libdir=/usr/lib64 --with-pjproject-bundled
contrib/scripts/get_mp3_source.sh

# Making some configuration of installation options, modules, etc. After selecting 'Save & Exit' you can then continue
make menuselect

# Installation itself
make
make install
make samples
make config
ldconfig
systemctl start asterisk
systemctl enable asterisk

# Setting Asterisk ownership permissions.
chown asterisk. /var/run/asterisk
chown -R asterisk. /etc/asterisk
chown -R asterisk. /var/{lib,log,spool}/asterisk
chown -R asterisk. /usr/lib64/asterisk
chown -R asterisk. /var/www/
echo -e "\e[32m asterisk Install OK!\e[m"

# Alow porrt access asterisk
firewall-cmd --permanent --zone=public --add-port=5060-5061/tcp
firewall-cmd --permanent --zone=public --add-port=5060-5061/udp
firewall-cmd --permanent --zone=public --add-port=10000-20000/udp
firewall-cmd --reload
}

menu 

while [  $CHOICE -ne "0" ]; do
   case "$CHOICE" in
      "0")
         exit 0
         CHOICE=0;;
      "1")
         update
         CHOICE=0;;
	  "2")
	     install_asterisk
         CHOICE=0;;
	*)echo -e  "\e[2;330mYou have entered an invalid option...\e[0m"
         echo ""
         menu
	esac
done	
echo -e "\e[2;32m                  INSTALL SCUCESSFULLY ASTERISK                            \e[0m"
echo ""
echo -e "\e[2;32m ------------------------- MISSION COMPLETE! -----------------------------\e[0m"
echo ""
