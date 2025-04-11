#!/bin/bash
limpiar(){
  clear
  if apt policy figlet 2> /dev/null | grep -qoe "(ninguno)" || apt policy lolcat 2> /dev/null | grep -qoe "(ninguno)"; then
    echo "------------------------------"
    echo "| Creador de 128 particiones |"
    echo "------------------------------"
    echo ""
  else
    figlet -f big -w 200 "Creador de 128 particiones" | /usr/games/lolcat
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
    echo "Tiene una buena conexion"
    return 0
  else
    echo "Parace que no tiene conxion, compruebe su conexion o intentelo mas tarde"
    exit 1
  fi
}

actualizar() {
  echo ""
  echo "Buscando actualizaciones..."
  echo ""
  apt update -y > /dev/null 2> /dev/null
  echo "Actualizando el sistema..."
  echo ""
  apt upgrade -y > /dev/null 2> /dev/null 
}

fdisk_install() {
  echo ""
  echo "Comprobando si tiene fdisk instalado..."
  sleep 2
  if apt policy fdisk 2> /dev/null | grep -qoe "(ninguno)"; then
    echo "fdisk no esta instalado, a si que vamos a intentar instalarlo"
    return 1
  else
    echo "fdisk esta instalado"
    return 0
  fi
}

instalar_fdisk() {
  if [[ $? -eq 1 ]];then
    echo ""
    echo "Comprobando su conexion a internet..."
    sleep 2
    conexion
    if [[ $? -eq 0 ]];then
      actualizar
      echo "Instalando fdisk..."
      apt install -y isc-dhcp-server > /dev/null 2> /dev/null
      if [[ $? -eq 0 ]];then
        echo "fdisk se a instalado con exito"
      else
        echo "Ha ocurrido un error al intentar descargar fdisk"
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
  wget https://raw.githubusercontent.com/JaviJ27/Scripts-de-linux/refs/heads/main/wideterm.tlf 2> /dev/null > /dev/null
  wget https://raw.githubusercontent.com/JaviJ27/Scripts-de-linux/refs/heads/main/pagga.tlf 2> /dev/null > /dev/null
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
      actualizar
      echo "Instalando los paquete necesarios..."
      apt install -y figlet > /dev/null 2> /dev/null && apt install -y lolcat > /dev/null 2> /dev/null
      if [[ $? -eq 0 ]];then
        echo "Todos los paquetes se han instalado con exito"
      else
        echo "Ha ocurrido un error al intentar descargar los paquetes necesarios"
        exit 1
      fi
    fi
  fi
}

comprobar_gpt(){
    local tipo=$(fdisk -l /dev/sda | grep "Tipo de etiqueta" | awk '{print $NF}')
    if [[ $tipo = "dos" ]]; then
        echo "Este disco $disco está en MBR"
        echo "Para ejecutar el script es necesario pasarlo a GPT"
    else
        echo "El disco $disco está en GPT"
    fi
}

select_disco() {
  comprobador_disco=0
  while [[ $comprobador_disco -eq 0 ]];do
    limpiar
    echo ""
    echo -e "\e[35m$(figlet -f wideterm.tlf "Selecciar el disco que se va a particionar")\e[0m"
    echo ""
    echo "Los discos disponibles son los siguientes:"
    echo "------------------------------------------"
    lsblk | egrep "(^vd|^sd|^nvme)" | awk '{print $1}'
    echo ""
    echo -n "Seleccione el disco donde se van a realizar las particiones: "
    read disco
    echo -e "q" | fdisk /dev/$disco > /dev/null 2> /dev/null
    if [[ $? -eq 0 ]];then
      comprobador=0
      while [[ $comprobador -eq 0 ]];do
	limpiar
	echo -e "\e[35m$(figlet -f wideterm.tlf "Selecciar el disco que se va a particionar")\e[0m"
	echo""
	echo "Estas son las particiones de $disco:"
	echo "---------------------------------------------"
	echo -e "\e[1m$(lsblk | grep NAME)\e[0m"
	lsblk | grep $disco
        echo ""
	comprobar_gpt
        echo -n "El progama borrara toda la informacion del disco $disco, lo pasara a GPT en caso de no estarlo y creara 128 particiones en. ¿Quiere continuar? (s/n): "
        read sure
        if [[ "$sure" =~ ^[sS]$ ]]; then
          comprobador=1
          comprobador_disco=1
        elif [[ "$sure" =~ ^[nN]$ ]]; then
          echo ""
          echo -n "¿Quiere seleccionar otro disco? (s/n): "
	  read sure
          if [[ "$sure" =~ ^[sS]$ ]]; then
            comprobador=1
          elif [[ "$sure" =~ ^[nN]$ ]]; then
            comprobador=1
	    comprobador_disco=1
	    exit 1
          else
            echo "Error, intruduzca s (si) o n (no)"
            echo ""
          fi
        else
          echo "Error, intruduzca s (si) o n (no)"
          echo ""
        fi
      done
    else
      echo ""
      echo "Error, el disco introducido no es correcto"
      pausa
    fi
  done
}

particionado(){
  limpiar
  echo -e "\e[35m$(figlet -f wideterm.tlf "Particionado del disco")\e[0m"
  echo ""
  echo "Limpiando disco..."
  sleep 2
  wipefs -a /dev/$disco > /dev/null
  echo -e "g\nw" | fdisk /dev/sdb > /dev/null
  echo "Creando particiones..."
  for ((i=1;i<=128;i+=1))
    do
      echo -e "n\n$i\n\n+1K\nw" | fdisk /dev/sdb 2> /dev/null
  done
  if [[ $? -eq 0 ]];then
    echo ""
    echo "Las particiones han sido creadas con exito"
  else
    echo ""
    echo "Ha ocurrido un error al crear las particiones"
  fi
}

#-------------------------------------------------------------------

limpiar
root
fdisk_install
instalar_fdisk
binarios_install
instalar_binarios
pausa
select_disco
particionado
