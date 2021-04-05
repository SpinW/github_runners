#!/bin/bash

# You need to have OS_USERNAME and OS_PASSWORD set before running this

ssh-keygen -t rsa -f tmpkey -N ""
openstack keypair create --public-key tmpkey.pub temp_install_key

vagrant up
openstack server image create --name matlab_linux runner_installation
vagrant destroy -f

rm -f tmpkey tmpkey.pub
openstack keypair delete temp_install_key
