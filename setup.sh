#!/usr/bin/env bash

if [ -z "$1" ]; then
        echo "Usage: setup.sh <hostname or ip address>"
        exit 1
fi

# Get Dependancies
sudo add-apt-repository ppa:jonathonf/ffmpeg-4 -y
sudo apt-get update
sudo apt-get install build-essential libpcre3 libpcre3-dev libssl-dev unzip git ffmpeg -y

# Build Nginx with RTMP module
if pushd /tmp
then
        sudo wget "http://nginx.org/download/nginx-1.17.3.tar.gz"
        sudo wget "https://github.com/arut/nginx-rtmp-module/archive/v1.2.1.zip"
        sudo wget "http://www.zlib.net/zlib-1.2.11.tar.gz"
        sudo tar xvfz nginx-1.17.3.tar.gz
        sudo unzip v1.2.1.zip
        sudo tar xvfz zlib-1.2.11.tar.gz
        if cd nginx-1.17.3
        then
                ./configure --with-http_ssl_module --with-http_v2_module --with-http_auth_request_module --add-module=../nginx-rtmp-module-1.2.1 --with-zlib=../zlib-1.2.11 --with-cc-opt="-Wimplicit-fallthrough=0"
                sudo make install
        else
                echo "Unable to Build Nginx! Aborting."
                exit 1
        fi
else
        echo "Unable to Download Nginx due to missing /tmp! Aborting."
        exit 1
fi

popd

# Grab Configuration
sudo cp -R ./nginx/* /usr/local/nginx/conf/

# Setup Configuration with IP
sed -i "s/::IP_ADDR::/$1/g" /usr/local/nginx/conf/servers/osp-edge-servers.conf
sed -i "s/::IP_ADDR::/$1/g" /usr/local/nginx/conf/services/osp-edge-rtmp.conf

# Enable SystemD

sudo cp osp-edge.service /etc/systemd/system/osp-edge.service
sudo systemctl daemon-reload
sudo systemctl enable osp-edge.service

# Create HLS directory
sudo mkdir -p /var/www
sudo mkdir -p /var/www/live
sudo mkdir -p /var/www/live-adapt

sudo chown -R www-data:www-data /var/www

# Start Nginx
sudo systemctl start osp-edge.service