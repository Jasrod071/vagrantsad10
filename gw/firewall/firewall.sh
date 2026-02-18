#!/bin/bash
set -x

# 0. Limpiar conexiones previas en memoria (evita que Google siga funcionando por sesiones viejas)
sudo conntrack -F

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

# L4. Permitir consultas DNS (Local)
iptables -A OUTPUT -o eth0 -p udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
iptables -A INPUT -i eth0 -p udp --sport 53 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# L5. Permitir http/https para actualizar y navegar (Local)
iptables -A OUTPUT -o eth0 -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -i eth0 -p tcp -m multiport --sports 80,443 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# L6. Permitir acceso SSH sólo desde adminpc
iptables -A INPUT -i eth3 -s 172.2.10.10 -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth3 -d 172.2.10.10 -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT

################################
# REGLAS DE PROTECCIÓN DE RED
################################

# --- BLOQUEO PREVENTIVO (NUEVO ORDEN - PRIORIDAD MÁXIMA) ---
# Si un paquete de la LAN intenta ir directamente a la WEB (80,443), RECHAZO inmediato.
iptables -A FORWARD -s 172.2.10.0/24 -p tcp -m multiport --dports 80,443 -j REJECT --reject-with icmp-admin-prohibited

# R1. NAT del tráfico saliente (Solo para la DMZ/Squid)
iptables -t nat -A POSTROUTING -s 172.1.10.0/24 -o eth1 -j MASQUERADE

# R2. Port Forwarding a WWW (172.1.10.3)
iptables -t nat -A PREROUTING -i eth1 -p tcp --dport 80 -j DNAT --to-destination 172.1.10.3
iptables -A FORWARD -i eth1 -o eth2 -p tcp -d 172.1.10.3 --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -p tcp -s 172.1.10.3 --sport 80 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# R3. Usuarios LAN -> WWW (DMZ) e SSH AdminPC
iptables -A FORWARD -i eth3 -o eth2 -s 172.2.10.0/24 -d 172.1.10.3 -p tcp -m multiport --dports 80,443 -j ACCEPT
iptables -A FORWARD -i eth3 -o eth2 -s 172.2.10.10 -d 172.1.10.3 -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth3 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# R4.v2 OBLIGAR PROXY (Tráfico LAN a Internet)
# 4.1 Permitir SOLO al puerto del Proxy (Squid)
iptables -A FORWARD -i eth3 -o eth2 -s 172.2.10.0/24 -d 172.1.10.2 -p tcp --dport 3128 -j ACCEPT

# 4.2 DNS directo (Permitido para que resuelvan nombres)
iptables -A FORWARD -i eth3 -o eth1 -s 172.2.10.0/24 -p udp --dport 53 -j ACCEPT
# 4.3 NTP y Ping directos
iptables -A FORWARD -i eth3 -o eth1 -s 172.2.10.0/24 -p udp --dport 123 -j ACCEPT
iptables -A FORWARD -i eth3 -o eth1 -s 172.2.10.0/24 -p icmp --icmp-type echo-request -j ACCEPT
iptables -A FORWARD -i eth1 -o eth3 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# R5/P6. SALIDA SQUID (DMZ -> Internet)
iptables -A FORWARD -i eth2 -o eth1 -s 172.1.10.2 -p tcp -m multiport --dports 80,443 -j ACCEPT
iptables -A FORWARD -i eth1 -o eth2 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# LDAP (172.2.10.2) hablando con el Proxy
iptables -A FORWARD -i eth3 -o eth2 -s 172.2.10.2 -d 172.1.10.2 -p tcp --dport 3128 -j ACCEPT

# OPENVPN
iptables -A INPUT -i eth1 -p udp --dport 1194 -j ACCEPT
iptables -A OUTPUT -o eth1 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# VPN -> DMZ y LDAP
iptables -A FORWARD -i tun0 -s 172.3.10.0/24 -j ACCEPT
iptables -A FORWARD -o tun0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# LOGS (Al final para capturar lo rechazado)
iptables -A FORWARD -j LOG --log-prefix "JSR-REJECT-FWD: "
iptables -A INPUT -j LOG --log-prefix "JSR-REJECT-IN: "