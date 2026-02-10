#!/usr/bin/env bash

# El script se detiene si hay errores
set -e
export DEBIAN_FRONTEND=noninteractive

echo "########################################"
echo "      Aprovisionando idp - JJSR        "
echo "########################################"

echo "Actualizando repositorios..."
apt-get update -y
apt-get install -y net-tools iputils-ping curl tcpdump nmap

# --- PARTE 1: Tus datos ---
DOMAIN="easyconfigpro.org"
ORGANIZACION="Easy Config Pro S.L.U."
DB_DIR="/vagrant/idp/sldapdb"

# Cargamos datos en debconf para que no se nos pidan durante la instalación
sudo debconf-set-selections <<EOF
slapd slapd/no_configuration boolean false
slapd slapd/domain string ${DOMAIN}
slapd slapd/organization string ${ORGANIZACION}
slapd slapd/purge_database boolean true
EOF

# Instalamos paquetes necesarios para openldap
apt-get install -y slapd ldap-utils
apt-get autoremove -y

# Forzamos la contraseña de administrador (la que definiste en Vagrantfile)
echo "[*] Forzando contraseña de administrador..."
SECURE_HASH=$(slappasswd -s "$LDAP_PASS")
cat <<EOF > /tmp/set_pass.ldif
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: $SECURE_HASH
EOF

# Aplicamos la contraseña usando el socket local
ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/set_pass.ldif

# --- PARTE 2: Carga de tus archivos LDIF ---
echo "[*] Cargando base (OUs)..."
ldapadd -x -D "cn=admin,dc=easyconfigpro,dc=org" -w $LDAP_PASS -f "$DB_DIR/basedn.ldif" -c

echo "[*] Cargando grupos..."
ldapadd -x -D "cn=admin,dc=easyconfigpro,dc=org" -w $LDAP_PASS -f "$DB_DIR/grupos.ldif" -c

echo "[*] Cargando usuarios..."
ldapadd -x -D "cn=admin,dc=easyconfigpro,dc=org" -w $LDAP_PASS -f "$DB_DIR/usr.ldif" -c

echo "------ CONFIGURACIÓN COMPLETADA ------"