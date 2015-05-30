# Introducción

Este repositorio alberga un *contenedor Docker* para montar un [Plex Media Server](https://plex.tv/), está automatizado en el Registry Hub de Docker [luispa/base-plex](https://registry.hub.docker.com/u/luispa/base-plex/) conectado con el proyecto en [GitHub base-plex](https://github.com/LuisPalacios/base-plex). Además, en este otro repositorio [servicio-plex](https://github.com/LuisPalacios/servicio-plex) verás un ejemplo sobre cómo arrancar este servicio usando fig.

Te recomiendo que consultes este [apunte técnico sobre varios servicios en contenedores Docker](http://www.luispa.com/?p=172) para tener una visión más global de otros contenedores Docker y fuentes en GitHub y entender mejor este ejemplo.

## Ficheros

* **Dockerfile**: Para crear la base de servicio.
* **do.sh**: Para arrancar el contenedor creado con esta imagen.

# Personalización

### Volumen


Directorios persistentes donde se ubica la configuración de Plex (/config) y donde espero encontrar las fuentes de video, audio y fotografía (/data). 

    - "/Volumen/A/Configuración/Plex:/config"
    - "/Volumen/Multimedia:/data"
    - "/Volumen/Timezone/tz:/config/tz"

Directorio persistente para configurar el Timezone. Crear el directorio /Apps/data/tz y dentro de él crear el fichero timezone. Luego montarlo con -v o con fig.yml. 

    $ echo "Europe/Madrid" > /config/tz/timezone


## Instalación de la imagen

Para usar esta imagen descargándola desde el registry de docker hub:

    totobo ~ $ docker pull luispa/base-plex


## Clonar el repositorio

Si quieres clonar el repositorio desde Github:

    ~ $ clone https://github.com/LuisPalacios/docker-plex.git

Luego puedes crear la imagen localmente con el siguiente comando

    $ docker build -t luispa/base-plex ./


# Revisar y personalizar

Es muy importante que revises el fichero **do.sh** para comprobar que la configuración que se realiza es adecuada para tus intereses. 

