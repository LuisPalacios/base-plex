#!/bin/bash
#
# Punto de entrada para el servicio Plex Media Server
#
# Activar el debug de este script:
# set -eux
#

##################################################################
#
# main
#
##################################################################

# Averiguar si necesito configurar Postfix por primera vez
#
CONFIG_DONE="/.config_plex_done"
NECESITA_PRIMER_CONFIG="si"
if [ -f ${CONFIG_DONE} ] ; then
    NECESITA_PRIMER_CONFIG="no"
fi

##################################################################
#
# PREPARAR timezone
#
##################################################################

# Workaround para el Timezone, en vez de montar el fichero en modo read-only, voy a realizar
# lo siguiente en varios sitios: 
#
# 1) En este fichero (Dockerfile)
#    RUN mkdir -p /config/tz && mv /etc/timezone /config/tz/ && ln -s /config/tz/timezone /etc/
# 2) En el Script entrypoint (do.sh):
if [ -d '/config/tz' ]; then
    dpkg-reconfigure -f noninteractive tzdata
    echo "Hora actual: `date`"
fi
# 3) Al arrancar el contenedor, montar el volumen, un ejemplo:
#     /Apps/data/tz:/config/tz
# 4) Localizar la configuración, en el directorio persistente crear un fichero timezone
#     echo "Europe/Madrid" > /Apps/data/tz/timezone


##################################################################
#
# VARIABLES OBLIGATORIAS
#
##################################################################


## Servidor:Puerto por el que escucha el agregador de Logs (fluentd)
#
#if [ -z "${FLUENTD_LINK}" ]; then
#	echo >&2 "error: falta el Servidor:Puerto por el que escucha fluentd, variable: FLUENTD_LINK"
#	exit 1
#fi
#fluentdHost=${FLUENTD_LINK%%:*}
#fluentdPort=${FLUENTD_LINK##*:}

## Variables para crear la BD del servicio
#
#if [ -z "${SERVICE_POSTMASTER}" ]; then
#	echo >&2 "error: falta la variable SERVICE_POSTMASTER"
#	exit 1
#fi

##################################################################
#
# PREPARAR EL CONTAINER POR PRIMERA VEZ
#
##################################################################

# Necesito configurar por primera vez?
#
if [ ${NECESITA_PRIMER_CONFIG} = "si" ] ; then

	# Muestro las variables
	#
	echo >&2 "Realizo la instalación por primera vez !!!!"
	echo >&2 "-------------------------------------------"


	############
	#
	# Supervisor
	# 
	############
	
	### 
	### INICIO FICHERO  /etc/supervisor/conf.d/supervisord.conf
	### ------------------------------------------------------------------------------------------------
	cat > /etc/supervisor/conf.d/supervisord.conf <<-EOF_SUPERVISOR
	
	[unix_http_server]
	file=/var/run/supervisor.sock 					; path to your socket file
	
	[inet_http_server]
	port = 0.0.0.0:9001								; allow to connect from web browser
	
	[supervisord]
	logfile=/var/log/supervisor/supervisord.log 	; supervisord log file
	logfile_maxbytes=50MB 							; maximum size of logfile before rotation
	logfile_backups=10 								; number of backed up logfiles
	loglevel=error 									; info, debug, warn, trace
	pidfile=/var/run/supervisord.pid 				; pidfile location
	minfds=1024 									; number of startup file descriptors
	minprocs=200 									; number of process descriptors
	user=root 										; default user
	childlogdir=/var/log/supervisor/ 				; where child log files will live
	
	nodaemon=false 									; run supervisord as a daemon when debugging
	;nodaemon=true 									; run supervisord interactively
	 
	[rpcinterface:supervisor]
	supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface
	 
	[supervisorctl]
	serverurl=unix:///var/run/supervisor.sock		; use a unix:// URL for a unix socket 
		
	[program:plex]
	command=start_pms
	environment=HOME="/config"
	stdout_logfile=/config/logs/supervisor/%(program_name)s.log
	stderr_logfile=/config/logs/supervisor/%(program_name)s.log
	autostart=true
	autorestart=true
	
	#
	# DESCOMENTAR PARA INTEGRAR CON FLUENTD
	#
	#[program:rsyslog]
	#process_name = rsyslogd
	#command=/usr/sbin/rsyslogd -n
	#startsecs = 0
	#autorestart = true
	
	#
	# DESCOMENTAR PARA DEBUG o SI QUIERES SSHD
	#
	#[program:sshd]
	#process_name = sshd
	#command=/usr/sbin/sshd -D
	#startsecs = 0
	#autorestart = true
	
	EOF_SUPERVISOR
	### ------------------------------------------------------------------------------------------------
	### FIN FICHERO /etc/supervisor/conf.d/supervisord.conf  
	### 


	
	############
	#
	# Configurar rsyslogd para que envíe logs a un agregador remoto
	#
	############

	### 
	### INICIO FICHERO /etc/rsyslog.conf
	### ------------------------------------------------------------------------------------------------
    cat > /etc/rsyslog.conf <<-EOF_RSYSLOG
    
	\$LocalHostName postfix
	\$ModLoad imuxsock # provides support for local system logging
	#\$ModLoad imklog   # provides kernel logging support
	#\$ModLoad immark  # provides --MARK-- message capability
	
	# provides UDP syslog reception
	#\$ModLoad imudp
	#\$UDPServerRun 514
	
	# provides TCP syslog reception
	#\$ModLoad imtcp
	#\$InputTCPServerRun 514
	
	# Activar para debug interactivo
	#
	#\$DebugFile /var/log/rsyslogdebug.log
	#\$DebugLevel 2
	
	\$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
	
	\$FileOwner root
	\$FileGroup adm
	\$FileCreateMode 0640
	\$DirCreateMode 0755
	\$Umask 0022
	
	#\$WorkDirectory /var/spool/rsyslog
	#\$IncludeConfig /etc/rsyslog.d/*.conf
	
	# Dirección del Host:Puerto agregador de Log's con Fluentd
	#
	*.* @@${fluentdHost}:${fluentdPort}
	
	# Activar para debug interactivo
	#
	#*.* /var/log/syslog
	
	EOF_RSYSLOG
	### ------------------------------------------------------------------------------------------------
	### FIN FICHERO /etc/rsyslog.conf
	### 

	### Temporal, previo a fluentd
	###
	mkdir -p /config/logs/supervisor 

    #
    # Creo el fichero de control para que el resto de 
    # ejecuciones no realice la primera configuración
    > ${CONFIG_DONE}

fi


##################################################################
#
# EJECUCIÓN DEL COMANDO SOLICITADO
#
##################################################################
#
exec "$@"
