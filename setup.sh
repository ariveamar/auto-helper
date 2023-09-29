#!/bin/bash

dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm -y
yum -y install bind bind-utils ansible vim wget curl bash-completion tree tar libselinux-python3  dhcp-server tftp-server syslinux httpd haproxy
mv /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak
systemctl disable firewalld --now
setenforce 0
echo "Please confirm set main variable first done ?"
read inputs
echo $inputs
ansible-playbook tasks/configure_dhcpd.yml
cp set-dns-serial.sh /usr/local/bin/
chmod +x /usr/local/bin/set-dns-serial.sh
sh /usr/local/bin/set-dns-serial.sh
ansible-playbook tasks/configure_bind_dns.yml
cp helper-tftp.service /etc/systemd/system/helper-tftp.service
cp start-tftp.sh /usr/local/bin/
chmod +x /usr/local/bin/start-tftp.sh
systemctl daemon-reload
systemctl enable --now tftp helper-tftp named
mkdir -p  /var/lib/tftpboot/pxelinux.cfg
cp -rvf /usr/share/syslinux/* /var/lib/tftpboot
mkdir -p /var/lib/tftpboot/rhcos
mkdir -p /var/www/html/rhcos/
wget -O /var/lib/tftpboot/rhcos/initramfs.img https://rhcos.mirror.openshift.com/art/storage/prod/streams/4.12/builds/412.86.202308081039-0/x86_64/rhcos-412.86.202308081039-0-live-initramfs.x86_64.img
wget -O  /var/lib/tftpboot/rhcos/kernel https://rhcos.mirror.openshift.com/art/storage/prod/streams/4.12/builds/412.86.202308081039-0/x86_64/rhcos-412.86.202308081039-0-live-kernel-x86_64
wget -O /var/www/html/rhcos/rootfs.img https://rhcos.mirror.openshift.com/art/storage/prod/streams/4.12/builds/412.86.202308081039-0/x86_64/rhcos-412.86.202308081039-0-live-rootfs.x86_64.img
wget -O /root/openshift-install-linux.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/4.12.35/openshift-install-linux.tar.gz
wget -O /root/openshift-client-linux.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/4.12.35/openshift-client-linux.tar.gz
tar -xvf /root/openshift-install-linux.tar.gz -C /root/
tar -xvf /root/openshift-client-linux.tar.gz -C /root/
chmod -R 775 /var/www/html/rhcos 
chmod -R 775 /var/lib/tftpboot/rhcos
sed -i 's\80\8080\g' /etc/httpd/conf/httpd.conf
sudo systemctl enable httpd --now
ansible-playbook tasks/configure_tftp_pxe.yml
sudo mkdir -p /var/www/html/ignition
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
