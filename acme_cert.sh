#!/bin/bash

read -p "Enter your domain name: " domain_name
read -p "CF_Account_ID: " cf_account_id
read -p "CF_Token: " cf_token
certs_dir=/etc/nginx/certs

# Install dependencies
apt update
apt upgrade -y
apt dist-upgrade -y
apt install curl vim wget gnupg dpkg apt-transport-https lsb-release ca-certificates -y

# Add n.wtf repository
curl -sSL https://n.wtf/public.key | gpg --dearmor > /usr/share/keyrings/n.wtf.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/n.wtf.gpg] https://mirror-cdn.xtom.com/sb/nginx/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/n.wtf.list

# Install nginx-extras
apt update
apt install nginx-extras -y

# Install acme.sh
curl https://get.acme.sh | sh -s email=riolu.rs@gmail.com

# Set Cloudflare API credentials
export CF_Account_ID=$cf_account_id
export CF_Token=$cf_token

# Create directory for certificates
mkdir -p $certs_dir/$domain_name

# Issue certificate
acme.sh --issue --dns dns_cf -d $domain_name

# Renew certificate
# acme.sh --renew -d $domain_name

# Install certificate
acme.sh --install-cert -d $domain_name --key-file $certs_dir/$domain_name/cert.key --fullchain-file $certs_dir/$domain_name/fullchain.cer --reloadcmd "service nginx force-reload"

# Add nginx user
useradd -r nginx

# Download the new nginx.conf file
curl -o nginx.conf https://raw.githubusercontent.com/stitchrs/V2bX-script/master/config/nginx.conf

# Replace the existing nginx.conf file
mv nginx.conf /etc/nginx/nginx.conf

sed -i "s/\$domain_name/$domain_name/g" /etc/nginx/nginx.conf
systemctl restart nginx
