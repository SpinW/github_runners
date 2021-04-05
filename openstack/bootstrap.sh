#!/bin/bash

echo "*** Waiting for updates to finish ***"
START=$(date +%s)
#sudo kill -9 $(sudo lsof /var/lib/dpkg/lock-frontend | awk '{print $2}' | tail -n1)
while true
do
  if [[ $(sudo lsof /var/lib/dpkg/lock-frontend) == "" ]]
  then
    break
  fi
  sleep 10
done
STOP=$(date +%s)
echo "*** Done in $((STOP-START))s ***"

dpkg --configure -a
apt-get update
apt-get install -y openssl libxt6 cifs-utils curl sudo git jq
# For Ubuntu 18.04
apt-get install -y libicu60
apt-get clean
rm -rf /var/lib/apt/lists/*

MATLAB_VER=R2020b

mkdir /mnt/apps
mount -t cifs -o "username=xxxx,password=xxxx" //sofwareserver/STFC_Software /mnt/apps
mkdir /mnt/cdrom
mount -o users,exec /mnt/apps/Mathworks/${MATLAB_VER}/${MATLAB_VER}_Linux.iso /mnt/cdrom/

cat << EOF > /tmp/installer_input.txt
destinationFolder=/usr/local/MATLAB/${MATLAB_VER}
fileInstallationKey=xxxx
agreeToLicense=yes
outputFile=/tmp/mathworks_vagrant.log
licensePath=/tmp/network.lic
product.MATLAB
EOF
cat << EOF > /tmp/network.lic
SERVER abc.de <KEY> 27000
USE_SERVER
EOF

echo "*** Installing Matlab ***"
cd /mnt/cdrom
./install -inputFile /tmp/installer_input.txt
ln -s /usr/local/MATLAB/R2020b/bin/matlab /usr/local/bin/

echo "*** Installing Github runners ***"
useradd -m github
echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
cd /home/github/ || exit
mkdir work
curl -Ls https://github.com/actions/runner/releases/download/v2.277.1/actions-runner-linux-x64-2.277.1.tar.gz | tar xz \
    && sudo ./bin/installdependencies.sh

echo "*** Setting up vagrant user ***"
# https://github.com/govcloud/packer-linux/blob/master/scripts/vagrant.sh
USERNAME=vagrant
USERHOME=/home/$USERNAME
groupadd $USERNAME
useradd $USERNAME -g $USERNAME -G sudo
echo -e "${USERNAME}\n${USERNAME}" | passwd $USERNAME
echo "${USERNAME}        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
mkdir -pm 700 ${USERHOME}/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ==" > $USERHOME/.ssh/authorized_keys
chmod 0600 ${USERHOME}/.ssh/authorized_keys
chown -R ${USERNAME}:${USERNAME} ${USERHOME}/.ssh
