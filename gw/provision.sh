#!/usr/bin/env bash

# El script se detiene si hay errores
set -e
export DEBIAN_FRONTEND=noninteractive
echo "########################################"
echo " Aprovisionando Gateway "
echo "########################################"
echo "-----------------"
echo "Actualizando repositorios"
apt-get update -y && apt-get autoremove -y
apt-get install -y net-tools iputils-ping curl tcpdump nmap

echo "Gateway configurado"

# Activar el reenvío de paquetes (IP Forwarding)
echo 1 > /proc/sys/net/ipv4/ip_forward

# Limpiar reglas previas (Opcional pero recomendado)
iptables -F
iptables -t nat -F

# REGLA CLAVE: Permitir que el tráfico LDAP (389) pase a través del Gateway
# Esto permite que cualquier máquina de la LAN llegue al IDP por el puerto 389
iptables -A FORWARD -p tcp --dport 389 -j ACCEPT

# Permitir el tráfico de respuesta (ESTABLISHED y RELATED)
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# NAT para que las máquinas tengan salida a internet (si lo necesitas)
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "Reglas de IPTABLES aplicadas correctamente"