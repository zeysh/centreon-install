#!/bin/bash
# Centreon + engine install script for Debian Wheezy and Jessie
# Source https://github.com/zeysh/centreon-install and https://github.com/GreenCom-Networks/centreon-install
# Thanks to Eric http://eric.coquard.free.fr
#
export DEBIAN_FRONTEND=noninteractive
# Variables
## Versions
CLIB_VER='1.4.2'
CONNECTOR_VER='1.1.2'
ENGINE_VER='1.7.0'
PLUGIN_VER='2.1.1'
BROKER_VER='3.0.3'
CENTREON_VER='2.8.4'
CLAPI_VER='1.8.0'
NAGVIS_MOD_VER='1.1.1'
# MariaDB Series
MARIADB_VER='10.1'
## Sources URL
BASE_URL='https://s3-eu-west-1.amazonaws.com/centreon-download/public'
CLIB_URL="${BASE_URL}/centreon-clib/centreon-clib-${CLIB_VER}.tar.gz"
CONNECTOR_URL="${BASE_URL}/centreon-connectors/centreon-connector-${CONNECTOR_VER}.tar.gz"
ENGINE_URL="${BASE_URL}/centreon-engine/centreon-engine-${ENGINE_VER}.tar.gz"
PLUGIN_URL="http://www.nagios-plugins.org/download/nagios-plugins-${PLUGIN_VER}.tar.gz"
BROKER_URL="${BASE_URL}/centreon-broker/centreon-broker-${BROKER_VER}.tar.gz"
CENTREON_URL="${BASE_URL}/centreon/centreon-web-${CENTREON_VER}.tar.gz"
CLAPI_URL="${BASE_URL}/Modules/CLAPI/centreon-clapi-${CLAPI_VER}.tar.gz"
NAGVIS_MOD_URL="${BASE_URL}/Modules/centreon-nagvis/centreon-nagvis-${NAGVIS_MOD_VER}.tar.gz"
## Sources widgets
WIDGET_HOST_VER='1.4.0'
WIDGET_HOSTGROUP_VER='1.3.0'
WIDGET_SERVICE_VER='1.4.0'
WIDGET_SERVICEGROUP_VER='1.3.0'
WIDGET_GRAPH_VER='1.3.0'
WIDGET_TOP10_CPU_VER='1.0.0'
WIDGET_TOP10_MEM_VER='1.0.0'
WIDGET_ENGINE_STATUS_VER='1.0.0'
WIDGET_GRID_MAP_VER='1.0.0'
WIDGET_HTTP_LOADER_VER='1.0.0'
WIDGET_TACTICAL_OVERVIEW_VER='1.0.0'
WIDGET_BASE='https://s3-eu-west-1.amazonaws.com/centreon-download/public/centreon-widgets'
WIDGET_HOST="${WIDGET_BASE}/centreon-widget-host-monitoring/centreon-widget-host-monitoring-${WIDGET_HOST_VER}.tar.gz"
WIDGET_HOSTGROUP="${WIDGET_BASE}/centreon-widget-hostgroup-monitoring/centreon-widget-hostgroup-monitoring-${WIDGET_HOSTGROUP_VER}.tar.gz"
WIDGET_SERVICE="${WIDGET_BASE}/centreon-widget-service-monitoring/centreon-widget-service-monitoring-${WIDGET_SERVICE_VER}.tar.gz"
WIDGET_SERVICEGROUP="${WIDGET_BASE}/centreon-widget-servicegroup-monitoring/centreon-widget-servicegroup-monitoring-${WIDGET_SERVICEGROUP_VER}.tar.gz"
WIDGET_GRAPH="${WIDGET_BASE}/centreon-widget-graph-monitoring/centreon-widget-graph-monitoring-${WIDGET_GRAPH_VER}.tar.gz"
WIDGET_TOP10_CPU="${WIDGET_BASE}/centreon-widget-live-top10-cpu-usage/centreon-widget-live-top10-cpu-usage-${WIDGET_TOP10_CPU_VER}.tar.gz"
WIDGET_TOP10_MEM="${WIDGET_BASE}/centreon-widget-live-top10-memory/centreon-widget-live-top10-memory-${WIDGET_TOP10_MEM_VER}.tar.gz"
WIDGET_ENGINE_STATUS="${WIDGET_BASE}/centreon-widget-engine-status/centreon-widget-engine-status-${WIDGET_ENGINE_STATUS_VER}.tar.gz"
WIDGET_GRID_MAP="${WIDGET_BASE}/centreon-widget-grid-map/centreon-widget-grid-map-${WIDGET_GRID_MAP_VER}.tar.gz"
WIDGET_HTTP_LOADER="${WIDGET_BASE}/centreon-widget-httploader/centreon-widget-httploader-${WIDGET_HTTP_LOADER_VER}.tar.gz"
WIDGET_TACTICAL_OVERVIEW="${WIDGET_BASE}/centreon-widget-tactical-overview/centreon-widget-tactical-overview-${WIDGET_TACTICAL_OVERVIEW_VER}.tar.gz"
## Temp install dir
DL_DIR='/usr/local/src'
## Install dir
INSTALL_DIR='/usr/local'
## Log install file
INSTALL_LOG='/usr/local/src/centreon-install.log'
## Set mysql-server root password
MYSQL_PASSWORD=${MYSQL_PASSWORD:-YOUR_PASSWORD}
## Users and groups
ENGINE_USER='centreon-engine'
ENGINE_GROUP='centreon-engine'
BROKER_USER='centreon-broker'
BROKER_GROUP='centreon-broker'
CENTREON_USER='centreon'
CENTREON_GROUP='centreon'
## TMPL files (template install files for Centreon)
CENTREON_ENGINE_TMPL='centreon_engine.tmpl'
CENTREON_BROKER_TMPL='centreon_broker.tmpl'
CENTREON_WEB_TMPL='centreon_web.tpl'

