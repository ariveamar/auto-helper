#!/bin/bash
mkdir -p /var/www/html/
wget -O /root/openshift-install-linux.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/4.18.21/openshift-install-linux.tar.gz
wget -O /root/openshift-client-linux.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/4.18.21/openshift-client-linux.tar.gz
tar -xvf /root/openshift-install-linux.tar.gz -C /root/
tar -xvf /root/openshift-client-linux.tar.gz -C /root/
chmod -R 775 /var/www/html/

mkdir /ocp-prod
cp install-config.yaml /ocp-prod/
/root/openshift-install create manifests --dir  /ocp-prod
sed -i 's\true\false\g' /ocp-prod/manifests/cluster-scheduler-02-config.yml
/root/openshift-install create ignition-configs --dir /ocp-prod
cp /ocp-prod/*.ign /var/www/html/ignition
chmod 777 /var/www/html/ignition/*ign
