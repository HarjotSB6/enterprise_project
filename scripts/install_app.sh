#!/bin/bash
# install_app.sh - Initializes cross-cloud app server with basic monitoring

# Variables injected by Terraform templatefile()
region="${region}"
server_id="${server_id}"

# Update & install dependencies
sudo apt-get update -y
sudo apt-get install -y nginx curl jq

# Configure simple app page
echo "<html><body><h1>Disaster Recovery Node</h1>" > /var/www/html/index.html
echo "<p>Region: ${region}</p>" >> /var/www/html/index.html
echo "<p>Server ID: ${server_id}</p>" >> /var/www/html/index.html
echo "</body></html>" >> /var/www/html/index.html

# Start NGINX
systemctl enable nginx
systemctl start nginx

# Install Node Exporter for Prometheus monitoring
cd /tmp
NODE_EXPORTER_VERSION="1.7.0"
curl -LO "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
tar xvf "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
sudo cp "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" /usr/local/bin/

# Create systemd service for node_exporter
cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=nobody
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=default.target
EOF

# Start node_exporter
sudo systemctl daemon-reexec
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
