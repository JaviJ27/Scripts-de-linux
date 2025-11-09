#!/bin/bash
limpiar(){
  clear
  echo "---------------------------------"
  echo "| Creador de Contenedor con LXC |"
  echo "---------------------------------"
  echo ""
}

root() {
  check_root=$(id -u)
  if [[ $check_root -ne 0 ]];then
    echo "Usted no es ROOT, así que no puede ejecutar ese scipt"
    exit 1
  fi
}

conexion() {
  echo ""
  echo "Comprobando que tenga conexión a internet..."
  ping 8.8.8.8 -c 3  
  if [[ $? -ne 0 ]];then
    echo "Usted no tiene conexión, intentelo de nuevo mas tarde"
    exit 2
  fi
}

pausa(){
  echo ""
  echo -n "Pulse enter para continuar"
  read space
}

crear_contenedor(){
  echo -n "Introduzca el nombre del contenedor: "
  read container_name
  echo ""
  lxc-create -n $container_name -t download | tee /tmp/$container_name.txt
  DISTRO=$(cat /tmp/$container_name.txt | grep "You just created a" | awk '{print $5}')
  echo ""
  echo "¡¡¡El contenenedor se ha creado con exito!!!"
}

configurar_user_contenedor(){
  echo "Creando nuevo usuario"
  echo ""
  lxc-attach $container_name -- useradd -m -s /bin/bash usuario >/dev/null 2>/var/log/containercreator
  lxc-attach $container_name -- mkdir /home/usuario/.ssh >/dev/null 2>/var/log/containercreator
  lxc-attach $container_name -- chown usuario:usuario /home/usuario/.ssh >/dev/null 2>/var/log/containercreator
  lxc-attach $container_name -- bash -c 'echo ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA/WRwQYdoC8TjYvTfam8j9eVOoOcC6h0dj82Ajh0Ld7 javier@DebianJJG > /home/usuario/.ssh/authorized_keys' >/dev/null 2>/var/log/containercreator
  lxc-attach $container_name -- chown usuario:usuario /home/usuario/.ssh/authorized_keys >/dev/null 2>/var/log/containercreator
  lxc-attach $container_name -- bash -c 'echo "usuario ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers' >/dev/null 2>/var/log/containercreator
}

configrar_contenedor_debian(){
  lxc-start $container_name
  pausa
  limpiar
  echo "Se va a configurar el contenedor $DISTRO"
  echo ""
  echo "Actualizando el sistema"
  echo ""
  sleep 5 
  lxc-attach $container_name -- apt update -y >/dev/null 2>/var/log/containercreator
  lxc-attach $container_name -- apt upgrade -y >/dev/null 2>/var/log/containercreator
  echo "Instalando paquetes"
  echo ""
  lxc-attach $container_name -- apt install ssh locales ifupdown nano -y >/dev/null 2>/var/log/containercreator
  configurar_user_contenedor
  echo "Configurando idioma"
  echo ""
  lxc-attach $container_name -- bash -c 'echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen' >/dev/null 2>/var/log/containercreator
  lxc-attach $container_name -- locale-gen >/dev/null 2>/var/log/containercreator
  lxc-attach $container_name -- update-locale LANG=es_ES.UTF-8 LC_ALL=es_ES.UTF-8 >/dev/null 2>/var/log/containercreator
  echo "Configurando red"
  echo ""
  lxc-attach $container_name -- bash -c 'echo "" >> /etc/network/interfaces' >/dev/null 2>/var/log/containercreator
  lxc-attach $container_name -- bash -c 'echo "auto eth0" >> /etc/network/interfaces' >/dev/null 2>/var/log/containercreator
  lxc-attach $container_name -- bash -c 'echo "iface eth0 inet dhcp" >> /etc/network/interfaces' >/dev/null 2>/var/log/containercreator
  lxc-attach $container_name -- systemctl disable --now systemd-networkd.service >/dev/null 2>/var/log/containercreator
  lxc-attach $container_name -- systemctl disable --now systemd-networkd-wait-online.service >/dev/null 2>/var/log/containercreator
  lxc-attach $container_name -- systemctl mask systemd-networkd.service >/dev/null 2>/var/log/containercreator
  lxc-attach $container_name -- systemctl enable --now networking.service >/dev/null 2>/var/log/containercreator
  lxc-attach $container_name -- systemctl restart networking >/dev/null 2>/var/log/containercreator
  lxc-attach $container_name -- systemctl enable --now ssh >/dev/null 2>/var/log/containercreator
  echo "La configuración se ha completado con exito"
  pausa
  limpiar
  echo "Esta es la información de su nuevo contenedor"
  lxc-info $container_name
  echo ""
}

