#!/bin/sh -e

#
# This script will configure the raspberry pi for first time use. Edit the
# configuration settings below and then paste the contents of this file into
# /etc/rc.local on your Raspbian SD card.
#

# change these to settings to match your desired configuration
CONFIG_PI_HOSTNAME=raspberrypi
CONFIG_PI_PASSWORD=raspberry
CONFIG_WIRELESS_SSID=HACKATHON
CONFIG_WIRELESS_PASSWORD=gehacker
CONFIG_WIRELESS_SECURITY=WPA-PSK
CONFIG_APPLICATION_NAME=hackathon-2014-02
CONFIG_APPLICATION_PATH=git+https://github.com/GEMakers/$CONFIG_APPLICATION_NAME.git

# make sure we are in the right directory
cd /home/pi

# set the password for the 'pi' user
echo "pi:$CONFIG_PI_PASSWORD" | sudo /usr/sbin/chpasswd

# setup wpa supplicant to connect to the wireless network
echo "network={" > setup.tmp
echo "    ssid=\"$CONFIG_WIRELESS_SSID\"" >> setup.tmp
echo "    psk=\"$CONFIG_WIRELESS_PASSWORD\"" >> setup.tmp
echo "    key_mgmt=$CONFIG_WIRELESS_SECURITY" >> setup.tmp
echo "    scan_ssid=1" >> setup.tmp
echo "    priority=5" >> setup.tmp
echo "}" >> setup.tmp
sudo cp setup.tmp /etc/wpa_supplicant/wpa_supplicant.conf
rm setup.tmp

# change the hostname in /etc/hosts
echo "127.0.0.1	localhost" > setup.tmp
echo "::1		localhost ip6-localhost ip6-loopback" >> setup.tmp
echo "fe00::0		ip6-localnet" >> setup.tmp
echo "ff00::0		ip6-mcastprefix" >> setup.tmp
echo "ff02::1		ip6-allnodes" >> setup.tmp
echo "ff02::2		ip6-allrouters" >> setup.tmp
echo "" >> setup.tmp
echo "127.0.1.1	$CONFIG_PI_HOSTNAME" >> setup.tmp
sudo cp setup.tmp /etc/hosts
rm setup.tmp

# change the hostname in /etc/hostname
echo "$CONFIG_PI_HOSTNAME" > setup.tmp
sudo cp setup.tmp /etc/hostname
rm setup.tmp

# commit the hostname changes to the kernel
sudo /etc/init.d/hostname.sh

# install the packages needed for MDNS and USB communication
sudo /usr/bin/apt-get -y install avahi-daemon libudev-dev libusb-1.0-0-dev

# download node.js for the raspberry pi
/usr/bin/wget http://nodejs.org/dist/v0.10.2/node-v0.10.2-linux-arm-pi.tar.gz

# extract the tarball
tar xzf node-v0.10.2-linux-arm-pi.tar.gz

# make the node.js directory
sudo mkdir /opt/node

# copy all of the files to the directory
sudo cp -r node-v0.10.2-linux-arm-pi/* /opt/node

# cleanup the artifacts
rm -rf node-v0.10.2-linux-arm-pi.tar.gz node-v0.10.2-linux-arm-pi

# add the node.js binaries directory to the path variable (logout required)
sudo sed -i '/export PATH/i PATH="$PATH:/opt/node/bin"' /etc/profile

# install the application as the user 'pi' using the node.js package manager
sudo -u pi /opt/node/bin/npm install $CONFIG_APPLICATION_PATH

# run the node.js application on startup
echo "#!/bin/sh" > setup.tmp
echo "cd /home/pi/node_modules/$CONFIG_APPLICATION_NAME" >> setup.tmp
echo "(sleep 10; /opt/node/bin/node index.js; /sbin/reboot) &" >> setup.tmp
echo "exit 0" >> setup.tmp
sudo cp setup.tmp /etc/rc.local
rm setup.tmp

# reboot the system for the changes to take effect
sudo /sbin/reboot

# this script must return with success
exit 0
