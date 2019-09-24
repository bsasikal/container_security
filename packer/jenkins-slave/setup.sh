#!/bin/bash

echo "Install Java JDK 8"
yum remove -y java
yum install -y java-1.8.0-openjdk

echo "Install Docker engine"
yum update -y
yum install docker -y
usermod -aG docker ec2-user
service docker start

echo "Install git"
yum install -y git

echo "Setup SSH key"
mkdir /var/lib/jenkins/.ssh
touch /var/lib/jenkins/.ssh/known_hosts
chmod 700 /var/lib/jenkins/.ssh
cp /tmp/id_rsa /var/lib/jenkins/.ssh/id_rsa && chown jenkins:jenkins /tmp/id_rsa
mv /tmp/id_rsa.pub /var/lib/jenkins/.ssh/id_rsa.pub
chown -R jenkins:jenkins /var/lib/jenkins/.ssh
chmod 600 /var/lib/jenkins/.ssh/id_rsa /var/lib/jenkins/.ssh/id_rsa.pub

echo "Install Telegraf"
wget https://dl.influxdata.com/telegraf/releases/telegraf-1.6.0-1.x86_64.rpm -O /tmp/telegraf.rpm
yum localinstall -y /tmp/telegraf.rpm
rm /tmp/telegraf.rpm
chkconfig telegraf on
usermod -aG docker telegraf
mv /tmp/telegraf.conf /etc/telegraf/telegraf.conf
service telegraf start