ETH0_IP=`/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`

# Set some variables to support Debian 7 and 8
case `cat /etc/debian_version` in
    7\.[0-9] )
        DEBVERS='wheezy'
        echo 'Debian Wheezy'
        gnutlsdev='libgnutls-dev'
        dir_apache_conf='/etc/apache2/conf.d'
    ;;

    8\.[0-9] )
        DEBVERS='jessie'
        echo 'Debian Jessie'
        gnutlsdev='libgnutls28-dev'
        dir_apache_conf='/etc/apache2/conf-available'
    ;;
esac

function text_params () {
  ESC_SEQ="\x1b["
  bold=`tput bold`
  normal=`tput sgr0`
  COL_RESET=$ESC_SEQ"39;49;00m"
  COL_GREEN=$ESC_SEQ"32;01m"
  COL_RED=$ESC_SEQ"31;01m"
  STATUS_FAIL="[$COL_RED${bold}FAIL${normal}$COL_RESET]"
  STATUS_OK="[$COL_GREEN${bold} OK ${normal}$COL_RESET]"
}

function php_install () {
echo '
======================================================================

                  Install PHP, pear and apache

======================================================================
'
DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes bsd-mailx \
 apache2 php5-mysql rrdtool librrds-perl tofrodos php5 php-pear php5-ldap php5-snmp \
 php5-gd libconfig-inifiles-perl libcrypt-des-perl libdigest-hmac-perl libgd-gd2-perl \
 snmp snmpd sudo libdigest-sha-perl php5-sqlite php5-intl
DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes snmp-mibs-downloader
# Cleanup to prevent space full on /var
apt-get clean

/usr/bin/pear update-channels
/usr/bin/pear upgrade-all
wget -nv --no-check-certificate https://de.pear.php.net/get/XML_RPC-1.5.5.tgz -O ${DL_DIR}/XML_RPC-1.5.5.tgz
cd ${DL_DIR}
/usr/bin/pear install XML_RPC-1.5.5.tgz
/usr/bin/pear install Archive_Tar Archive_Zip-beta Auth_SASL Console_Getopt DB DB_DataObject DB_DataObject_FormBuilder Date HTML_Common HTML_QuickForm HTTP_Request Log MDB2 Net_Ping Net_SMTP Net_Socket Net_Traceroute-alpha Net_URL SOAP-beta Structures_Graph Validate-beta
/usr/bin/pear upgrade-all
cd -
sed -i 's/;date.timezone =/date.timezone = Europe\/Paris/' /etc/php5/apache2/php.ini

}

