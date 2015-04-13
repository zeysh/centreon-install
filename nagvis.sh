#!/bin/bash
# MK Livestatus + Nagvis install script for Debian Wheezy
# Source https://github.com/zeysh/centreon-install
# Thanks to Eric http://eric.coquard.free.fr
#
export DEBIAN_FRONTEND=noninteractive
# Variables
## Versions
NAGVIS_VER="1.8.2"
MK_VER="1.2.6"
## Sources URL
NAGVIS_URL="http://www.nagvis.org/share/nagvis-${NAGVIS_VER}.tar.gz"
MK_URL="http://mathias-kettner.de/download/mk-livestatus-${MK_VER}.tar.gz"
## Temp install dir
DL_DIR="/usr/local/src"
## Install dir
INSTALL_DIR="/usr/local"
## Log install file
INSTALL_LOG="/usr/local/src/nagvis-install.log"
## Parameters
NAGVIS_DIR="/usr/local/nagvis"
DIR_APACHE_CONF="/etc/apache2/conf.d"
WEB_USER="www-data"
WEB_GROUP="www-data"

ETH0_IP=`/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`

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

function mk-livestatus_install() {
echo "
======================================================================

                        Install MK Livestatus

======================================================================
"

apt-get install -y build-essential

cd ${DL_DIR}
if [[ -e mk-livestatus-${MK_VER}.tar.gz ]] ;
  then
    echo 'File already exist !'
  else
    wget ${MK_URL} -O ${DL_DIR}/mk-livestatus-${MK_VER}.tar.gz
fi

tar xzf mk-livestatus-${MK_VER}.tar.gz
cd ${DL_DIR}/mk-livestatus-${MK_VER}

./configure
make

cp -f src/livestatus.o ${INSTALL_DIR}/centreon-engine/bin
cp -f src/unixcat ${INSTALL_DIR}/centreon-engine/bin

}

function nagvis_install () {
echo "
======================================================================

               Install Nagvis 

======================================================================
"

apt-get install -y php5-sqlite graphviz sqlite3

cd ${DL_DIR}
if [[ -e nagvis-${NAGVIS_VER}.tar.gz ]]
  then
    echo 'File already exist !'
  else
    wget ${NAGVIS_URL} -O ${DL_DIR}/nagvis-${NAGVIS_VER}.tar.gz
fi

tar xzf nagvis-${NAGVIS_VER}.tar.gz
cd ${DL_DIR}/nagvis-${NAGVIS_VER}

./install.sh -o -q -n ${INSTALL_DIR}/centreon-engine -p ${NAGVIS_DIR} -l "unix:/var/lib/centreon-engine/rw/live" -b mklivestatus -u ${WEB_USER} -g ${WEB_GROUP} -w ${DIR_APACHE_CONF} -a y -c y -F

# Update www-data user to allow access to /var/lib/centreon-engine/rw/live
usermod -G centreon-engine ${WEB_USER}

# rm -f ${NAGVIS_DIR}/etc/maps/demo*.cfg
# rm -f ${NAGVIS_DIR}/etc/conf.d/demo.ini.php

# Configure an automap
cat > ${NAGVIS_DIR}/etc/maps/automap.cfg << EOF
define global {
    sources=automap
    alias=Automap
    parent_map=demo-overview
    iconset=std_medium
    backend_id=live_1
    label_show=1
    label_border=transparent
    # Automap specific parameters
    render_mode=directed
    rankdir=TB
    width=500
    height=300
}
EOF

# Backup old configuration in case of upgrade
mv -f ${NAGVIS_DIR}/etc/nagvis.ini.php ${NAGVIS_DIR}/etc/nagvis.ini.php.`date +%Y-%m-%d-%H-%M-%S`
# Create a file specifig for Centreon
cat > ${NAGVIS_DIR}/etc/nagvis.ini.php << EOF
[global]
file_group="${WEB_USER}"
file_mode="660"
language="en_US"
[paths]
htmlcgi="/centreon/main.php"
[defaults]
contextmenu=1
contexttemplate="default"
event_on_load=0
event_repeat_interval=0
event_repeat_duration=-1
eventbackground=0
eventscroll=1
hovermenu=1
hovertemplate="default"
hoverdelay=0
hoverchildsshow=1
recognizeservices=1
showinlists=1
showinmultisite=1
hosturl="[htmlcgi]?p=20201&o=svc&host_search=[host_name]&search=&poller=&hostgroup=&output_search="
hostgroupurl=
serviceurl="[htmlcgi]?p=20201&o=svcd&host_name=[host_name]&service_description=[service_description]&poller=&hostgroup=&output_search="
servicegroupurl=
mapurl="[htmlcgi]?p=403&map=[map_name]"
view_template="default"
label_show=1
[index]
[automap]
[wui]
[worker]
[backend_live_1]
backendtype="mklivestatus"
socket="unix:/var/lib/centreon-engine/rw/live"
[states]
EOF
}

function post_install () {
echo "
=====================================================================

                          Post install

=====================================================================
"
# Fix permissions
chown -R ${WEB_USER}:${WEB_GROUP} ${NAGVIS_DIR}
chmod -R o-rwx ${NAGVIS_DIR}
# Restart Apache
service apache2 restart

}

function main () {
echo "
=======================| Install details |============================

                  MK Livestatus : ${MK_VER}
                  Nagvis        : ${NAGVIS_VER}
                  Nagvis dir    : ${NAGVIS_DIR}
                  Install dir   : ${INSTALL_DIR}
                  Source dir    : ${DL_DIR}

======================================================================
"
text_params

mk-livestatus_install > ${INSTALL_LOG} 2>&1
if [[ $? -ne 0 ]];
  then
    echo -e "${bold}Step1${normal}  => Install MK Livestatus                                 ${STATUS_FAIL}"
  else
    echo -e "${bold}Step1${normal}  => Install MK Livestatus                                 ${STATUS_OK}"
fi
nagvis_install >> ${INSTALL_LOG} 2>&1
if [[ $? -ne 0 ]];
  then
    echo -e "${bold}Step2${normal}  => Install Nagvis                                        ${STATUS_FAIL}"
  else
    echo -e "${bold}Step2${normal}  => Install Nagvis                                        ${STATUS_OK}"
fi
post_install >> ${INSTALL_LOG} 2>&1
if [[ $? -ne 0 ]];
  then
    echo -e "${bold}Step3${normal}  => Post install                                          ${STATUS_FAIL}"
  else
    echo -e "${bold}Step3${normal}  => Post install                                          ${STATUS_OK}"
fi
echo ""
echo "##### Install completed #####" >> ${INSTALL_LOG} 2>&1
}
# Exec main function
main
echo -e ""
echo -e "${bold}Go to http://${ETH0_IP}/centreon/ to complete the setup${normal} of MK Livestatus"
echo -e ""
echo -e "  Under : Configuration -> Monitoring Engines -> main.cfg -- Data Tab --"
echo -e "  In 'Broker Module', click on 'Add a new entry' and fill the 'Event broker directive' with :"
echo -e "  /usr/local/centreon-engine/bin/livestatus.o /var/lib/centreon-engine/rw/live"
echo -e "  Restart your Monitoring Engine."
echo -e ""
echo -e "${bold}Go to http://${ETH0_IP}/nagvis/ to see your new map${normal} in Nagvis"
echo -e ""
