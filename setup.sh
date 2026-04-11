#!/bin/bash

source .env

# Installing needed packets
INSTALLED_PACKETS=$(apt list --installed)
if  echo "$INSTALLED_PACKETS" | grep -q "nginx" \
        && echo "$INSTALLED_PACKETS" | grep -q "certbot" \
        && echo "$INSTALLED_PACKETS" | grep -q "python3-certbot-nginx"; then
  echo "All the needed packets already exist"
else
  echo "Installing needed packets"
  sudo apt install -y nginx certbot python3-certbot-nginx
fi

# Configuring nginx
echo "Configuring nginx"
sudo sed "s|DOMAIN_NAME|$DOMAIN_NAME|g" ./vaultwarden.conf \
  | sudo tee /etc/nginx/sites-available/vaultwarden.conf
sudo ln -s /etc/nginx/sites-available/vaultwarden.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Setting up alertmanager with env value of discord webhook
sudo sed "s|DISCORD_WEBHOOK_URL|$DISCORD_WEBHOOK_URL|g" ./alertmanager/alertmanager.yml.tmp \
  | sudo tee ./alertmanager/alertmanager.yml > /dev/null 2>&1

# Configuring Let's Encrypt
echo "Configuring Let's Encrypt"
sudo certbot --nginx -n --agree-tos --email "$YOURE_EMAIL" -d "$DOMAIN_NAME"
sudo systemctl enable certbot.timer

# Rights
# change directory data rights
sudo chown -R 1000:1000 ./data/jenkins_data
sudo chown -R 65534:65534 ./data/prometheus_data

# stat -c '%g' /var/run/docker.sock
# put it in .env  and use value in docker compose  jenkinks group_add: - VALUE
DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)
echo "DOCKER_GID=$DOCKER_GID" >> .env

# Building docker image for jenkins
docker build -t alpine-testing:latest -f Dockerfile.agent .
#Also add to readmy that you must use this image for jenkins pipeline
