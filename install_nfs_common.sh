#!/bin/bash
hosts=( "air-gap-qa-renewed-troll-worker1" "air-gap-qa-renewed-troll-worker2" "air-gap-qa-renewed-troll-worker3" "air-gap-qa-renewed-troll-master1" "air-gap-qa-renewed-troll-master2" "air-gap-qa-renewed-troll-master3" )

sudo apt-get install --download-only -y nfs-common

for i in "${hosts[@]}"
do
    scp -r /var/cache/apt/archives $i:~/
    ssh $i "sudo mv archives/* /var/cache/apt/archives/"
    ssh $i "sudo apt-get install nfs-common -y"
    ssh $i "sudo mkdir -p /mnt/irisplus-data"
    ssh $i "sudo mount air-gap-qa-renewed-troll-nfs:/irisplus-data /mnt/irisplus-data"
    ssh $i "cat << EOF | sudo tee -a /etc/fstab
air-gap-qa-renewed-troll-nfs:/irisplus-data /mnt/irisplus-data nfs default 0 0
EOF"    
done
