#!/bin/bash

sudo apt update -y

cd $HOME && cd /tmp

wget https://github.com/prometheus/alertmanager/releases/download/v0.26.0/alertmanager-0.26.0.linux-amd64.tar.gz

tar xzf alertmanager-0.26.0.linux-amd64.tar.gz

sudo mv -v alertmanager-0.26.0.linux-amd64 /etc/alertmanager

sudo chown -Rfv root:root /etc/alertmanager

sudo mkdir -v /etc/alertmanager/data

sudo chown -Rfv prometheus:prometheus /etc/alertmanager/data

sudo tee /etc/systemd/system/alertmanager.service<<EOF
[Unit] 
Description=Alertmanager for prometheus

[Service] 
Restart=always 
User=prometheus 
ExecStart=/etc/alertmanager/alertmanager --config.file=/etc/alertmanager/alertmanager.yml --storage.path=/etc/alertmanager/data 
ExecReload=/bin/kill -HUP $MAINPID TimeoutStopSec=20s SendSIGKILL=no

[Install] 
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

sudo systemctl start alertmanager.service

sudo systemctl enable alertmanager.service

sudo systemctl status alertmanager.service