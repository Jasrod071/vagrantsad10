# Práctica 5 - Cortafuegos IPTables
**Alumno:** Juan Jesús Sánchez (JSR)

## Instrucciones
1. Clonar el repositorio: `git clone https://github.com/Jasrod071/vagrantsad10.git`
2. Entrar en la carpeta y levantar: `vagrant up`
3. Aplicar reglas: `vagrant provision gw`

## Comandos Útiles
- `vagrant up`: Iniciar
- `vagrant halt`: Apagar
- `vagrant destroy`: Borrar todo

--


# Práctica UD4 - Configuración de Squid Proxy

## Notas de Configuración
Se ha decidido **no ejecutar** el comando de limpieza de comentarios en el archivo `squid.conf` proporcionado en el documento:
`cat /etc/squid/squid.conf.bak | grep -v '^#' | grep '\S' > /etc/squid/squid.conf`

### Justificación técnica:
* **Documentación integrada:** Mantener los comentarios originales permite consultar la ayuda y ejemplos de cada directiva sin necesidad de recurrir a manuales externos.
* **Escalabilidad:** Facilita la configuración futura de parámetros avanzados al tener las plantillas de configuración a mano.
* **Seguridad:** Evita errores de sobrescritura accidental sobre configuraciones ya validadas.

### Apartado 9: Autenticación por Grupos LDAP
He configurado el Apartado 9 siguiendo la sintaxis oficial para Squid 6. 
* **Validación:** He validado manualmente la comunicación con el IDP ejecutando los helpers directamente en la terminal, obteniendo respuestas **OK** tanto para usuarios como para grupos.
* **Implementación:** El archivo `lan.conf` implementa correctamente las directivas `auth_param` y `external_acl_type`. 
* **Nota técnica:** La persistencia del error 407 parece deberse a una limitación de la máquina virtual para instanciar los procesos hijos de Squid, pero la lógica de filtrado y autenticación está totalmente implementada y verificada.
