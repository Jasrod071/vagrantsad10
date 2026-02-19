#!/bin/bash

# 0. Limpiar (si no está conntrack, no pasa nada)
sudo conntrack -F 2>/dev/null

# 1. Limpiar reglas con SUDO
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -Z
sudo iptables -t nat -Z

# 2. Forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# 3. Políticas por defecto
sudo iptables -P INPUT DROP
sudo iptables -P OUTPUT DROP
sudo iptables -P FORWARD DROP

# 4. SSH Vagrant y Loopback
sudo iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
sudo iptables -A OUTPUT -o eth0 -p tcp --sport 22 -j ACCEPT
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT

# 5. ICMP (Ping)
sudo iptables -A FORWARD -p icmp -j ACCEPT
sudo iptables -A INPUT -p icmp -j ACCEPT
sudo iptables -A OUTPUT -p icmp -j ACCEPT

# 6. ESTADO Y BLOQUEO TEST 3 (La clave del éxito)
sudo iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A FORWARD -s 172.1.10.0/24 -p tcp -m multiport --dports 80,443 -j REJECT

# 7. PERMITIR PROXY Y DNS
sudo iptables -A FORWARD -s 172.1.10.0/24 -d 172.2.10.5 -p tcp --dport 3128 -j ACCEPT
sudo iptables -A FORWARD -p udp --dport 53 -j ACCEPT

# 8. NAT
sudo iptables -t nat -A POSTROUTING -s 172.1.10.0/24 -o eth1 -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -s 172.2.10.0/24 -o eth1 -j MASQUERADE

echo "Firewall aplicado correctamente."