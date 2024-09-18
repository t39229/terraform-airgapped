#!/bin/bash

#Disable automatic updates
cat << EOF | sudo tee -a /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "0";
EOF

# Download nfs-common
apt-get update
apt-get install --downloadonly -y nfs-common
apt-get install ansible -y
apt-get install wget -y
apt-get install sshpass -y

# Install Ansible collections
ansible-galaxy collection install ansible.posix

# Create user, ssh key and sudo
useradd -m -s /bin/bash bastion && usermod bastion -aG sudo
sudo echo 'bastion  ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/00-no-pass-sudo
sudo chmod 0440 /etc/sudoers.d/00-no-pass-sudo
passwd -d bastion
sudo -u bastion bash -c "ssh-keygen -f ~/.ssh/id_rsa -N ''"
sudo -u bastion bash -c "chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_rsa && chmod 644 ~/.ssh/id_rsa.pub"
sudo -u bastion bash -c "mkdir ~/config"
sudo -u bastion bash -c "cp /etc/ansible/ansible.cfg config/ansible.cfg"

# Add public key to authorized keys.
sudo -u bastion bash -c "echo 'ssh-rsa ..........................................................................'

#If you want to add your public key copy and edit:
#sudo -u bastion bash -c "echo '<your_public_key>' >> ~/.ssh/authorizes_keys"
#Then connect to bastion vm with "ssh bastion@<ip>"


# Disable password login for ssh
sed -i -E 's/#?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd


