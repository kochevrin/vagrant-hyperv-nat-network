#!/bin/sh

echo 'Setting static IP address for VM ...'

IP_ADDRESS=$1
GATEWAY=$2

cat << EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - ${IP_ADDRESS}/24
      routes:
        - to: default
          via: ${GATEWAY}
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
EOF

# Be sure NOT to execute "netplan apply" here, so the changes take effect on
# reboot instead of immediately, which would disconnect the provisioner.