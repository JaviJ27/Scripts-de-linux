#!/bin/bash
limpiar(){
  clear
  if apt policy figlet 2> /dev/null | grep -qoe "(ninguno)" || apt policy lolcat 2> /dev/null | grep -qoe "(ninguno)"; then
    echo "-------------------"
    echo "| INSTALADOR DHCP |"
    echo "-------------------"
    echo ""
  else
    figlet -f big -w 200 "INSTALADOR   DHCP" | /usr/games/lolcat
  fi
}

pausa(){
  echo ""
  echo -n "Pulse enter para continuar"
  read space
  }
root() {
  echo "Comprobando que usted tenga permisos de administrador..."
  sleep 2
  if [[ $UID -eq 0 ]];then
    echo "Usted es ROOT"
    return 0
  else
    echo "Usted no es ROOT, así que no puede ejecutar ese scipt"
    exit 1
  fi
}

conexion() {
  ping -c1 8.8.8.8 > /dev/null 2> /dev/null
  if [[ $? -eq 0 ]];then
    echo "Parece que su conexion es buena a si que vamos a instalar el DHCP"
    return 0
  else
    echo "Parace que no tiene conxion, compruebe su conexion o intentelo mas tarde"
    exit 1
  fi
}

dhcp_install() {
  echo ""
  echo "Comprobando si tiene el servidor DHCP instalado..."
  sleep 2
  if apt policy isc-dhcp-server 2> /dev/null | grep -qoe "(ninguno)"; then
    echo "El servidor DHCP no esta instalado, a si que vamos a intentar instalarlo"
    return 1
  else
    echo "El servidor DHCP esta instalado"
    return 0
  fi
}

instalar_DHCP() {
  if [[ $? -eq 1 ]];then
    echo ""
    echo "Comprobando su conexion a internet..."
    sleep 2
    conexion
    if [[ $? -eq 0 ]];then
      echo ""
      echo "Instalando servidor DHCP..."
      apt update -y > /dev/null 2> /dev/null && apt upgrade -y > /dev/null 2> /dev/null && apt install -y isc-dhcp-server > /dev/null 2> /dev/null
      if [[ $? -eq 0 ]];then
        echo "El servidor DHCP se a instalado con exito"
      else
        echo "Ha ocurrido un error al intentar descargar el servidor DHCP"
        exit 1
      fi
    fi
  fi
}

binarios_install() {
  echo ""
  echo "Comprobando si tiene todos los paquetes necesarios..."
  if apt policy figlet 2> /dev/null | grep -qoe "(ninguno)" || apt policy lolcat 2> /dev/null | grep -qoe "(ninguno)"; then
    echo "Parece que falta algun paquete, a si que vamos a intentar instalarlo"
    return 1
  else
    echo "Todos los paquetes estan instalados"
    return 0
  fi
  rm /usr/share/figlet/wideterm.tlf 2> /dev/null > /dev/null
  wget https://raw.githubusercontent.com/JaviJ27/Script-de-linux/refs/heads/main/wideterm.tlf 2> /dev/null > /dev/null
  wget https://raw.githubusercontent.com/JaviJ27/Script-de-linux/refs/heads/main/pagga.tlf 2> /dev/null > /dev/null
  mv wideterm.tlf /usr/share/figlet/
  mv pagga.tlf /usr/share/figlet/
}

instalar_binarios() {
  if [[ $? -eq 1 ]];then
    echo ""
    echo "Comprobando su conexion a internet..."
    sleep 2
    conexion
    if [[ $? -eq 0 ]];then
      echo ""
      echo "Instalando paquetes necesarios..."
      apt update -y > /dev/null 2> /dev/null && apt upgrade -y > /dev/null 2> /dev/null && apt install -y figlet > /dev/null 2> /dev/null && apt install -y lolcat > /dev/null 2> /dev/null
      if [[ $? -eq 0 ]];then
        echo "Todos los paquetes se han instalado con exito"
      else
        echo "Ha ocurrido un error al intentar descargar los paquetes necesarios"
        exit 1
      fi
    fi
  fi
}

add_interfaces(){
  echo -e "\e[35m$(figlet -f wideterm.tlf "Modificar interfaces")\e[0m"
  echo ""
  echo "Interfaces disponibles"
  echo "----------------------"
  ip a | grep -o "[0-9]: [a-zA-Z0-9]*"
  echo ""
  echo -n "Escriba las interfaces en las que va a actuar el DHCP con un espacio entre las interfaces: "
  read interfaces
  sed -iEr s/INTERFACESv4=".*"/INTERFACESv4='"'"$interfaces"'"'/ /etc/default/isc-dhcp-server
}

limpiar_pool(){
  echo -e "\e[35m$(figlet -f wideterm.tlf "Limpiar pools")\e[0m"
  echo ""
  comprobador=0
  while [[ $comprobador -eq 0 ]];do
    echo -n "¿Esta seguro? Esto borrara el fichero entero (s/n): "
    read sure
    if [[ "$sure" =~ ^(s|S)$ ]]; then
      comprobador=1
      echo "ddns-update-style none;" > /etc/dhcp/dhcpd.conf
      echo "El fichero ha sido limpiado correctamente"
      pasusa
    elif [[ "$sure" =~ ^(n|N)$ ]]; then
      comprobador=1
    else
      echo "Error, intruduzca s (si) o n (no)"
      echo ""
    fi
  done
}

