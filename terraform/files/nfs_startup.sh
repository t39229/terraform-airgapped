#!/bin/bash

#Disable automatic updates
cat << EOF | sudo tee -a /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "0";
EOF

#Create user
useradd -m -s /bin/bash bastion && usermod -aG sudo bastion
echo "bastion:bastion" | chpasswd
sudo echo 'bastion  ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/00-no-pass-sudo && sudo chmod 0440 /etc/sudoers.d/00-no-pass-sudo

#Allow for password login
sed -i -E 's/#?PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

# Install NFS Server
yum install -y nfs-utils
systemctl start nfs-server rpcbind
systemctl enable nfs-server rpcbind

# Create NFS Share
mkdir /irisplus-data
chmod 777 /irisplus-data
echo "/irisplus-data 12.10.10.0/24(rw,sync,no_root_squash)" > /etc/exports
exportfs -r

# Configure Firewall
firewall-cmd --permanent --add-service mountd
firewall-cmd --permanent --add-service rpc-bind
firewall-cmd --permanent --add-service nfs
firewall-cmd --reload