function mariadb_install() {
echo '
======================================================================

                        Install MariaDB

======================================================================
'
apt-get install -y lsb-release python-software-properties
DISTRO=`lsb_release -i -s | tr '[:upper:]' '[:lower:]'`
RELEASE=`lsb_release -c -s`


MIRROR_DOMAIN='ftp.igh.cnrs.fr'
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db
echo "deb http://${MIRROR_DOMAIN}/pub/mariadb/repo/${MARIADB_VER}/${DISTRO} ${RELEASE} main" > /etc/apt/sources.list.d/mariadb.list
apt-get update

# Pin repository in order to avoid conflicts with MySQL from distribution
# repository. See https://mariadb.com/kb/en/installing-mariadb-deb-files
# section "Version Mismatch Between MariaDB and Ubuntu/Debian Repositories"
echo "
Package: *
Pin: origin ${MIRROR_DOMAIN}
Pin-Priority: 1000
" | tee /etc/apt/preferences.d/mariadb

debconf-set-selections <<< "mariadb-server-${MARIADB_VER} mysql-server/root_password password ${MYSQL_PASSWORD}"
debconf-set-selections <<< "mariadb-server-${MARIADB_VER} mysql-server/root_password_again password ${MYSQL_PASSWORD}"
apt-get install --force-yes -y mariadb-server
apt-get upgrade --force-yes -y
}

function clib_install () {
echo '
======================================================================

                          Install Clib

======================================================================
'

apt-get install -y build-essential cmake

cd ${DL_DIR}
if [[ -e centreon-clib-${CLIB_VER}.tar.gz ]] ;
  then
    echo 'File already exists !'
  else
    wget -nv ${CLIB_URL} -O ${DL_DIR}/centreon-clib-${CLIB_VER}.tar.gz
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
}

function centreon_connectors_install () {
echo '
======================================================================

               Install Centreon Perl and SSH connectors

======================================================================
'

apt-get install -y libperl-dev

cd ${DL_DIR}
if [[ -e centreon-connector-${CONNECTOR_VER}.tar.gz ]]
  then
    echo 'File already exists !'
  else
    wget -nv ${CONNECTOR_URL} -O ${DL_DIR}/centreon-connector-${CONNECTOR_VER}.tar.gz
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
}

function centreon_engine_install () {
echo '
======================================================================

                    Install Centreon Engine

======================================================================
'

groupadd -g 6001 ${ENGINE_GROUP}
useradd -u 6001 -g ${ENGINE_GROUP} -m -r -d /var/lib/centreon-engine -c "Centreon-engine Admin" ${ENGINE_USER}

apt-get install -y libcgsi-gsoap-dev zlib1g-dev libssl-dev libxerces-c-dev libsnmp-perl

# Cleanup to prevent space full on /var
apt-get clean

cd ${DL_DIR}
if [[ -e centreon-engine-${ENGINE_VER}.tar.gz ]]
  then
    echo 'File already exists !'
  else
    wget -nv ${ENGINE_URL} -O ${DL_DIR}/centreon-engine-${ENGINE_VER}.tar.gz
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
}

function nagios_plugin_install () {
echo '
======================================================================

                     Install Plugins Nagios

======================================================================
'

apt-get install --force-yes -y $gnutlsdev libssl-dev libkrb5-dev libldap2-dev libsnmp-dev gawk \
        libwrap0-dev libmcrypt-dev smbclient fping gettext dnsutils libmariadbclient-dev \
        libnet-snmp-perl

# Cleanup to prevent space full on /var
apt-get clean

cd ${DL_DIR}
if [[ -e nagios-plugins-${PLUGIN_VER}.tar.gz ]]
  then
    echo 'File already exists !'
  else
    wget -nv ${PLUGIN_URL} -O ${DL_DIR}/nagios-plugins-${PLUGIN_VER}.tar.gz
fi

tar xzf nagios-plugins-${PLUGIN_VER}.tar.gz
cd ${DL_DIR}/nagios-plugins-${PLUGIN_VER}

./configure --with-nagios-user=${ENGINE_USER} --with-nagios-group=${ENGINE_GROUP} \
--prefix=${INSTALL_DIR}/centreon-plugins --enable-perl-modules --with-openssl=/usr/bin/openssl \
--enable-extra-opts

make
make install
}

function centreon_broker_install() {
echo '
======================================================================

                     Install Centreon Broker

======================================================================
'

groupadd -g 6002 ${BROKER_GROUP}
useradd -u 6002 -g ${BROKER_GROUP} -m -r -d /var/lib/centreon-broker -c "Centreon-broker Admin" ${BROKER_USER}
usermod -aG ${BROKER_GROUP} ${ENGINE_USER}

apt-get install -y librrd-dev libqt4-dev libqt4-sql-mysql

# Cleanup to prevent space full on /var
apt-get clean

cd ${DL_DIR}
if [[ -e centreon-broker-${BROKER_VER}.tar.gz ]]
  then 
    echo 'File already exists !'
  else
    wget -nv ${BROKER_URL} -O ${DL_DIR}/centreon-broker-${BROKER_VER}.tar.gz
fi

if [[ -d /var/log/centreon-broker ]]
  then
    echo 'Directory already exists !'
  else
    mkdir /var/log/centreon-broker
    chown ${BROKER_USER}:${ENGINE_GROUP} /var/log/centreon-broker
    chmod 775 /var/log/centreon-broker
fi
if [[ -d /usr/local/centreon-broker/var ]]; then
    mkdir /usr/local/centreon-broker/var
    chown ${BROKER_USER}:${ENGINE_GROUP} /usr/local/centreon-broker/var
    chmod 775 /usr/local/centreon-broker/var
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
}

