#!/bin/bash
# Centreon + engine install script for Debian Wheezy
# Source https://github.com/zeysh/centreon-install
# Thanks to Eric http://eric.coquard.free.fr
#

# Variables
## Versions
CLIB_VER="1.2.0"
CONNECTOR_VER="1.0.2"
ENGINE_VER="1.3.7"
PLUGIN_VER="2.0.3"
BROKER_VER="2.6.2"
CENTREON_VER="2.5.1"
CLAPI_VER="1.5.2"
# MariaDB Series
MARIADB_VER='5.5'
## Sources URL
CLIB_URL="http://download.centreon.com/index.php?id=4299"
CONNECTOR_URL="http://download.centreon.com/index.php?id=4305"
ENGINE_URL="http://download.centreon.com/index.php?id=4310"
PLUGIN_URL="http://www.nagios-plugins.org/download/nagios-plugins-${PLUGIN_VER}.tar.gz"
BROKER_URL="http://download.centreon.com/index.php?id=4315"
CENTREON_URL="http://download.centreon.com/index.php?id=4314"
CLAPI_URL="http://download.centreon.com/index.php?id=4296"
## Temp install dir
DL_DIR="/tmp"
## Install dir
INSTALL_DIR="/srv"
## Set mysql-server root password
MYSQL_PASSWORD="password"
## Users and groups
ENGINE_USER="centreon-engine"
ENGINE_GROUP="centreon-engine"
BROKER_USER="centreon-broker"
BROKER_GROUP="centreon-broker"
CENTREON_USER="centreon"
CENTREON_GROUP="centreon"
## TMPL file (template install file for Centreon)
CENTREON_TMPL="centreon_engine.tmpl"

# BEGIN
echo "
======================| Install details |=============================

                Clib       : ${CLIB_VER}
                Connector  : ${CONNECTOR_VER}
                Engine     : ${ENGINE_VER}
                Plugin     : ${PLUGIN_VER}
                Broker     : ${BROKER_VER}
                Centreon   : ${CENTREON_VER}
                Install dir: ${INSTALL_DIR}
                Source dir : ${DL_DIR}

=====================================================================
 "

echo "
==========================| Step 1 |=================================

        Add Squeeze repo for php 5.3 on Wheezy
        At the moment Centreon doesn't support PHP 5.4

=====================================================================
"

echo 'deb http://ftp.fr.debian.org/debian/ squeeze main non-free
deb-src http://ftp.fr.debian.org/debian/ squeeze main non-free

deb http://security.debian.org/ squeeze/updates main non-free
deb-src http://security.debian.org/ squeeze/updates main non-free' > /etc/apt/sources.list.d/squeeze.list

# Fix version PHP5.3 on Wheezy
echo 'Package: php5*
Pin: release a=oldstable
Pin-Priority: 700

Package: libapache2-mod-php5
Pin: release a=oldstable
Pin-Priority: 700

Package: php-pear
Pin: release a=oldstable
Pin-Priority: 700

Package: *
Pin: release a=stable
Pin-Priority: 600' > /etc/apt/preferences.d/preferences

apt-get update

echo "
==========================| Step 2 |=================================

                        Install Clib

=====================================================================
"

apt-get install -y build-essential cmake

cd ${DL_DIR}
if [[ -e centreon-clib-${CLIB_VER}.tar.gz ]] ;
  then 
    echo 'File already exist !'
  else 
    wget ${CLIB_URL} -O ${DL_DIR}/centreon-clib-${CLIB_VER}.tar.gz
fi

tar xzf centreon-clib-${CLIB_VER}.tar.gz
cd centreon-clib-${CLIB_VER}/build

cmake \
   -DWITH_TESTING=0 \
   -DWITH_PREFIX=${INSTALL_DIR}/centreon-lib \
   -DWITH_SHARED_LIB=1 \
   -DWITH_STATIC_LIB=0 \
   -DWITH_PKGCONFIG_DIR=/usr/lib/pkgconfig .
make 
make install

echo "${INSTALL_DIR}/centreon-lib/lib" >> /etc/ld.so.conf.d/libc.conf

echo "
==========================| Step 3 |=================================

                Install Centreon Perl Connector

=====================================================================
"

apt-get install -y libperl-dev

cd ${DL_DIR}
if [[ -e centreon-connector-${CONNECTOR_VER}.tar.gz ]]
  then 
    echo 'File already exist !'
  else 
    wget ${CONNECTOR_URL} -O ${DL_DIR}/centreon-connector-${CONNECTOR_VER}.tar.gz
