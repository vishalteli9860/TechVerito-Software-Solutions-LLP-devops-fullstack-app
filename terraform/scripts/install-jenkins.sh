#!/bin/bash
set -euo pipefail

apt-get update
apt-get install -y openjdk-21-jre-headless curl git docker.io unzip
systemctl enable --now docker
usermod -aG docker ubuntu

curl -fsSL https://go.dev/dl/go1.20.14.linux-amd64.tar.gz -o /tmp/go.tar.gz
rm -rf /usr/local/go
mkdir -p /usr/local
tar -C /usr/local -xzf /tmp/go.tar.gz
ln -sf /usr/local/go/bin/go /usr/local/bin/go

curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

curl -fsSLo /usr/local/bin/kubectl https://dl.k8s.io/release/v1.28.15/bin/linux/amd64/kubectl
chmod 0755 /usr/local/bin/kubectl

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key | tee /usr/share/keyrings/jenkins-keyring.asc >/dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list >/dev/null
apt-get update
apt-get install -y jenkins
usermod -aG docker jenkins

sed -i 's/JENKINS_PORT=.*/JENKINS_PORT=8081/' /etc/default/jenkins
systemctl enable jenkins
systemctl restart docker
systemctl restart jenkins
