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
  comprobador_internet=0
  while [[ $comprobador_internet -eq 0 ]];do
    echo "Comprobando su conexion a internet..."
    ping -c3 8.8.8.8 > /dev/null 2> /dev/null
    if [[ $? -eq 0 ]];then
      echo "Tiene una buena conexion"
      comprobador_internet=1
      return 0
    else
      comprobador=0
      while [[ $comprobador -eq 0 ]];do
        echo -n "Parace que no tiene conxion, ¿Quiere entrar al menu de configuración de interfaces? (s/n): "
        read sure
        if [[ "$sure" =~ ^[sS]$ ]];then
          comprobador=1
	  menu_interfaces
	  limpiar
        elif [[ "$sure" =~ ^[nN]$ ]]; then
          comprobador=1
        else
          echo "Error, intruduzca s (si) o n (no)"
          echo ""
	  comprobador=0
        fi
      done
      comprobador=0
      while [[ $comprobador -eq 0 ]];do
        echo -n "¿Quiere reintentar la conexion? (s/n): "
        read sure
        if [[ "$sure" =~ ^[sS]$ ]]; then
          limpiar
          comprobador=1
        elif [[ "$sure" =~ ^[nN]$ ]]; then
          comprobador=1
          exit 1
        else
          echo "Error, intruduzca s (si) o n (no): "
          echo ""
        fi
      done
    fi
  done
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
}

instalar_binarios() {
  if [[ $? -eq 1 ]];then
    echo ""
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
  wget https://raw.githubusercontent.com/JaviJ27/Scripts-de-linux/refs/heads/main/wideterm.tlf 2> /dev/null > /dev/null
  wget https://raw.githubusercontent.com/JaviJ27/Scripts-de-linux/refs/heads/main/pagga.tlf 2> /dev/null > /dev/null
  mv wideterm.tlf /usr/share/figlet/
  mv pagga.tlf /usr/share/figlet/
}

limpiar_interfaces(){
  echo "limpiando el fichero /etc/network/interfaces..."
  sleep 2
  echo "source /etc/network/interfaces.d/*" > /etc/network/interfaces
  echo "" >> /etc/network/interfaces
  echo "#The loopback network interface" >> /etc/network/interfaces
  echo "auto lo" >> /etc/network/interfaces
  echo "iface lo inet loopback" >> /etc/network/interfaces
  echo "El fichero /etc/network/interfaces se ha limpiado correctamente"
  pausa
}

nueva_interfaz(){
  comprobador=0
  while [[ $comprobador -eq 0 ]];do
    limpiar
    echo "Interfaces disponibles"
    echo "----------------------"
    ip a | grep -o "[0-9]: [a-zA-Z0-9]*"
    echo ""
    echo -n "Introduce la interfaz de red que quiere añadir: "
    read interfaz
    echo ""
    echo -n "¿Obtendra IP de forma estatica o dinamica?: "
    read modo
    echo ""
    if [[ "$modo" =~ ^(dinamica|estatica)$ ]]; then
      echo "" >> /etc/network/interfaces
      if [[ $modo = "dinamica" ]];then
        echo "allow-hotplug $interfaz" >> /etc/network/interfaces
        echo "iface $interfaz inet dhcp" >> /etc/network/interfaces
	echo "Interfaz añadida con exito"
	comprobador=1
	pausa
      elif [[ $modo = "estatica" ]];then
	echo "allow-hotplug $interfaz" >> /etc/network/interfaces
        echo "iface $interfaz inet static" >> /etc/network/interfaces
	echo -n "Introduzca la IP que tendra la interfaz: "
	read ip
	echo ""
	echo -n "Introduzca la mascara de red que tendra su interfaz: "
	read mascara
	echo ""
	echo "  address $ip" >> /etc/network/interfaces
	echo "  netmask $mascara" >> /etc/network/interfaces
	comprobador_gateway=0
	while [[ $comprobador_gateway -eq 0 ]];do
	  echo -n "¿Quiere introducir puerta de enlace? (s/n): "
	  read sure
	  echo ""
	  if [[ "$sure" =~ ^[sS]$ ]]; then
            comprobador_gateway=1
            echo -n "Introduzca la puerta de enlace: "
	    read gateway
	    echo ""
            echo "  gateway $gateway" >> /etc/network/interfaces
          elif [[ "$sure" =~ ^[nN]$ ]]; then
            comprobador_gateway=1
          else
            echo "Error, intruduzca s (si) o n (no)"
            echo ""
          fi
	done
	comprobador_dns=0
	while [[ $comprobador_dns -eq 0 ]];do
	  echo -n "¿Quiere introducir un servidor DNS? (s/n): "
	  read sure
	  if [[ "$sure" =~ ^[sS]$ ]]; then
            comprobador_dns=1
            echo -n "Introduzca la IP del servidor DNS: "
	    read dns
            echo "  dns-nameserver $dns" >> /etc/network/interfaces
            echo ""
  	    echo "Interfaz añadida con exito"
	    comprobador=1
	    pausa
          elif [[ "$sure" =~ ^[nN]$ ]]; then
            comprobador_dns=1
            echo ""
  	    echo "Interfaz añadida con exito"
	    comprobador=1
	    pausa
          else
            echo "Error, intruduzca s (si) o n (no)"
            echo ""
          fi
	done
      fi
    else
      echo "Error, modo no valido, introduzca '"'estatica'"' o '"'dhcp'"'"
      pausa
    fi
  done
}

