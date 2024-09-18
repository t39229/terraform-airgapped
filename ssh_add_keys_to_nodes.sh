hosts=( "air-gap-qa-renewed-troll-nfs" "air-gap-qa-renewed-troll-worker1" "air-gap-qa-renewed-troll-worker2" "air-gap-qa-renewed-troll-worker3" "air-gap-qa-renewed-troll-master1" "air-gap-qa-renewed-troll-master2" "air-gap-qa-renewed-troll-master3")
#For loop that scans keys, adds them to known hosts, copies the autorized key for remote host, remove password auth for sudo at remote host and blocks passwordauth
for i in "${hosts[@]}"
do
    ssh-keyscan $i  >> .ssh/known_hosts	
    sshpass -p "bastion" ssh-copy-id bastion@$i
    ssh bastion@$i 'sudo passwd -d bastion'
    ssh bastion@$i "sudo sed -i -E 's/#?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config"
    ssh bastion@$i 'sudo systemctl restart sshd'

done