function create_centreon_tmpl() {
echo '
======================================================================

                  Centreon templates generation

======================================================================
'
cat > ${DL_DIR}/${CENTREON_ENGINE_TMPL} << EOF
# column 1 => name of macro
# column 2 => label of macro
# column 3 => 0:optional, 1: required
# column 4 => 0:directory, 1: file, 2: other
# column 5 => default value
INSTALL_DIR_ENGINE;Centreon Engine directory;1;0;${INSTALL_DIR}/centreon-engine
CENTREON_ENGINE_STATS_BINARY;Centreon Engine Stats binary;1;1;${INSTALL_DIR}/centreon-engine/bin/centenginestats
MONITORING_VAR_LIB;Centreon Engine var lib directory;1;0;/var/lib/centreon-engine
CENTREON_ENGINE_CONNECTORS;Centreon Engine Connector path;0;0;${INSTALL_DIR}/centreon-connector
CENTREON_ENGINE_LIB;Centreon Engine Library (*.so) directory;1;0;${INSTALL_DIR}/centreon-engine/lib/centreon-engine
EMBEDDED_PERL;Embedded Perl initialisation file;0;1;
EOF

cat > ${DL_DIR}/${CENTREON_BROKER_TMPL} << EOF
# column 1 => name of macro
# column 2 => label of macro
# column 3 => 0:optional, 1: required
# column 4 => 0:directory, 1: file
# column 5 => default value
CENTREONBROKER_ETC;Centreon Broker etc directory;1;0;${INSTALL_DIR}/centreon-broker/etc
CENTREONBROKER_CBMOD;Centreon Broker module (cbmod.so);0;1;${INSTALL_DIR}/centreon-broker/lib/cbmod.so
CENTREONBROKER_LOG;Centreon Broker log directory;1;0;/var/log/centreon-broker
CENTREONBROKER_VARLIB;Retention file directory;1;0;/var/lib/centreon-broker
CENTREONBROKER_LIB;Centreon Broker lib (*.so) directory;1;0;${INSTALL_DIR}/centreon-broker/lib/centreon-broker
EOF

cat > ${DL_DIR}/${CENTREON_WEB_TMPL} << EOF
# Centreon Web template
PROCESS_CENTREON_WWW=1
PROCESS_CENTSTORAGE=1
PROCESS_CENTCORE=1
PROCESS_CENTREON_PLUGINS=1
PROCESS_CENTREON_SNMP_TRAPS=1

LOG_DIR="$BASE_DIR/log"
LOG_FILE="$LOG_DIR/install_centreon.log"
TMPDIR='/tmp/centreon-setup'
SNMP_ETC='/etc/snmp/'
PEAR_MODULES_LIST='pear.lst'
PEAR_AUTOINST=1

INSTALL_DIR_CENTREON="${INSTALL_DIR}/centreon"
CENTREON_BINDIR="${INSTALL_DIR}/centreon/bin"
CENTREON_DATADIR="${INSTALL_DIR}/centreon/data"
CENTREON_USER=${CENTREON_USER}
CENTREON_GROUP=${CENTREON_GROUP}
PLUGIN_DIR="${INSTALL_DIR}/centreon-plugins/libexec"
CENTREON_PLUGINS="${INSTALL_DIR}/centreon-plugins/libexec"
CENTREON_LOG='/var/log/centreon'
CENTREON_ETC="/etc/centreon"
CENTREON_RUNDIR='/var/run/centreon'
CENTREON_GENDIR='/var/cache/centreon'
CENTSTORAGE_RRD='/var/lib/centreon'
CENTSTORAGE_BINDIR="${INSTALL_DIR}/centreon/bin"
CENTCORE_BINDIR="${INSTALL_DIR}/centreon/bin"
CENTREON_VARLIB='/var/lib/centreon'
CENTPLUGINS_TMP='/var/lib/centreon/centplugins'
CENTPLUGINSTRAPS_BINDIR="${INSTALL_DIR}/centreon/bin"
SNMPTT_BINDIR="${INSTALL_DIR}/centreon/bin"
CENTCORE_INSTALL_INIT=1
CENTCORE_INSTALL_RUNLVL=1
CENTSTORAGE_INSTALL_INIT=0
CENTSTORAGE_INSTALL_RUNLVL=0
CENTREONTRAPD_BINDIR="${INSTALL_DIR}/centreon/bin"
CENTREONTRAPD_INSTALL_INIT=1
CENTREONTRAPD_INSTALL_RUNLVL=1

INSTALL_DIR_NAGIOS="${INSTALL_DIR}/centreon-engine"
CENTREON_ENGINE_USER="${ENGINE_USER}"
MONITORINGENGINE_USER="${CENTREON_USER}"
MONITORINGENGINE_LOG='/var/log/centreon-engine'
MONITORINGENGINE_INIT_SCRIPT='/etc/init.d/centengine'
MONITORINGENGINE_BINARY="${INSTALL_DIR}/centreon-engine/bin/centengine"
MONITORINGENGINE_ETC="${INSTALL_DIR}/centreon-engine/etc"
NAGIOS_PLUGIN="${INSTALL_DIR}/centreon-plugins/libexec"
FORCE_NAGIOS_USER=1
NAGIOS_GROUP="${CENTREON_USER}"
FORCE_NAGIOS_GROUP=1
NDOMOD_BINARY="${INSTALL_DIR}/centreon-broker/bin/cbd"
NDO2DB_BINARY="${INSTALL_DIR}/centreon-broker/bin/cbd"
NAGIOS_INIT_SCRIPT='/etc/init.d/centengine'
CENTREON_ENGINE_CONNECTORS="${INSTALL_DIR}/centreon-connector"
BROKER_USER="${BROKER_USER}"
BROKER_ETC="${INSTALL_DIR}/centreon-broker/etc"
BROKER_INIT_SCRIPT='/etc/init.d/cbd'
BROKER_LOG='/var/log/centreon-broker'

DIR_APACHE='/etc/apache2'
DIR_APACHE_CONF="${dir_apache_conf}"
APACHE_CONF='apache.conf'
WEB_USER="www-data"
WEB_GROUP="www-data"
APACHE_RELOAD=1
BIN_RRDTOOL='/usr/bin/rrdtool'
BIN_MAIL='/usr/bin/mail'
BIN_SSH='/usr/bin/ssh'
BIN_SCP='/usr/bin/scp'
PHP_BIN='/usr/bin/php'
GREP='/bin/grep'
CAT='/bin/cat'
SED='/bin/sed'
CHMOD='/bin/chmod'
CHOWN='/bin/chown'

RRD_PERL='/usr/lib/perl5'
SUDO_FILE='/etc/sudoers'
FORCE_SUDO_CONF=1
INIT_D='/etc/init.d'
CRON_D='/etc/cron.d'
PEAR_PATH='/usr/share/php'
EOF
}

