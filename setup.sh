#!/bin/bash

dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm -y
yum -y install bind bind-utils git ansible vim wget curl bash-completion tree tar libselinux-python3  dhcp-server tftp-server syslinux httpd haproxy
mv /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak
systemctl disable firewalld --now
setenforce 0
git clone https://github.com/ariveamar/auto-helper.git
cd auto-helper
echo "Please confirm set main variable first done ?"
read inputs
echo $inputs
vim handlers/main.yml
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
chmod 775 /var/www/html/rhcos
wget -O https://rhcos.mirror.openshift.com/art/storage/prod/streams/4.12/builds/412.86.202308081039-0/x86_64/rhcos-412.86.202308081039-0-live-kernel-x86_64 /var/lib/tftpboot/rhcos/kernel
wget -O  /var/lib/tftpboot/rhcos/kernel https://rhcos.mirror.openshift.com/art/storage/prod/streams/4.12/builds/412.86.202308081039-0/x86_64/rhcos-412.86.202308081039-0-live-kernel-x86_64
wget -O /var/www/html/rhcos/rootfs.img https://rhcos.mirror.openshift.com/art/storage/prod/streams/4.12/builds/412.86.202308081039-0/x86_64/rhcos-412.86.202308081039-0-live-rootfs.x86_64.img
wget -O /root/openshift-install-linux.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/4.12.35/openshift-install-linux.tar.gz
wget -O /root/openshift-client-linux.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/4.12.35/openshift-client-linux.tar.gz
tar -xvf /root/openshift-install-linux.tar.gz
tar -xvf /root/openshift-client-linux.tar.gz
sed -i 's\80\8080\g' /etc/httpd/conf/httpd.conf
sudo systemctl enable httpd --now
ansible-playbook tasks/configure_tftp_pxe.yml

sudo mkdir -p /var/www/html/ignition