fi

tar xzf centreon-connector-${CONNECTOR_VER}.tar.gz
cd ${DL_DIR}/centreon-connector-${CONNECTOR_VER}/perl/build

cmake \
 -DWITH_PREFIX=${INSTALL_DIR}/centreon-connector  \
 -DWITH_CENTREON_CLIB_INCLUDE_DIR=${INSTALL_DIR}/centreon-lib/include \
 -DWITH_CENTREON_CLIB_LIBRARIES=${INSTALL_DIR}/centreon-lib/lib/libcentreon_clib.so \
 -DWITH_TESTING=0 .
make
make install

# install Centreon SSH Connector
apt-get install -y libssh2-1-dev libgcrypt11-dev

# Cleanup to prevent space full on /var
apt-get clean

cd ${DL_DIR}/centreon-connector-${CONNECTOR_VER}/ssh/build

cmake \
 -DWITH_PREFIX=${INSTALL_DIR}/centreon-connector  \
 -DWITH_CENTREON_CLIB_INCLUDE_DIR=${INSTALL_DIR}/centreon-lib/include \
 -DWITH_CENTREON_CLIB_LIBRARIES=${INSTALL_DIR}/centreon-lib/lib/libcentreon_clib.so \
 -DWITH_TESTING=0 .
make
make install

echo "
==========================| Step 4 |=================================

                   Install Centreon Engine

=====================================================================
"

groupadd -g 6001 ${ENGINE_GROUP}
useradd -u 6001 -g ${ENGINE_GROUP} -m -r -d /var/lib/centreon-engine -c "Centreon-engine Admin" ${ENGINE_USER}

apt-get install -y libcgsi-gsoap-dev zlib1g-dev libssl-dev libxerces-c-dev

# Cleanup to prevent space full on /var
apt-get clean

cd ${DL_DIR}
if [[ -e centreon-engine-${ENGINE_VER}.tar.gz ]]
  then 
    echo 'File already exist !'
  else 
    wget ${ENGINE_URL} -O ${DL_DIR}/centreon-engine-${ENGINE_VER}.tar.gz
fi

tar xzf centreon-engine-${ENGINE_VER}.tar.gz
cd ${DL_DIR}/centreon-engine-${ENGINE_VER}/build

cmake \
   -DWITH_CENTREON_CLIB_INCLUDE_DIR=${INSTALL_DIR}/centreon-lib/include \
   -DWITH_CENTREON_CLIB_LIBRARY_DIR=${INSTALL_DIR}/centreon-lib/lib \
   -DWITH_PREFIX=${INSTALL_DIR}/centreon-engine \
   -DWITH_USER=${ENGINE_USER} \
   -DWITH_GROUP=${ENGINE_GROUP} \
   -DWITH_LOGROTATE_SCRIPT=1 \
   -DWITH_VAR_DIR=/var/log/centreon-engine \
   -DWITH_RW_DIR=/var/lib/centreon-engine/rw \
   -DWITH_STARTUP_DIR=/etc/init.d \
   -DWITH_PKGCONFIG_SCRIPT=1 \
   -DWITH_PKGCONFIG_DIR=/usr/lib/pkgconfig \
   -DWITH_TESTING=0 \
   -DWITH_WEBSERVICE=1 .
make
make install

chmod +x /etc/init.d/centengine
update-rc.d centengine defaults

echo "
==========================| Step 5 |=================================

                    Install Plugins Nagios

=====================================================================
"

apt-get install -y libgnutls-dev libssl-dev libkrb5-dev libldap2-dev libsnmp-dev gawk \
        libwrap0-dev libmcrypt-dev smbclient fping gettext dnsutils libmysqlclient-dev \
        libnet-snmp-perl

# Cleanup to prevent space full on /var
apt-get clean

cd ${DL_DIR}
if [[ -e nagios-plugins-${PLUGIN_VER}.tar.gz ]]
  then 
    echo 'File already exist !'
  else 
    wget ${PLUGIN_URL} -O ${DL_DIR}/nagios-plugins-${PLUGIN_VER}.tar.gz
fi

tar xzf nagios-plugins-${PLUGIN_VER}.tar.gz
cd ${DL_DIR}/nagios-plugins-${PLUGIN_VER}

./configure --with-nagios-user=${ENGINE_USER} --with-nagios-group=${ENGINE_GROUP} \
--prefix=${INSTALL_DIR}/centreon-plugins --enable-perl-modules --with-openssl=/usr/bin/openssl \
--enable-extra-opts

make 
make install

