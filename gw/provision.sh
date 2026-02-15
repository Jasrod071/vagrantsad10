#!/usr/bin/env bash

# El script se detiene si hay errores
set -e
export DEBIAN_FRONTEND=noninteractive

echo "########################################"
echo " Aprovisionando Gateway con OpenVPN + LDAP "
echo "########################################"

# 1. Actualización e Instalación de herramientas
apt-get update -y
apt-get install -y net-tools iputils-ping curl tcpdump nmap openvpn easy-rsa openvpn-auth-ldap

# 2. Configuración de Red (IP Forwarding e IPTables)
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -F
iptables -t nat -F
iptables -A FORWARD -p tcp --dport 389 -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE 

# 3. Configuración de PKI (Certificados)
# Copiamos easy-rsa y generamos CA y certificados de servidor
cp -r /usr/share/easy-rsa /etc/openvpn/
cd /etc/openvpn/easy-rsa/
./easyrsa --batch init-pki
./easyrsa --batch build-ca nopass
./easyrsa --batch gen-req servidor-easyconfigpro nopass
./easyrsa --batch sign-req server servidor-easyconfigpro

# 4. Preparar archivos del servidor
openvpn --genkey secret /etc/openvpn/server/ta.key
cp pki/issued/servidor-easyconfigpro.crt /etc/openvpn/server/
cp pki/ca.crt /etc/openvpn/server/
cp pki/private/servidor-easyconfigpro.key /etc/openvpn/server/

# 5. Restaurar configuraciones desde la carpeta compartida /vagrant
# IMPORTANTE: Asegúrate de que los archivos existan en tu PC real en gw/openvpn/
cp /vagrant/gw/openvpn/server.conf /etc/openvpn/server/server.conf
cp /vagrant/gw/openvpn/client.conf /etc/openvpn/client/client.conf

# 6. Crear configuración del PLUGIN LDAP usando la variable del Vagrantfile
mkdir -p /etc/openvpn/auth
cat <<EOF > /etc/openvpn/auth/ldap.conf
<LDAP>
    URL             ldap://172.2.10.2
    BindDN          "cn=admin,dc=easyconfigpro,dc=org"
    Password        "${LDAP_PASS}"
    Timeout         15
</LDAP>

<Authorization>
    BaseDN          "ou=ou_usuarios,dc=easyconfigpro,dc=org"
    SearchFilter    "(&(uid=%u)(objectClass=posixAccount))"
</Authorization>
EOF

chmod 600 /etc/openvpn/auth/ldap.conf

# 7. Gestión de infraestructura de clientes
mkdir -p /etc/openvpn/client/keys /etc/openvpn/client/files
chmod -R 700 /etc/openvpn/client
cp /etc/openvpn/server/ca.crt /etc/openvpn/client/keys/
cp /etc/openvpn/server/ta.key /etc/openvpn/client/keys/

# 8. Reinicio de servicios
systemctl stop openvpn.service || true
systemctl disable openvpn.service || true
systemctl daemon-reload
systemctl enable openvpn-server@server
systemctl restart openvpn-server@server

echo "Gateway configurado y OpenVPN levantado."
