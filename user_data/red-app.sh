#!/bin/bash
sudo yum update -y
sudo yum install -y nodejs npm git
cd /home/ec2-user
git clone --branch alb-red --single-branch https://github.com/leonardobgsilva/app-leocinema-lite.git 
sudo chown -R ec2-user:ec2-user /home/ec2-user/app-leocinema-lite
cd app-leocinema-lite
sudo npm install

sudo bash -c 'cat <<EOF > /etc/systemd/system/leocinema-lite.service
[Unit]
Description=Leo Cinema Lite
After=network.target

[Service]
ExecStart=/usr/bin/node server.js
WorkingDirectory=/home/ec2-user/app-leocinema-lite
Restart=always
User=root
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl daemon-reload
sudo systemctl enable leocinema-lite
sudo systemctl start leocinema-lite