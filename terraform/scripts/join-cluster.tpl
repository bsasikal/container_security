#!/bin/bash

# Restart docker
sudo service docker restart

# Install and start docker private registry
sudo docker run -d -p 5000:5000 --restart=always --name image-registry registry:2

echo "start anchore engine"
cd /opt/anchore/aevolume
docker-compose pull
docker-compose up -d

# make sure anchore-engine loads the database completely as it is time consuming process
docker-compose exec engine-api anchore-cli system status
docker-compose exec engine-api anchore-cli system wait
docker-compose exec engine-api anchore-cli system feeds list

JENKINS_URL="${jenkins_url}"
JENKINS_USERNAME="${jenkins_username}"
JENKINS_PASSWORD="${jenkins_password}"
#TOKEN=$(curl -u $JENKINS_USERNAME:$JENKINS_PASSWORD "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")
TOKEN=test
INSTANCE_NAME=$(curl -s 169.254.169.254/latest/meta-data/local-hostname)
INSTANCE_IP=$(curl -s 169.254.169.254/latest/meta-data/local-ipv4)
JENKINS_CREDENTIALS_ID="${jenkins_credentials_id}"

sleep 60

curl -vvv -u "$JENKINS_USERNAME":"$JENKINS_PASSWORD" -H "$TOKEN" -d 'script=
import hudson.model.Node.Mode
import hudson.slaves.*
import jenkins.model.Jenkins
import hudson.plugins.sshslaves.verifiers.NonVerifyingKeyVerificationStrategy
import hudson.plugins.sshslaves.SSHLauncher
DumbSlave dumb = new DumbSlave("'$INSTANCE_NAME'",
"'$INSTANCE_NAME'",
"/home/ec2-user",
"3",
Mode.NORMAL,
"slaves",
new SSHLauncher("'$INSTANCE_IP'", 22, "'$JENKINS_CREDENTIALS_ID'", null, null, "", "", 60, 3, 15, new NonVerifyingKeyVerificationStrategy()),
RetentionStrategy.INSTANCE)
Jenkins.instance.addNode(dumb)
' $JENKINS_URL/script