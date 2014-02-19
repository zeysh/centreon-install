centreon-install
================

Centreon autoinstall for Debian (with centreon-engine)

Test on Debian Wheezy

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
