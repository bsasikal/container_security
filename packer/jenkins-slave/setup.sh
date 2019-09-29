#!/bin/bash

echo "Install Java JDK 8"
yum remove -y java
yum install -y java-1.8.0-openjdk

echo "Install Docker engine"
yum update -y
yum install docker -y
usermod -aG docker ec2-user
service docker start

echo "Install Docker compose"
curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose --version

echo "Install git"
yum install -y git

echo "Install Telegraf"
wget https://dl.influxdata.com/telegraf/releases/telegraf-1.6.0-1.x86_64.rpm -O /tmp/telegraf.rpm
yum localinstall -y /tmp/telegraf.rpm
rm /tmp/telegraf.rpm
chkconfig telegraf on
usermod -aG docker telegraf
mv /tmp/telegraf.conf /etc/telegraf/telegraf.conf
service telegraf start

echo "Install Anchore Engine"
sudo mkdir -p /opt/anchore/aevolume
sudo chmod 777 /opt/anchore/aevolume
cd /opt/anchore/aevolume

docker pull docker.io/anchore/anchore-engine:latest
docker create --name ae docker.io/anchore/anchore-engine:latest
docker cp ae:/docker-compose.yaml /opt/anchore/aevolume/docker-compose.yaml
docker rm ae

#echo "Install Anchore CLI"
#docker run -e ANCHORE_CLI_URL=http://localhost:8228/v1/ -it anchore/engine-cli
