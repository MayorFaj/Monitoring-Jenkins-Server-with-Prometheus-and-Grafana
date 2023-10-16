#!/bin/bash
set -x

sudo groupadd --system prometheus

# create a system user
# /sbin/nologin is used for system users who are not intended to log in interactively. It essentially disables shell access for the user
sudo useradd -s /sbin/nologin --system -g prometheus prometheus

sudo mkdir /var/lib/prometheus

sudo apt update -y

sudo apt -y install jq wget curl vim

mkdir -p /tmp/prometheus && cd /tmp/prometheus


#Input system distribution
echo "Enter the system distribution (e.g., linux-amd64, darwin-amd64, etc):"
read sys_dist

# Fetch release information

latest_release_info=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest)
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
echo "Downloading prometheus from URL"
wget -q --show-progress "$url"
echo 
echo "Extracting Prometheus archive"
tar xvf "$(basename "$url")"
echo 
echo "Prometheus has been downloaded and extracted."

cd prometheus*/

sudo mv prometheus promtool /usr/local/bin/

#confirm promrtheus version
prometheus --version

promtool --version

sudo mkdir /etc/prometheus/

sudo mv prometheus.yml /etc/prometheus/prometheus.yml

sudo mv consoles/ console_libraries/ /etc/prometheus/

cd $HOME

sudo tee /etc/systemd/system/prometheus.service<<EOF
[Unit] 
Description=Prometheus 
Documentation=https://prometheus.io/docs/introduction/overview/ 
Wants=network-online.target 
After=network-online.target

[Service] 
Type=simple 
User=prometheus 
Group=prometheus 
ExecReload=/bin/kill -HUP \$MAINPID 
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus --web.console.templates=/etc/prometheus/consoles --web.console.libraries=/etc/prometheus/console_libraries --web.listen-address=0.0.0.0:9090 --web.external-url=


SyslogIdentifier=prometheus
Restart=always

[Install] 
WantedBy=multi-user.target 
EOF

sudo chown -R prometheus:prometheus /etc/prometheus/

sudo chmod -R 775 /etc/prometheus/

sudo chown -R prometheus:prometheus /var/lib/prometheus/

sudo systemctl daemon-reload

sudo systemctl start prometheus

sudo systemctl enable prometheus

sudo systemctl status prometheus
