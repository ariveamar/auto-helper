#!/bin/bash

dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm -y
yum -y install bind bind-utils ansible vim wget curl bash-completion tree tar libselinux-python3 httpd haproxy
systemctl disable firewalld --now
setenforce 0
echo "Please confirm set main variable first done ?"
read inputs
echo $inputs
cp set-dns-serial.sh /usr/local/bin/
chmod +x /usr/local/bin/set-dns-serial.sh
sh /usr/local/bin/set-dns-serial.sh
ansible-playbook tasks/config-dns-only.yaml
ansible-playbook tasks/configure_haproxy_lb.yml
wget -O /root/openshift-install-linux.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/4.14.32/openshift-install-linux.tar.gz
wget -O /root/openshift-client-linux.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/4.14.32/openshift-client-linux.tar.gz
tar -xvf /root/openshift-install-linux.tar.gz -C /root/
tar -xvf /root/openshift-client-linux.tar.gz -C /root/
sed -i 's\80\8080\g' /etc/httpd/conf/httpd.conf
sudo systemctl enable httpd --now
echo "Please confirm set install-config.yaml has been done ?"
read inputs
echo $inputs
mkdir /ocp-prod
cp install-config.yaml /ocp-prod/
/root/openshift-install create manifests --dir  /ocp-prod
sed -i 's\true\false\g' /ocp-prod/manifests/cluster-scheduler-02-config.yml
/root/openshift-install create ignition-configs --dir /ocp-prod
cp /ocp-prod/*.ign /var/www/html/ignition
chmod 777 /var/www/html/ignition/*ign
