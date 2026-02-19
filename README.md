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
## Estructura de la Entrega Final
Para facilitar la corrección, los archivos validados se han organizado en la carpeta `entrega_final/`:
* **config/**: Contiene `squid.conf.final`, `lan.conf` (LDAP), `iptables-gateway.rules` y las listas de dominios.

---

# Memoria de Configuración de Squid Proxy

## Notas de Configuración
Se ha procedido a la **limpieza integral** del archivo `squid.conf` original.

### Justificación técnica:
* **Claridad y Mantenimiento:** Se han eliminado los comentarios y líneas en blanco para obtener un archivo de configuración minimalista y funcional. Esto reduce errores de lectura y facilita la auditoría de las reglas aplicadas.
* **Optimización:** Un archivo más ligero permite una carga y revisión más rápida de las directivas activas.

## Apartado 9 y 10: Autenticación LDAP y Clientes
* **Validación completa:** Se ha superado el test de estrés con el script `usuarios-lan.sh`, obteniendo un **pleno de 4/4 OK**.
* **Integración:** El proxy autentica correctamente contra el IDP (OpenLDAP) y discrimina por pertenencia al grupo `proxy_users`.
* **Persistencia:** Los clientes Alpine Linux mantienen la configuración mediante variables de entorno en `/etc/profile`, garantizando que todo el tráfico HTTP sea filtrado.

## Apartado Extra: Validación de Seguridad y Firewall
* **Filtro de dominios y palabras:** Implementado con éxito. Se bloquean términos como "poker" o "crack" mediante expresiones regulares.
* **Firewall (Anti-bypass):** El Gateway (GW) bloquea cualquier intento de salida directa a internet por los puertos 80/443, forzando el uso del Proxy.

## Apartado 3: Listas Negras Públicas (Subir Nota)
* **Implementación:** Se ha configurado una ACL que consume un archivo externo (`dominios-denegados`) para bloquear sitios de alto tráfico o redes sociales.
* **Jerarquía de Reglas:** Se ha priorizado el bloqueo de estas listas (Código 403) sobre la autenticación (Código 407), optimizando el rendimiento del servidor al no procesar credenciales para sitios ya denegados por política global.
