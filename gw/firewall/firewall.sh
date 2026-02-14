#!/bin/bash
set -x

# Activamos el IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Borrar todas las tablas y reiniciar contadores
iptables -F
iptables -t nat -F
iptables -Z
iptables -t nat -Z

# ANTI-LOCK rule: Permitir ssh a través de la eth0 para manejarla con vagrant
iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport 22 -j ACCEPT

# POLÍTICAS POR DEFECTO
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

################################
# REGLAS DE PROTECCIÓN LOCAL
################################
# L1. Permitir tráfico loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# L2. Permitir ping a cualquier máquina interna o externa
iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT

# L3. Permitir que me hagan ping desde LAN y DMZ
iptables -A INPUT -i eth2 -s 172.1.10.0/24 -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -i eth3 -s 172.2.10.0/24 -p icmp --icmp-type echo-request -j ACCEPT
iptables -A OUTPUT -o eth2 -s 172.1.10.1 -p icmp --icmp-type echo-reply -j ACCEPT
iptables -A OUTPUT -o eth3 -s 172.1.10.1 -p icmp --icmp-type echo-reply -j ACCEPT

# L4. Permitir consultas DNS
iptables -A OUTPUT -o eth0 -p udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
iptables -A INPUT -i eth0 -p udp --sport 53 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# L5. Permitir http/https para actualizar y navegar
iptables -A OUTPUT -o eth0 -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED   -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --sport 80 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --dport 443 -m conntrack --ctstate NEW,ESTABLISHED   -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --sport 443 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# L6. Permitir acceso SSH sólo desde adminpc
iptables -A INPUT -i eth3 -s 172.2.10.10 -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth3 -d 172.2.10.10 -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT

################################
# REGLAS DE PROTECCIÓN DE RED
################################
# R1. Se debe hacer NAT del tráfico saliente
iptables -t nat -A POSTROUTING -s 172.2.10.0/24 -o eth0 -j MASQUERADE

#R2. Permitir acceso desde la WAN a www a través del 80 haciendo port forwading
# Redirige el tráfico que llega a la IP de la WAN (eth1) hacia el servidor www
iptables -t nat -A PREROUTING -i eth1 -p tcp --dport 80 -j DNAT --to-destination 172.1.10.3

# Permitir el paso en FORWARD para ese tráfico DNAT
iptables -A FORWARD -i eth1 -o eth2 -p tcp -d 172.1.10.3 --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -p tcp -s 172.1.10.3 --sport 80 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT


# R3.a Usuarios LAN -> WWW (80 y 443)
iptables -A FORWARD -i eth3 -o eth2 -s 172.2.10.0/24 -d 172.1.10.3 -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth3 -s 172.1.10.3 -d 172.2.10.0/24 -p tcp -m multiport --sports 80,443 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# R3.b AdminPC -> SSH a DMZ (Corregida)
iptables -A FORWARD -i eth3 -o eth2 -s 172.2.10.10 -d 172.1.10.3 -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth3 -s 172.1.10.3 -d 172.2.10.10 -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# R4. Permitir salir tráfico de la LAN
iptables -A FORWARD -i eth3 -o eth0 -s 172.2.10.0/24 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth3 -d 172.2.10.0/24 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

#R5. Permitir salir tráfico de la DMZ (sólo http/https/dns/ntp)
# DNS (UDP 53)
iptables -A FORWARD -i eth2 -o eth1 -s 172.1.10.0/24 -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -i eth1 -o eth2 -d 172.1.10.0/24 -p udp --sport 53 -j ACCEPT
iptables -A FORWARD -i eth1 -o eth2 -d 172.1.10.0/24 -p udp --sport 123 -j ACCEPT

# HTTP/HTTPS y NTP (TCP 80,443 y UDP 123)
iptables -A FORWARD -i eth2 -o eth1 -s 172.1.10.0/24 -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -s 172.1.10.0/24 -p udp --dport 123 -j ACCEPT

# Respuestas de Internet a la DMZ
iptables -A FORWARD -i eth1 -o eth2 -d 172.1.10.0/24 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# No olvides el NAT para la DMZ (para que puedan salir a internet)
iptables -t nat -A POSTROUTING -s 172.1.10.0/24 -o eth1 -j MASQUERADE

# Reglas para hacer logs - /var/log/kern.log
iptables -A FORWARD -j LOG --log-prefix "JSR-FORWARD-"
iptables -A INPUT -j LOG --log-prefix "JSR-INPUT-"
iptables -A OUTPUT -j LOG --log-prefix "JSR-OUTPUT-"

# =========================================================
# REGLAS PARA OPENVPN (APARTADO 5)
# =========================================================

# Regla P4.2.1 Permitir acceso WAN (eth1) a servidor VPN
iptables -A INPUT -i eth1 -p udp --dport 1194 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth1 -p udp --sport 1194 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Permitir que el openvpn en el GW consulte al servidor LDAP (IDP) 
iptables -A OUTPUT -o eth3 -d 172.2.10.2 -p tcp --dport 389 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -i eth3 -s 172.2.10.2 -p tcp --sport 389 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Regla P4.2.2 Permitir acceso de VPN-net a http de la DMZ
iptables -A FORWARD -i tun0 -o eth2 -s 172.3.10.0/24 -d 172.1.10.3 -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o tun0 -s 172.1.10.3 -d 172.3.10.0/24 -p tcp -m multiport --sports 80,443 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Regla P4.2.3 Permitir acceso de VPN-net a IDP de la DMZ
iptables -A FORWARD -i tun0 -o eth3 -s 172.3.10.0/24 -d 172.2.10.2 -p tcp --dport 389 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth3 -o tun0 -s 172.2.10.2 -d 172.3.10.0/24 -p tcp --sport 389 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT