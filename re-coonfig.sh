#!/bin/bash
ansible-playbook tasks/configure_dhcpd.yml
ansible-playbook tasks/configure_bind_dns.yml
rm -rf /var/lib/tftpboot/pxelinux.cfg/*
ansible-playbook tasks/configure_tftp_pxe.yml
ansible-playbook tasks/configure_haproxy_lb.yml
