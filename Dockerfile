FROM ubuntu:latest
LABEL MANTAINER="Rafael Santisteban"

RUN apt-get update 
RUN apt-get -y install python3 python3-pip python3-venv sshpass sudo
RUN apt-get -y --fix-missing install git
RUN pip3 install --upgrade pip
RUN useradd -m ansible
USER ansible
# RUN pip install ansible==2.10 --user, netaddr, paramiko, argcomplete
WORKDIR /home/ansible/
ADD ./build-config/requirements.txt ./
RUN pip install -r requirements.txt

# ENV DEBIAN_FRONTEND=noninteractive
# ENV DEBCONF_NONINTERACTIVE_SEEN=true
# RUN echo "tzdata tzdata/Areas select Europe" >> /root/preseed.txt
# RUN echo "tzdata tzdata/Zones/Europe select Berlin" >> /root/preseed.txt
# RUN echo "locales locales/locales_to_be_generated multiselect     es_ES.UTF-8 UTF-8"  >> /root/preseed.txt
# RUN echo "locales locales/default_environment_locale      select  es_ES.UTF-8" >> /root/preseed.txt
# RUN debconf-set-selections /root/preseed.txt

#Preparación del sistema
USER root
ENV PATH=/home/ansible/.local/bin:${PATH}
RUN echo PATH="/home/ansible/.local/bin":${PATH} >> /etc/profile
ADD ./build-config/ssh_config.conf /etc/ssh/ssh_config.d/
RUN chmod 644  /etc/ssh/ssh_config.d/ssh_config.conf
RUN mkdir /etc/ansible
ADD ./build-config/ansible.cfg /etc/ansible/

## Apaño necesario debido al BUG de Ansible en delegate_to y local_action que SIEMPRE intentan ser root.
## Esto convierte al contenedor en peligroso. Eliminar o comentar si no se emplean los módulos mencionados.
RUN echo 'ansible     ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER ansible

# # #Para traspado de datos con ROLES
# # WORKDIR /opt/ansible/roles
# # RUN ansible-galaxy init --force basic_config
# # # creamos una estructura de directorios y ficheros que luego sobreescribimos en algun caso.
# # ADD ./config/roles /opt/ansible/roles
#     # tasks : main.yml define tareas a ejecutar en el rol.
#     # templates: plantillas Jinja2 para usar en el rol.
#     # vars: Variables a emplear que tendrán preferencia en la ejecución.
#     # handlers: main.yml manejadores a arrancar como parte del playbook.

# WORKDIR /opt/ansible

# #RUN ansible-galaxy collection install ansible.netcommon
RUN ansible-galaxy collection install community.general
RUN ansible-galaxy collection install cisco.ios

# # Instalación para permitir uso de pyATS y Genie para parseo de configuraciones y datos de Cisco.
RUN pip install pyats[library] jmespath fortiosapi
RUN ansible-galaxy install clay584.parse_genie

# # Instalacion de parseo manual
RUN ansible-galaxy install ansible-network.network-engine

# # Para usar con fortigate
RUN ansible-galaxy collection install fortinet.fortios

# # Modulo para usat GIT
RUN ansible-galaxy collection install lvrfrc87.git_acp && \
    git config --global user.email usuario@example.com && \
    git config --global user.name "Rafael Santisteban"

# # configuración de datos globales de GIT
# RUN git config --global user.email rafaelsb@cac.es
# RUN git config --global user.name "Rafael Santisteban"

# # RUN apt -y install vim

# VOLUME [ "/home/ansible/.ansible" ]

ADD ./build-config/inventory/hosts.ini /home/ansible/.ansible/hosts
ADD ./build-config/inventory/group_vars /home/ansible/.ansible/group_vars/
ADD ./build-config/inventory/host_vars /home/ansible/.ansible/host_vars/

WORKDIR /home/ansible/.ansible 

USER ansible

CMD [ "/usr/bin/bash" ]