function centreon_install () {
echo '
======================================================================

                  Install Centreon Web Interface

======================================================================
'
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

if [[ -e centreon-web-${CENTREON_VER}.tar.gz ]]
  then
    echo 'File already exists !'
  else
    wget -nv ${CENTREON_URL} -O ${DL_DIR}/centreon-web-${CENTREON_VER}.tar.gz
fi

groupadd -g 6003 ${CENTREON_GROUP}
useradd -u 6003 -g ${CENTREON_GROUP} -m -r -d ${INSTALL_DIR}/centreon -c "Centreon Web user" ${CENTREON_USER}
usermod -aG ${CENTREON_GROUP} ${ENGINE_USER}

tar xzf centreon-web-${CENTREON_VER}.tar.gz
cd ${DL_DIR}/centreon-web-${CENTREON_VER}
# Workaround for Install generateSqlLite FAIL
mkdir -p ${INSTALL_DIR}/centreon/bin/
cp ${DL_DIR}/centreon-web-${CENTREON_VER}/bin/generateSqlLite ${INSTALL_DIR}/centreon/bin/
chmod 755 ${INSTALL_DIR}/centreon/bin/generateSqlLite

echo ' Generate Centreon templates '

cp ${DL_DIR}/${CENTREON_ENGINE_TMPL} ${DL_DIR}/centreon-web-${CENTREON_VER}/www/install/var/engines/centreon-engine
cp ${DL_DIR}/${CENTREON_BROKER_TMPL} ${DL_DIR}/centreon-web-${CENTREON_VER}/www/install/var/brokers/centreon-broker
./install.sh -i -f ${DL_DIR}/${CENTREON_WEB_TMPL}
}

