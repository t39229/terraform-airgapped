#!/bin/bash

#Disable automatic updates
cat << EOF | sudo tee -a /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "0";
EOF

mkdir -p /mnt/irisplus-data
chmod 777 /mnt/irisplus-data

mkdir -p /agentvi_installs
chmod -R 777 /agentvi_installs

#Create user and sudo
useradd -m -s /bin/bash bastion && usermod -aG sudo bastion
echo "bastion:bastion" | chpasswd
sudo echo 'bastion  ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/00-no-pass-sudo && sudo chmod 0440 /etc/sudoers.d/00-no-pass-sudo


#Allow for password login
sed -i -E 's/#?PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd
