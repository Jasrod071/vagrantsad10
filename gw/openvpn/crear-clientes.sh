#!/bin/bash
# Script para generar clientes automáticamente

# ESTO ES LO QUE TE FALTA: Captura el argumento (ej: luna)
USERID=$1

# Si no escribes un nombre, el script te avisa y para
if [ -z "$USERID" ]; then
    echo "Uso: $0 nombre_del_cliente"
    exit 1
fi

echo "[*] Generando certificado de cliente para $USERID"
cd /etc/openvpn/easy-rsa/

# 1. Generamos par de claves para el cliente
/etc/openvpn/easy-rsa/easyrsa --batch gen-req ${USERID} nopass

# 2. Firmamos la clave con nuestra CA
/etc/openvpn/easy-rsa/easyrsa --batch sign-req client ${USERID}

# 3. Copiamos ficheros a la carpeta de llaves del cliente
cp /etc/openvpn/easy-rsa/pki/issued/${USERID}.crt /etc/openvpn/client/keys
cp /etc/openvpn/easy-rsa/pki/private/${USERID}.key /etc/openvpn/client/keys

# 4. Definimos rutas para montar el .ovpn
KEY_DIR=/etc/openvpn/client/keys
OUTPUT_DIR=/etc/openvpn/client/files
BASE_CONFIG=/etc/openvpn/client/client.conf

# 5. Montamos el archivo .ovpn uniendo la base + certificados
cat ${BASE_CONFIG} > ${OUTPUT_DIR}/${USERID}.ovpn
echo -e '<ca>' >> ${OUTPUT_DIR}/${USERID}.ovpn 
cat ${KEY_DIR}/ca.crt  >> ${OUTPUT_DIR}/${USERID}.ovpn
echo -e '</ca>\n<cert>' >> ${OUTPUT_DIR}/${USERID}.ovpn
cat ${KEY_DIR}/${USERID}.crt >> ${OUTPUT_DIR}/${USERID}.ovpn
echo -e '</cert>\n<key>' >> ${OUTPUT_DIR}/${USERID}.ovpn
cat ${KEY_DIR}/${USERID}.key >> ${OUTPUT_DIR}/${USERID}.ovpn
echo -e '</key>\n<tls-crypt>' >> ${OUTPUT_DIR}/${USERID}.ovpn
cat ${KEY_DIR}/ta.key >> ${OUTPUT_DIR}/${USERID}.ovpn
echo -e '</tls-crypt>' >> ${OUTPUT_DIR}/${USERID}.ovpn

echo "[+] Archivo generado en: ${OUTPUT_DIR}/${USERID}.ovpn"