ver_interfaces(){
  less /etc/network/interfaces
}

aplicar_interfaces() {
  echo "Aplicando los cambios..."
  systemctl restart networking.service 2> /dev/null
  if [[ $? -eq 0 ]]; then
    echo "Las interfaces han sido configuradas con exito y estan funcionado"
    pausa
  else
    echo "Algun error impide el funcionamiento de las interfaces. Revisa la configuración"
    pausa
  fi
}

menu_interfaces(){
  comprobador_menu=0
  while [[ $comprobador_menu -eq 0 ]];do
    limpiar
    if apt policy figlet 2> /dev/null | grep -qoe "(ninguno)";then
    echo "---------------------------------------"
    echo "| Menu de Configuracion de Interfaces |"
    echo "---------------------------------------"
    else
      echo -e  "\e[36m$(figlet -f pagga.tlf -w 200 "Menu de configuracion de interfaces")\e[0m"
    fi
    echo ""
    echo "1. Limpiar fichero de interfaces"
    echo "2. Añadir nueva configuracion de interfaz"
    echo "3. Ver fichero de interfaces"
    echo "4. Ver interfaces disponibes"
    echo "5. Aplicar cambios"
    echo "6. Salir"
    echo ""
    echo -n "Introduzca un numero del menu segun la accion que quiera realizar: "
    read menu
    if [[ "$menu" =~ ^1$ ]]; then
      limpiar
      limpiar_interfaces
    elif [[ "$menu" =~ ^2$ ]]; then
      nueva_interfaz
    elif [[ "$menu" =~ ^3$ ]]; then
      limpiar
      ver_interfaces
    elif [[ "$menu" =~ ^4$ ]]; then
      limpiar
        echo "Interfaces disponibles"
        echo "----------------------"
        ip a | grep -o "[0-9]: [a-zA-Z0-9]*"
        pausa
    elif [[ "$menu" =~ ^5$ ]]; then
      aplicar_interfaces
    elif [[ "$menu" =~ ^6$ ]]; then
      comprobador_menu=1
    else
      echo "Error, intruduzca un numero del 1 al 6"
      echo ""
    fi
  done
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
    if [[ "$sure" =~ ^[sS]$ ]]; then
      comprobador=1
      echo "ddns-update-style none;" > /etc/dhcp/dhcpd.conf
      echo "El fichero ha sido limpiado correctamente"
      pasusa
    elif [[ "$sure" =~ ^[nN]$ ]]; then
      comprobador=1
    else
      echo "Error, intruduzca s (si) o n (no)"
      echo ""
    fi
  done
}

ver_pool(){
  less /etc/dhcp/dhcpd.conf
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
    if [[ "$dns" =~ ^[sS]$ ]]; then
      comprobador=1
      echo -n "Introduzca las IPs de los servidores DNS (separados por coma y espacio): "
      read dns_ip
      echo -n "Introduzca el nombre de dominio del servidor DNS: "
      read dns_name
    elif [[ "$dns" =~ ^[nN]$ ]]; then
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
  if [[ $dns =~ ^[sS]$ ]]; then
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

aplicar_dhcp() {
  echo "Aplicando los cambios..."
  systemctl restart isc-dhcp-server.service 2> /dev/null
  if [[ $? -eq 0 ]]; then
    echo "El servidor dhcp ha sido configurado con exito y esta funcionado"
    pausa
  else
    echo "Algun error impide el funcionamiento del DHCP. Revisa la configuración"
    pausa
  fi
}

menu_dhcp() {
  comprobador_menu=0
  while [[ $comprobador_menu_dhcp -eq 0 ]];do
    limpiar
    echo -e  "\e[36m$(figlet -f pagga.tlf -w 200 "Menu de configuracion del DHCP")\e[0m"
    echo ""
    echo "1. Modificar las interfaces en las que va a actuar el DHCP"
    echo "2. Limpiar el fichero de pools del DHCP"
    echo "3. Añadir pool al DHCP"
    echo "4. Añadir reserva al DHCP"
    echo "5. Ver fichero de pools"
    echo "6. Entrar al menu de configuración de interfaces"
    echo "7. Aplicar los cambios"
    echo "8. Salir"
    echo ""
    echo -n "Introduzca un numero del menu segun la accion que quiera realizar: "
    read menu
    if [[ "$menu" =~ ^1$ ]]; then
      limpiar
      add_interfaces
    elif [[ "$menu" =~ ^2$ ]]; then
      limpiar
      limpiar_pool
    elif [[ "$menu" =~ ^3$ ]]; then
      limpiar
      add_pool
    elif [[ "$menu" =~ ^4$ ]]; then
      limpiar
      add_reserva
    elif [[ "$menu" =~ ^5$ ]]; then
      limpiar
      ver_pool
    elif [[ "$menu" =~ ^6$ ]]; then
      menu_interfaces
    elif [[ "$menu" =~ ^7$ ]]; then
      limpiar
      aplicar_dhcp
    elif [[ "$menu" =~ ^8$ ]]; then
      comprobador_menu_dhcp=1
    else
      echo "Error, intruduzca un numero del 1 al 8"
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