configrar_contenedor_ubuntu(){
  lxc-start $container_name
  pausa
  limpiar
  echo "Se va a configurar el contenedor $DISTRO"
  echo ""
  echo "Actualizando el sistema"
  echo "" 
  sleep 5
  lxc-attach $container_name -- apt update -y >/dev/null 2>/var/log/containercreator
  lxc-attach $container_name -- apt upgrade -y >/dev/null 2>/var/log/containercreator
  echo "Instalando paquetes"
  echo ""
  lxc-attach $container_name -- apt install ssh locales nano -y >/dev/null 2>/var/log/containercreator
  configurar_user_contenedor
  echo "Configurando idioma"
  echo ""
  lxc-attach $container_name -- bash -c 'echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen' >/dev/null 2>/var/log/containercreator
  lxc-attach $container_name -- locale-gen >/dev/null 2>/var/log/containercreator
  lxc-attach $container_name -- update-locale LANG=es_ES.UTF-8 LC_ALL=es_ES.UTF-8 >/dev/null 2>/var/log/containercreator
  echo "Habilitando y arrancando servicios"
  echo ""
  lxc-attach $container_name -- systemctl enable --now ssh >/dev/null 2>/var/log/containercreator
  echo "La configuración se ha completado con exito"
  pausa
  limpiar
  echo "Esta es la información de su nuevo contenedor"
  lxc-info $container_name
  echo ""
}

configrar_contenedor_rhel(){
  lxc-start $container_name
  pausa
  limpiar
  echo "Se va a configurar el contenedor $DISTRO"
  echo ""
  echo "Actualizando el sistema"
  echo "" 
  sleep 5
  lxc-attach $container_name -- dnf update -y >/dev/null 2>/var/log/containercreator
  lxc-attach $container_name -- dnf upgrade -y >/dev/null 2>/var/log/containercreator
  echo "Instalando paquetes"
  echo ""
  lxc-attach $container_name -- dnf install openssh-server nano NetworkManager ncurses glibc-langpack-es -y >/dev/null 2>/var/log/containercreator
  configurar_user_contenedor
  echo "Configurando idioma"
  echo ""
  lxc-attach $container_name -- localectl set-locale LANG=es_ES.UTF-8 >/dev/null 2>/var/log/containercreator
  echo "Habilitando y arrancando servicios"
  echo ""
  lxc-attach $container_name -- systemctl enable --now sshd >/dev/null 2>/var/log/containercreator
  lxc-attach $container_name -- systemctl enable --now NetworkManager >/dev/null 2>/var/log/containercreator
  echo "La configuración se ha completado con exito"
  pausa
  limpiar
  echo "Esta es la información de su nuevo contenedor"
  lxc-info $container_name
  echo ""
}
#----------------------------------------------------------------------------------------------------------------

limpiar
root
crear_contenedor
if [[ $DISTRO = "Debian" ]];then
  configrar_contenedor_debian
elif [[ $DISTRO = "Ubuntu" ]];then
  configrar_contenedor_ubuntu
elif [[ $DISTRO =~ ^(Fedora|Centos|Rockylinux|Almalinux)$ ]];then
  configrar_contenedor_rhel
else
  echo "Este script no puede configurar la distro seleccionada"
fi
