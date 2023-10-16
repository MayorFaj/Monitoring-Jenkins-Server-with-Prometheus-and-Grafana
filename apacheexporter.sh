#!/bin/bash

sudo apt update -y && sudo apt install jq wget curl -y apache2 > /dev/null 2>&1

#Input system distribution
echo "Enter the system distribution (e.g., linux-amd64, darwin-amd64, etc):"
read sys_dist

# Fetch release information

latest_release_info=$(curl -s https://api.github.com/repos/Lusitaniae/apache_exporter/releases/latest)
echo 

echo "Latest Release Info:"

echo "$latest_release_info"

echo 

# Extract the URL for the specified system distribution
url=$(echo "$latest_release_info" | jq -r --arg sys_dist "$sys_dist" '.assets[] | select(.name | contains($sys_dist)).browser_download_url')
echo 
echo "$url"
echo 

# Check if URL is empty
if [ -z "$url" ]; then
    echo "No matching distribution found for '$sys_dist'."
    exit 1
fi

# Download and extract Prometheus
echo "Downloading apache-exporter from URL"

wget -q --show-progress "$url"

echo 

echo "Extracting apache-exporter archive"

tar xvf "$(basename "$url")"

echo 

echo "apache-exporter has been downloaded and extracted."


sudo cp apache_exporter-*."$sys_dist"/apache_exporter /usr/local/bin

sudo chmod +x /usr/local/bin/apache_exporter

#check version
apache_exporter --version

sudo groupadd --system prometheus

sudo useradd -s /sbin/nologin --system -g prometheus prometheus

sudo tee -a /etc/systemd/system/apache_exporter.service<<EOF
[Unit]
Description=Prometheus
Documentation=https://github.com/Lusitaniae/apache_exporter
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/apache_exporter \
  --insecure \
  --scrape_uri=http://localhost:9117/server-status/?auto \
  --web.listen-address=0.0.0.0:9117 \
  --telemetry.endpoint=/metrics

SyslogIdentifier=apache_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

sudo systemctl start apache_exporter.service

sudo systemctl enable apache_exporter.service 

sudo systemctl status apache_exporter.service

