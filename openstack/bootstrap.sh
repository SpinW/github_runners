#!/bin/bash

sudo dpkg --configure -a
sudo apt update && sudo apt -y upgrade
sudo apt install -y openssl libxt6 cifs-utils

sudo mkdir /mnt/apps
sudo mount -t cifs -o username=xxxx //sofwareserver/STFC_Software /mnt/apps
sudo mkdir /mnt/cdrom
sudo mount -o users /mnt/apps/Mathworks/R2020b/R2020b_Linux.iso /mnt/cdrom/

cat << EOF > /tmp/installer_input.txt
destinationFolder=/usr/local/MATLAB/R2020b
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

sudo ./install -inputFile /tmp/installer_input.txt
sudo ln -s /usr/local/MATLAB/R2020b/bin/matlab /usr/local/bin/