function post_install () {
echo '
=====================================================================

                          Post install

=====================================================================
'
if [ $install_db -eq 0 ]; then
    # Add mysql config for Centreon
    echo '[mysqld]
    innodb_file_per_table=1' > /etc/mysql/conf.d/innodb.cnf
    echo '[mysqld]
    open_files_limit=32000' > /etc/mysql/conf.d/open_files_limit.cnf

    mkdir -p /etc/systemd/system/mysql.service.d/
    echo -e "[Service]\nLimitNOFILE=infinity" > /etc/systemd/system/mysql.service.d/limits.conf
    systemctl daemon-reload

    service mysql restart
fi
service cbd restart
service centcore restart
service centengine restart
service centreontrapd restart

# Workarounds for apache2 on Debian 8
if [ "$DEBVERS" == "jessie" ]
then

    cat > $dir_apache_conf/centreon.conf << EOF
##
## Section add by Centreon Install Setup <modified by script>
##

Alias /centreon $INSTALL_DIR/centreon/www/
<Directory "$INSTALL_DIR/centreon/www">
    Options Indexes
    AllowOverride AuthConfig Options
    Require all granted
</Directory>
EOF
# Enable centreon conf and restart apache
/usr/sbin/a2enconf centreon
/bin/systemctl restart apache2.service
fi

## Workarounds
## config:  cannot open '/var/lib/centreon-broker/module-temporary.tmp-1-central-module-output-master-failover'
## (mode w+): Permission denied)
chmod 775 /var/lib/centreon-broker/

## drwxr-xr-x 3 root root 15 Feb  4 20:31 centreon-engine
chown ${ENGINE_USER}:${ENGINE_GROUP} /var/lib/centreon-engine/

}

##ADDONS

function clapi_install () {
echo '
=======================================================================

                          Install CLAPI

=======================================================================
'
cd ${DL_DIR}
  if [[ -e ${DL_DIR}/centreon-clapi-${CLAPI_VER}.tar.gz ]]
    then
      echo 'File already exists !'
    else
      wget -nv ${CLAPI_URL} -O ${DL_DIR}/centreon-clapi-${CLAPI_VER}.tar.gz
      tar xzf ${DL_DIR}/centreon-clapi-${CLAPI_VER}.tar.gz
  fi
    cd ${DL_DIR}/centreon-clapi-${CLAPI_VER}
    ./install.sh -u `grep CENTREON_ETC ${DL_DIR}/${CENTREON_WEB_TMPL} | cut -d '=' -f2 | tr -d \"`
}

function widget_install() {
echo '
=======================================================================

                         Install WIDGETS and NAGVIS

=======================================================================
'
cd ${DL_DIR}
  wget -nv -qO- ${WIDGET_HOST} | tar -C ${INSTALL_DIR}/centreon/www/widgets --strip-components 1 -xzv
  wget -nv -qO- ${WIDGET_HOSTGROUP} | tar -C ${INSTALL_DIR}/centreon/www/widgets --strip-components 1 -xzv
  wget -nv -qO- ${WIDGET_SERVICE} | tar -C ${INSTALL_DIR}/centreon/www/widgets --strip-components 1 -xzv
  wget -nv -qO- ${WIDGET_SERVICEGROUP} | tar -C ${INSTALL_DIR}/centreon/www/widgets --strip-components 1 -xzv
  wget -nv -qO- ${WIDGET_GRAPH} | tar -C ${INSTALL_DIR}/centreon/www/widgets --strip-components 1 -xzv
  
  wget -nv -qO- ${WIDGET_TOP10_CPU} | tar -C ${INSTALL_DIR}/centreon/www/widgets --strip-components 1 -xzv
  wget -nv -qO- ${WIDGET_TOP10_MEM} | tar -C ${INSTALL_DIR}/centreon/www/widgets --strip-components 1 -xzv
  wget -nv -qO- ${WIDGET_ENGINE_STATUS} | tar -C ${INSTALL_DIR}/centreon/www/widgets --strip-components 1 -xzv
  wget -nv -qO- ${WIDGET_GRID_MAP} | tar -C ${INSTALL_DIR}/centreon/www/widgets --strip-components 1 -xzv
  wget -nv -qO- ${WIDGET_HTTP_LOADER} | tar -C ${INSTALL_DIR}/centreon/www/widgets --strip-components 1 -xzv
  wget -nv -qO- ${WIDGET_TACTICAL_OVERVIEW} | tar -C ${INSTALL_DIR}/centreon/www/widgets --strip-components 1 -xzv
  chown -R $CENTREON_USER:$CENTREON_GROUP ${INSTALL_DIR}/centreon/www/widgets
  
  wget -nv -qO- ${NAGVIS_MOD_URL} | tar -C ${INSTALL_DIR}/centreon/www/modules centreon-nagvis-${NAGVIS_MOD_VER}/www --strip-components 3 -xzv
  # Added to fix a bug in nagvis module
  cat >> ${INSTALL_DIR}/centreon/www/modules/centreon-nagvis/sql/install.sql << 'EOF'
INSERT INTO `options` (`key`, `value`) VALUES ('centreon_nagvis_auth', 'single');
INSERT INTO `options` (`key`, `value`) VALUES ('centreon_nagvis_single_user', 'centreon_nagvis');
EOF
  chown -R `grep WEB_USER ${DL_DIR}/${CENTREON_WEB_TMPL} | cut -d '=' -f2 | tr -d \"`:`grep WEB_GROUP ${DL_DIR}/${CENTREON_WEB_TMPL} | cut -d '=' -f2 | tr -d \"` ${INSTALL_DIR}/centreon/www/modules/centreon-nagvis
}

