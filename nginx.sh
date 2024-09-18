#!/bin/bash
sudo apt install -y nginx
sudo ufw allow "Nginx HTTPS"

cat << EOF | sudo tee -a /etc/nginx/nginx.conf
load_module /usr/lib/nginx/modules/ngx_stream_module.so;
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
}

stream {
  upstream backend {
    server air-gap-qa-renewed-troll-master1:443;
  }

  log_format proxy '$remote_addr [$time_local] $protocol $upstream_addr $status';
  access_log  /var/log/nginx/access.log proxy;
  error_log /var/log/nginx/error.log error;

  server {
    listen 443;
    proxy_pass backend;
  }
}
EOF

sudo systemctl enable nginx
sudo systemctl start nginx