add_pool() {
  echo -e "\e[35m$(figlet -f wideterm.tlf "Añadir nuevo pool")\e[0m"
  echo ""
  echo -n "Introduzca un nombre para el pool: "
  read nombre_pool
  echo -n "Introduzca la red en la que estaran las direcciones del DHCP: "
  read red
  echo -n "Introduzca la mascara de red: "
  read mascara
  echo -n "Introduzca la primera IP que puede otorgar el DHCP: "
  read ip_first
  echo -n "Introduzca la ultima IP que puede otorgar el DHCP: "
  read ip_last
  echo -n "Introduca la puerta de enlace de la red: "
  read gateway
  echo -n "Introduzca la direccion de broadcast: "
  read broadcast
  echo -n "Introduzca el tiempo de concesion de IP: "
  read default_lease
  echo -n "Introduzca el tiempo maximo de concesion de IP: "
  read max_lease
  comprobador=0
  while [[ $comprobador -eq 0 ]];do
    echo -n "¿Quiere añadir servidores DNS? (s/n): "
    read dns
    if [[ "$dns" =~ ^(s|S)$ ]]; then
      comprobador=1
      echo -n "Introduzca las IPs de los servidores DNS (separados por coma y espacio): "
      read dns_ip
      echo -n "Introduzca el nombre de dominio del servidor DNS: "
      read dns_name
    elif [[ "$dns" =~ ^(n|N)$ ]]; then
      comprobador=1
    else
      echo "Error, intruduzca s (si) o n (no)"
      echo ""
    fi
  done
  echo "" >> /etc/dhcp/dhcpd.conf
  echo "#Pool $nombre_pool" >> /etc/dhcp/dhcpd.conf
  echo "subnet $red netmask $mascara {" >> /etc/dhcp/dhcpd.conf
  echo "  range $ip_first $ip_last;" >> /etc/dhcp/dhcpd.conf
  if [[ $dns =~ ^(s|S)$ ]]; then
    echo "  option domain-name-servers $dns_ip;" >> /etc/dhcp/dhcpd.conf
    echo '  option domain-name "'$dns_name'";' >> /etc/dhcp/dhcpd.conf
  fi
  echo "  option routers $gateway;" >> /etc/dhcp/dhcpd.conf
  echo "  option broadcast-address $broadcast;" >> /etc/dhcp/dhcpd.conf
  echo "  default-lease-time $default_lease;" >> /etc/dhcp/dhcpd.conf
  echo "  max-lease-time $max_lease;" >> /etc/dhcp/dhcpd.conf
  echo "}" >> /etc/dhcp/dhcpd.conf
}

add_reserva(){
  echo -e "\e[35m$(figlet -f wideterm.tlf "Añadir nueva reserva")\e[0m"
  echo ""
  echo -n "Introduzca el nombre del equipo para la reserva sin espacios: "
  read nombre_reserva
  echo -n "Introduzca la MAC del equipo de la reserva: "
  read mac
  echo -n "Introduzca la IP o el nombre del equipo de la reserva: "
  read ip
  echo "" >> /etc/dhcp/dhcpd.conf
  echo "#Reserva para el equipo: $nombre_reserva" >> /etc/dhcp/dhcpd.conf
  echo "host $nombre_reserva {" >> /etc/dhcp/dhcpd.conf
  echo "  hardware ethernet $mac;" >> /etc/dhcp/dhcpd.conf
  echo "  fixed-address $ip;" >> /etc/dhcp/dhcpd.conf
  echo "}" >> /etc/dhcp/dhcpd.conf
}

terminar() {
  echo "Aplicando los cambios..."
  systemctl restart isc-dhcp-server.service 2> /dev/null
  if [[ $? -eq 0 ]]; then
    echo "El servidor dhcp ha sido configurado con exito y esta funcionado"
  else
    echo "Algun error impide el funcionamiento del DHCP. Revisa la configuración"
    echo ""
  fi
}
menu_dhcp() {
  comprobador_menu=0
  while [[ $comprobador_menu -eq 0 ]];do
    limpiar
    echo -e  "\e[36m$(figlet -f pagga.tlf -w 200 "Menu de configuracion del DHCP")\e[0m"
    echo ""
    echo "1. Modificar las interfaces en las que va a actuar el DHCP"
    echo "2. Limpiar el fichero de pools del DHCP"
    echo "3. Añadir pool al DHCP"
    echo "4. Añadir reserva al DHCP"
    echo "5. Aplicar los cambios y salir"
    echo ""
    echo -n "Introduzca un numero del menu segun la accion que quiera realizar: "
    read menu
    if [[ "$menu" =~ ^(1)$ ]]; then
      limpiar
      add_interfaces
    elif [[ "$menu" =~ ^(2)$ ]]; then
      limpiar
      limpiar_pool
    elif [[ "$menu" =~ ^(3)$ ]]; then
      limpiar
      add_pool
    elif [[ "$menu" =~ ^(4)$ ]]; then
      limpiar
      add_reserva
    elif [[ "$menu" =~ ^(5)$ ]]; then
      limpiar
      comprobador_menu=1
      terminar
    else
      echo "Error, intruduzca un numero del 1 al 5"
      echo ""
      pausa
    fi
  done
}
#-------------------------------------------------------------------
limpiar 2> /dev/null
root
dhcp_install
instalar_DHCP
binarios_install
instalar_binarios
pausa
menu_dhcp