function centreon_plugins_install() {
echo '
=======================================================================

                    Install Centreon Plugins

=======================================================================
'
cd ${DL_DIR}
DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes libcache-memcached-perl libjson-perl libxml-libxml-perl libdatetime-perl git-core
git clone https://github.com/centreon/centreon-plugins.git
cd centreon-plugins
chmod +x centreon_plugins.pl
chown -R ${ENGINE_USER}:${ENGINE_GROUP} ${DL_DIR}/centreon-plugins
cp -R * ${INSTALL_DIR}/centreon-plugins/libexec/
}





function main () {
echo "
=======================| Install details |============================

                  MariaDB    : ${MARIADB_VER}
                  Clib       : ${CLIB_VER}
                  Connector  : ${CONNECTOR_VER}
                  Engine     : ${ENGINE_VER}
                  Plugin     : ${PLUGIN_VER}
                  Broker     : ${BROKER_VER}
                  Centreon   : ${CENTREON_VER}
                  Install dir: ${INSTALL_DIR}
                  Source dir : ${DL_DIR}

======================================================================
"

if [ $install_web -eq 0 ]; then
    php_install > ${INSTALL_LOG} 2>&1
    if [[ $? -ne 0 ]];
      then
        echo -e "${bold}Step1${normal}  => Install PHP, PEAR                                     ${STATUS_FAIL}"
      else
        echo -e "${bold}Step1${normal}  => Install PHP, PEAR                                     ${STATUS_OK}"
    fi
fi
if [ $install_db -eq 0 ]; then
	mariadb_install > ${INSTALL_LOG} 2>&1
	if [[ $? -ne 0 ]];
	  then
	    echo -e "${bold}Step2${normal}  => Install MariaDB                                       ${STATUS_FAIL}"
	  else
	    echo -e "${bold}Step2${normal}  => Install MariaDB                                       ${STATUS_OK}"
	fi
fi
if [ $install_engine -eq 0 ]; then
    clib_install >> ${INSTALL_LOG} 2>&1
    if [[ $? -ne 0 ]];
      then
        echo -e "${bold}Step3${normal}  => Clib install                                          ${STATUS_FAIL}"
      else
        echo -e "${bold}Step3${normal}  => Clib install                                          ${STATUS_OK}"
    fi
    centreon_connectors_install >> ${INSTALL_LOG} 2>&1
    if [[ $? -ne 0 ]];
      then
        echo -e "${bold}Step4${normal}  => Centreon Perl and SSH connectors install              ${STATUS_FAIL}"
      else
        echo -e "${bold}Step4${normal}  => Centreon Perl and SSH connectors install              ${STATUS_OK}"
    fi
    centreon_engine_install >> ${INSTALL_LOG} 2>&1
    if [[ $? -ne 0 ]];
      then
        echo -e "${bold}Step5${normal}  => Centreon Engine install                               ${STATUS_FAIL}"
      else
        echo -e "${bold}Step5${normal}  => Centreon Engine install                               ${STATUS_OK}"
    fi
    nagios_plugin_install >> ${INSTALL_LOG} 2>&1
    if [[ $? -ne 0 ]];
      then
        echo -e "${bold}Step6${normal}  => Nagios plugins install                                ${STATUS_FAIL}"
      else
        echo -e "${bold}Step6${normal}  => Nagios plugins install                                ${STATUS_OK}"
    fi
    centreon_plugins_install >> ${INSTALL_LOG} 2>&1
    if [[ $? -ne 0 ]];
      then
        echo -e "${bold}Step6${normal}  => Centreon plugins install                              ${STATUS_FAIL}"
      else
        echo -e "${bold}Step6${normal}  => Centreon plugins install                              ${STATUS_OK}"
    fi
    centreon_broker_install >> ${INSTALL_LOG} 2>&1
    if [[ $? -ne 0 ]];
      then
        echo -e "${bold}Step7${normal}  => Centreon Broker install                               ${STATUS_FAIL}"
      else
        echo -e "${bold}Step7${normal}  => Centreon Broker install                               ${STATUS_OK}"
    fi
fi
if [ $install_web -eq 0 ]; then
    create_centreon_tmpl >> ${INSTALL_LOG} 2>&1
    if [[ $? -ne 0 ]];
      then
        echo -e "${bold}Step8${normal}  => Centreon template generation                          ${STATUS_FAIL}"
      else
        echo -e "${bold}Step8${normal}  => Centreon template generation                          ${STATUS_OK}"
    fi
    centreon_install >> ${INSTALL_LOG} 2>&1
    if [[ $? -ne 0 ]];
      then
        echo -e "${bold}Step9${normal}  => Centreon web interface install                        ${STATUS_FAIL}"
      else
        echo -e "${bold}Step9${normal}  => Centreon web interface install                        ${STATUS_OK}"
    fi
    post_install >> ${INSTALL_LOG} 2>&1
    if [[ $? -ne 0 ]];
      then
        echo -e "${bold}Step10${normal} => Post install                                          ${STATUS_FAIL}"
      else
        echo -e "${bold}Step10${normal} => Post install                                          ${STATUS_OK}"
    fi
    widget_install >> ${INSTALL_LOG} 2>&1
    if [[ $? -ne 0 ]];
      then
        echo -e "${bold}Step12${normal} => Widgets and Nagvis install                            ${STATUS_FAIL}"
      else
        echo -e "${bold}Step12${normal} => Widgets and Nagvis install                            ${STATUS_OK}"
    fi
    echo ""
fi
echo "##### Install completed #####" >> ${INSTALL_LOG} 2>&1
}

