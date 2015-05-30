#
# Plex Media Server by Luispa, May 2015
#
# -----------------------------------------------------
#

# Desde donde parto...
#
FROM debian:jessie

#
MAINTAINER Luis Palacios <luis@luispa.com>

# Pido que el frontend de Debian no sea interactivo
ENV DEBIAN_FRONTEND noninteractive

# Actualizo el sistema operativo e instalo paquetes de software
#
RUN apt-get update && \
    apt-get -y install locales \
                       supervisor \
                       curl
           #            wget 
           #            net-tools \
           #            tcpdump \
           #            vim 

# Preparo locales
#
RUN locale-gen es_ES.UTF-8
RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales

# Preparo el timezone para Madrid
#
RUN echo "Europe/Madrid" > /etc/timezone; dpkg-reconfigure -f noninteractive tzdata

# Workaround para el Timezone, en vez de montar el fichero en modo read-only, voy a realizar
# lo siguiente en varios sitios: 
#
# 1) En este fichero (Dockerfile)
RUN mkdir -p /config/tz && mv /etc/timezone /config/tz/ && ln -s /config/tz/timezone /etc/
# 2) En el Script entrypoint (do.sh):
#     if [ -d '/config/tz' ]; then
#         dpkg-reconfigure -f noninteractive tzdata
#         echo "Hora actual: `date`"
#     fi
# 3) Al arrancar el contenedor, montar el volumen, un ejemplo:
#     /Apps/data/tz:/config/tz
# 4) Localizar la configuración, en el directorio persistente crear un fichero timezone
#     echo "Europe/Madrid" > /Apps/data/tz/timezone
 
# Instalo Plex Media Server
#
RUN echo "deb http://shell.ninthgate.se/packages/debian wheezy main" > /etc/apt/sources.list.d/plexmediaserver.list

RUN curl http://shell.ninthgate.se/packages/shell-ninthgate-se-keyring.key | apt-key add - 

RUN apt-get -q update && apt-get -qy --force-yes dist-upgrade 
	
RUN apt-get install -qy --force-yes ca-certificates \
                                    procps \
                                    plexmediaserver
                                    
# Limpiar
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* 
RUN rm -rf /tmp/*
                                            
# SSL
#
#RUN	openssl req -new -x509 -days 1095 -nodes \
#			-out /etc/ssl/certs/postfix.pem  \
#			-keyout /etc/ssl/private/postfix.key \
#			-subj "/C=ES/ST=Madrid/L=Mi querido pueblo/O=Org/CN=localhost"

# ------- ------- ------- ------- ------- ------- -------
# DEBUG ( Descomentar durante debug del contenedor )
# ------- ------- ------- ------- ------- ------- -------
#
# Herramientas SSH, tcpdump y net-tools
#RUN apt-get update && \
#    apt-get -y install 	openssh-server \
#                       	tcpdump \
#                        net-tools
## Setup de SSHD
#RUN mkdir /var/run/sshd
#RUN echo 'root:docker' | chpasswd
#RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
#RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
#ENV NOTVISIBLE "in users profile"
#RUN echo "export VISIBLE=now" >> /etc/profile

## Script que uso a menudo durante las pruebas. Es como "cat" pero elimina líneas de comentarios
RUN echo "grep -vh '^[[:space:]]*#' \"\$@\" | grep -v '^//' | grep -v '^;' | grep -v '^\$' | grep -v '^\!' | grep -v '^--'" > /usr/bin/confcat
RUN chmod 755 /usr/bin/confcat

#-----------------------------------------------------------------------------------

# Ejecutar siempre al arrancar el contenedor este script
#
ADD do.sh /do.sh
RUN chmod +x /do.sh
ENTRYPOINT ["/do.sh"]

#
# Si no se especifica nada se ejecutará lo siguiente: 
#
CMD ["/usr/bin/supervisord", "-n -c /etc/supervisor/supervisord.conf"]

