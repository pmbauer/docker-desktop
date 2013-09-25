# This file creates a container that runs X11 and SSH services
# The ssh is used to forward X11 and provide you encrypted data
# communication between the docker container and your local 
# machine.
#
# Xpra allows to display the programs running inside of the
# container such as Firefox, LibreOffice, xterm, etc. 
# with disconnection and reconnection capabilities
#
# Xephyr allows to display the programs running inside of the
# container such as Firefox, LibreOffice, xterm, etc. 
#
# Fluxbox and ROX-Filer creates a very minimalist way to 
# manages the windows and files.
#
# Author: Roberto Gandolfo Hashioka
# Date: 07/28/2013


FROM ubuntu:12.10
MAINTAINER Roberto G. Hashioka "roberto_hashioka@hotmail.com"

# Set the env variable DEBIAN_FRONTEND to noninteractive
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update

# Installing the environment required: xserver, xdm, flux box, roc-filer and ssh
RUN apt-get install -y xpra rox-filer ssh pwgen xserver-xephyr xdm fluxbox

# Configuring xdm to allow connections from any IP address and ssh to allow X11 Forwarding. 
RUN sed -i 's/DisplayManager.requestPort/!DisplayManager.requestPort/g' /etc/X11/xdm/xdm-config
RUN sed -i '/#any host/c\*' /etc/X11/xdm/Xaccess
RUN ln -s /usr/bin/Xorg /usr/bin/X
RUN echo X11Forwarding yes >> /etc/ssh/ssh_config

# Upstart and DBus have issues inside docker. We work around in order to install firefox.
RUN dpkg-divert --local --rename --add /sbin/initctl && ln -s /bin/true /sbin/initctl

# Installing fuse package (libreoffice-java dependency) and it's going to try to create
# a fuse device without success, due the container permissions. || : help us to ignore it. 
# Then we are going to delete the postinst fuse file and try to install it again!
# Thanks Jerome for helping me with this workaround solution! :)
# Now we are able to install the libreoffice-java package  
RUN apt-get -y install fuse  || :
RUN rm -rf /var/lib/dpkg/info/fuse.postinst
RUN apt-get -y install fuse

# Installing the apps: jdk and xterm
RUN apt-get install -y openjdk-7-jre icedtea-plugin xterm ubuntu-restricted-extras 

# Install FF18
RUN apt-get install -y curl 
RUN curl -o /opt/firefox.tar.bz2 https://ftp.mozilla.org/pub/mozilla.org/firefox/releases/18.0.2/linux-x86_64/en-US/firefox-18.0.2.tar.bz2
RUN tar -C /opt -xjf /opt/firefox.tar.bz2
RUN ln -sf /opt/firefox/firefox /usr/bin/firefox

# Adding updated xpra
RUN curl http://xpra.org/gpg.asc | apt-key add -
RUN echo "deb http://xpra.org/ quantal main" > /etc/apt/sources.list.d/xpra.list;
RUN apt-get update
RUN apt-get install -y xpra

# Set locale (fix the locale warnings)
RUN localedef -v -c -i en_US -f UTF-8 en_US.UTF-8 || :

# Copy the files into the container
ADD . /src

# make sure ff doesn't auto-update
RUN mkdir -p /opt/firefox/defaults/profile
RUN cp /src/prefs.js /opt/firefox/defaults/profile

EXPOSE 22
# Start xdm and ssh services.
CMD ["/bin/bash", "/src/startup.sh"]
