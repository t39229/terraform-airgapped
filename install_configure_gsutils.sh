#!/bin/bash
  
# Setup gsutils and install gsutil
sudo apt-get install -y apt-transport-https ca-certificates gnupg

echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

sudo touch /var/lib/man-db/auto-update

sudo apt-get update && sudo apt-get install -y google-cloud-cli

gcloud init --console-only