echo "
==========================| Step 6 |=================================

                   Install Centreon Broker

=====================================================================
"

groupadd -g 6002 ${BROKER_GROUP}
useradd -u 6002 -g ${BROKER_GROUP} -m -r -d /var/lib/centreon-broker -c "Centreon-broker Admin" ${BROKER_USER}
usermod -aG ${BROKER_USER} ${ENGINE_GROUP}

apt-get install -y librrd-dev libqt4-dev libqt4-sql-mysql

# Cleanup to prevent space full on /var
apt-get clean

cd ${DL_DIR}
if [[ -e centreon-broker-2.5.0.tar.gz ]]
  then 
    echo 'File already exist !'
  else
    wget ${BROKER_URL} -O ${DL_DIR}/centreon-broker-${BROKER_VER}.tar.gz
fi

if [[ -d /var/log/centreon-broker ]]
  then
    echo "Directory already exist!"
  else
    mkdir /var/log/centreon-broker
    chown ${BROKER_USER}:${ENGINE_GROUP} /var/log/centreon-broker
    chmod 775 /var/log/centreon-broker
fi

tar xzf centreon-broker-${BROKER_VER}.tar.gz
cd ${DL_DIR}/centreon-broker-${BROKER_VER}/build/

cmake \
    -DWITH_DAEMONS='central-broker;central-rrd' \
    -DWITH_GROUP=${BROKER_GROUP} \
    -DWITH_PREFIX=${INSTALL_DIR}/centreon-broker \
    -DWITH_STARTUP_DIR=/etc/init.d \
    -DWITH_STARTUP_SCRIPT=auto \
    -DWITH_TESTING=0 \
    -DWITH_USER=${BROKER_USER} .
make
make install
update-rc.d cbd defaults

# Cleanup to prevent space full on /var
apt-get clean

echo "
==========================| Step 7 |=================================

                Install Centreon Web Interface

=====================================================================
"

echo "mysql-server-5.5 mysql-server/root_password password ${MYSQL_PASSWORD}
      mysql-server-5.5 mysql-server/root_password seen true
      mysql-server-5.5 mysql-server/root_password_again password ${MYSQL_PASSWORD}
      mysql-server-5.5 mysql-server/root_password_again seen true" | debconf-set-selections

DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes bsd-mailx mysql-server \
 apache2 php5-mysql rrdtool librrds-perl tofrodos php5 php-pear php5-ldap php5-snmp \
 php5-gd libconfig-inifiles-perl libcrypt-des-perl libdigest-hmac-perl libgd-gd2-perl \
 snmp snmpd snmp-mibs-downloader sudo

# Cleanup to prevent space full on /var
apt-get clean


# MIBS errors
if [[ -d /root/mibs_removed ]]
  then 
    echo 'MIBS already moved !'
  else
    mkdir /root/mibs_removed
        mv /usr/share/mibs/ietf/IPATM-IPMC-MIB /root/mibs_removed
        mv /usr/share/mibs/ietf/SNMPv2-PDU /root/mibs_removed
        mv /usr/share/mibs/ietf/IPSEC-SPD-MIB /root/mibs_removed
        mv /usr/share/mibs/iana/IANA-IPPM-METRICS-REGISTRY-MIB /root/mibs_removed
fi

cd ${DL_DIR}

if [[ -e centreon-${CENTREON_VER}.tar.gz ]]
  then 
    echo 'File already exist!'
  else
    wget ${CENTREON_URL} -O ${DL_DIR}/centreon-${CENTREON_VER}.tar.gz
fi

groupadd -g 6003 ${CENTREON_GROUP}
useradd -u 6003 -g ${CENTREON_GROUP} -m -r -d ${INSTALL_DIR}/centreon -c "Centreon Web user" ${CENTREON_USER}

tar xzf centreon-${CENTREON_VER}.tar.gz
cd ${DL_DIR}/centreon-${CENTREON_VER}

./install.sh -i -f /${DL_DIR}/${CENTREON_TMPL}

# Add mysql config for Centreon
echo '[mysqld]
innodb_file_per_table=1' > /etc/mysql/conf.d/innodb.cnf

service mysql restart

## Workarounds
## config:  cannot open '/var/lib/centreon-broker/module-temporary.tmp-1-central-module-output-master-failover'
## (mode w+): Permission denied)
chmod 775 /var/lib/centreon-broker/

## drwxr-xr-x 3 root root 15 Feb  4 20:31 centreon-engine
chown ${ENGINE_USER}:${ENGINE_GROUP} /var/lib/centreon-engine/
