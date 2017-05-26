FROM debian:jessie
MAINTAINER George Vieira <github@vieira.com.au>

# Debian
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -u upgrade
RUN apt-get install apache2 -y

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install vim ntp openssh-server openssh-client passwd ntpdate wget net-tools
RUN cp /usr/share/zoneinfo/Australia/Sydney /etc/localtime
RUN ntpdate -s pool.ntp.org

# SSH
#RUN ssh-keygen  -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key && ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key && sed -i "s/#UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config && sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config
RUN export TERM=linux
RUN wget -q https://raw.githubusercontent.com/GreenCom-Networks/centreon-install/master/centreon.sh -O /tmp/centreon.sh && \
        sed -i -e 's/snmp-mibs-downloader//g' /tmp/centreon.sh && \
        sed -i -e "s/CENTREON_VER='2.7.1'/CENTREON_VER='2.8.8'/g" /tmp/centreon.sh && \
        sed -i -e "s/BROKER_VER='2.11.0'/BROKER_VER='3.0.4'/g" /tmp/centreon.sh && \
        sed -i -e "s/ENGINE_VER='1.5.0'/ENGINE_VER='1.7.1'/g" /tmp/centreon.sh && \
        bash /tmp/centreon.sh

# SUPERVISORD
#RUN yum install -y python-pip && pip install "pip>=1.4,<1.5" --upgrade
#RUN pip install supervisor
#ADD supervisord.conf /etc/
EXPOSE 22 80
#CMD /etc/init.d/centengine start
#CMD /etc/init.d/cbd start
#CMD /etc/init.d/centcore start
#CMD /etc/init.d/apache start

ENTRYPOINT /etc/init.d/centengine start && /etc/init.d/cbd start && /etc/init.d/centcore start && /etc/init.d/apache2 start && /etc/init.d/mysql start && bash
