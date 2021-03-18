#!/bin/bash

SSID="YourNetworkName"
PASSWORD="YourPassword"
DNS="UPatrasDNS"

# Install access point software
apt install hostapd

# Enable access point service ans start at boot
systemctl unmask hostap
systemctl enable hostapd

# Install dnsmasq to provide network management services (DNS, DHCP) 
apt install dnsmasq

# install netfilter-persistent and iptables-persistent to save firewall rules 
DEBIAN_FRONTEND=noninteractive apt install -y netfilter-persistent iptables-persistent

# Assign first IP address of the wireless network to the Pi, to act as router
echo "
interface wlan0
static ip_address=192.168.4.1/24
nohook wpa_supplicant
" >> /etc/dhcpcd.conf

# Enable routing
echo "# https://www.raspberrypi.org/documentation/configuration/wireless/access-point-routed.md
# Enable IPv4 routing
net.ipv4.ip_forward=1
" >> /etc/sysctl.d/routed-ap.conf

# Masquerade traffic from/to wireless clients as Pi
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Persist changes to be loaded at boot
netfilter-persistent save

# Add UPatras nameserver
echo "
server=$DNS
" >> /etc/dnsmasq.conf

# Configure DHCP and DNS services for the wireless network
echo "
interface=wlan0 # Listening interface
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
                # Pool of IP addresses served via DHCP
domain=wlan     # Local wireless DNS domain
address=/gw.wlan/192.168.4.1
                # Alias for this router
" >> /etc/dnsmasq.conf

# Ensure wireless operation
rfkill unblock wlan

# Configure access point
echo "country_code=GR
interface=wlan0
ssid=$SSID
hw_mode=g
channel=7
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$PASSWORD
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
" >> /etc/hostapd/hostapd.conf


reboot

