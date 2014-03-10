centreon-install
================

Centreon autoinstall for Debian (with centreon-engine)

Test on Debian Wheezy

# Default install
1. Version and URLs

- CLIB_VER="1.2.0"
- CONNECTOR_VER="1.0.2"
- ENGINE_VER="1.3.7"
- PLUGIN_VER="1.5"
- BROKER_VER="2.6.1"
- CENTREON_VER="2.5.0"
- CLIB_URL="http://download.centreon.com/index.php?id=4299"
- CONNECTOR_URL="http://download.centreon.com/index.php?id=4305"
- ENGINE_URL="http://download.centreon.com/index.php?id=4310"
- PLUGIN_URL="http://assets.nagios.com/downloads/nagiosplugins/nagios-plugins-${PLUGIN_VER}.tar.gz"
- BROKER_URL="http://download.centreon.com/index.php?id=4309"
- CENTREON_URL="http://download.centreon.com/index.php?id=4307"

2. Temp and install directories
- DL_DIR="/tmp"
- INSTALL_DIR="/srv"

3. Users, groups and passwords
- MYSQL_PASSWORD="password"
- ENGINE_USER="centreon-engine"
- ENGINE_GROUP="centreon-engine"
- BROKER_USER="centreon-broker"
- BROKER_GROUP="centreon-broker"
- CENTREON_USER="centreon"
- CENTREON_GROUP="centreon"

4. Centreon template install file
- CENTREON_TMPL="centreon_engine.tmpl"

# Usage

1. Change your vars at the beginning of the script
2. Copy the template file centreon_engine.tmpl to /tmp
3. sudo ./centreon.sh
4. http://localhost/centreon/ 
5. Enjoy!

# Complete the web install

        Monitoring engine                        => centreon-engine
        Centreon Engine directory                => /srv/centreon-engine
        Centreon Engine Stats binary             => /srv/centreon-engine/bin/centenginestats
        Centreon Engine var lib directory        => /var/lib/centreon-engine
        Centreon Engine Connector path           => /srv/centreon-connector
        Centreon Engine Library (*.so) directory => /srv/centreon-engine/lib/centreon-engine/
        Embedded Perl initialisation file        => 

# Broker Module Information

        Broker Module                            => centreon-broker
        Centreon Broker etc directory            => /srv/centreon-broker/etc
        Centreon Broker module (cbmod.so)        => /srv/centreon-broker/lib/cbmod.so
        Centreon Broker log directory            => /var/log/centreon-broker/
        Retention file directory                 => /var/lib/centreon-broker
        Centreon Broker lib (*.so) directory     => /srv/centreon-broker/lib/centreon-broker/

# Restart cbd
        service cbd restart