function usage() {
    echo "Usage:"
    echo "  -r|--role  {roletype}  Specific role installation"
    echo "              roletype="
    echo "                  central          # web, core, engine, db"
    echo "                  central-nodb     # web, engine"
    echo "                  remote-db        # db"
    echo "                  poller           # engine"
    echo "                  poller-ui        # web, engine, db"
    exit 1
}

text_params
# Command Line Options
while getopt -o r:h --long role:,help; do
    case "$1" in
        -r|--role)
            role=$2
            case $2 in
                'central')
                    install_web=0; install_core=0; install_engine=0; install_db=0; shift 2; break
                    ;;
                'central-nodb')
                    install_web=0; install_core=0; install_engine=0; install_db=1; shift 2; break
                    ;;
                'remote-db')
                    install_web=1; install_core=1; install_engine=1; install_db=0; shift 2; break
                    ;;
                'poller')
                    install_web=1; install_core=1; install_engine=0; install_db=1; shift 2; break
                    ;;
                'poller-ui')
                    install_web=0; install_core=1; install_engine=0; install_db=0; shift 2; break
                    ;;
                *)
                    echo "Unknown role '$role'"
                    exit 1
                    ;;
            esac
            ;;
        -h|--help)
            usage
            exit 1
            ;;
        --) shift ; break ;;
        "") usage ; break ;;

        *)
            echo "Unknown option '$1'"
            exit 1
            ;;
    esac
done

# Prerequisite checks
[ "$MYSQL_PASSWORD" = "YOUR_PASSWORD" ] && echo -e "${COL_RED}Error${COL_RESET}: MYSQL_PASSWORD not set!\n\nRun \`export MYSQL_PASSWORD='YOUR_PASSWORD'\` and then rerun the centreon.sh" && exit 1

# Exec main function
main
echo -e ''
if [ $install_web -eq 0 ]; then
    echo -e "${bold}Go to http://${ETH0_IP}/centreon to complete the setup${normal} "
else
    echo -e "${bold}Installation Completed.${normal}"
fi
echo -e ''
