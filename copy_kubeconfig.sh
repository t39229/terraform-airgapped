#!/bin/bash
master=air-gap-qa-renewed-troll-master1
worker=air-gap-qa-renewed-troll-worker1
ssh $master "sudo cp /etc/rancher/k3s/k3s.yaml /home/bastion/k3s.yaml"
ssh $master "sudo chown bastion:bastion /home/bastion/k3s.yaml"
scp $master:~/k3s.yaml .
sed -i -E "s/([0-9]{1,3}[\.]){3}[0-9]{1,3}/$master/g" ~/k3s.yaml
scp ~/k3s.yaml $worker:~/.
ssh $worker "sudo mv ~/k3s.yaml /etc/rancher/k3s/k3s.yaml"
