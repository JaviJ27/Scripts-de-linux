#!/usr/bin/bash
FECHA_HOY=$(date +%F)
FECHA_AYER=$(date -d "yesterday" +%F)

limpiar(){
  clear
  echo "--------------------------------------"
  echo "| Restaurador de copias de seguridad |"
  echo "--------------------------------------"
  echo ""
}

pausa(){
  echo ""
  echo -n "Pulse enter para continuar"
  read space
}

root() {
  echo "Comprobando que usted tenga permisos de administrador..."
  sleep 2
  check_root=$(id -u)
  if [[ $check_root -eq 0 ]];then
    echo "Usted es ROOT"
    return 0
  else
    echo "Usted no es ROOT, así que no puede ejecutar ese scipt"
    exit 1
  fi
}

pv_check_install() {
  echo ""
  echo "Comprobando que pv este instalado..."
  if apt policy pv 2>/dev/null | egrep -qoe "\(ninguno\)|\(none\)"; then
    echo "El comando pv no esta instalado"
    pv_check_install=1
  else
    echo "El comando pv esta instalado"
    return 0
  fi
}

rsync_check_install() {
  echo ""
  echo "Comprobando que rsync este instalado..."
  if apt policy rsync 2>/dev/null | egrep -qoe "\(ninguno\)|\(none\)"; then
    echo "El comando rsync no esta instalado" > /var/log/copia-$FECHA_HOY
    rsync_check_install=1
  else
    echo "El comando rsync esta instalado" > /var/log/copia-$FECHA_HOY
    return 0
  fi
}

conexion() {
  echo ""
  echo "Comprobando que tenga conexión a internet..."
  ping 8.8.8.8 -c 3 >/dev/null 2>/dev/null
  if [[ $? -eq 0 ]];then
    echo "Usted tiene conexión"
  else
    echo "Usted no tiene conexión, intentelo de nuevo mas tarde"
    exit 2
  fi
}

pv_install() {
  echo ""
  echo "Instalando pv..."
  apt install pv >/dev/null 2>/dev/null
  if [[ $? -eq 0 ]];then
    echo "¡pv se ha instalado con exito!"
  else
    echo "Ha ocurrido un problema, rsync no se ha podido instalar"
    exit 3
  fi
}

rsync_install() {
  echo ""
  echo "Instalando rsync..."
  apt install rsync >/dev/null 2>/dev/null
  if [[ $? -eq 0 ]];then
    echo "¡rsync se ha instalado con exito!" >> /var/log/copia-$FECHA_HOY
  else
    echo "Ha ocurrido un problema, rsync no se ha podido instalar" >> /var/log/copia-$FECHA_HOY
    exit 3
  fi
}

preguntar_copia() {
  CHECK_WHILE=0
  while [ $CHECK_WHILE -eq 0 ]; do
    limpiar
    echo -n "Ingrese la fecha de la copia que quiere restaurar en formato AAAA-MM-DD: "
    read FECHA_COPIA
    if [[ $FECHA_COPIA =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]];then
      CHECK_WHILE=1
    else
      echo "El formato de la fecha no es valido, por favor introduzca una fecha valida"
      pausa
    fi
  done

  EXIST_COPIA=$(find /mnt/backup -maxdepth 1 -name "*$FECHA_COPIA*")

  if [[ -z $EXIST_COPIA ]];then
    echo "No se ha encontrado ninguna copia de seguridad en esta fecha"
    exit 4
  fi
}

check_copia() {
  echo ""
  echo "Comprobando de que tipo es la copia..."
  sleep 2
  TIPO_COPIA=$(basename "$EXIST_COPIA" | cut -d'-' -f1)
}

restaurar_copia() {
  NOMBRE_COPIA=$(basename $EXIST_COPIA)
  if [[ $TIPO_COPIA = "completa" ]];then
    echo "Es una copia completa"
    echo ""
    echo "Se dispone a restaurar la copia \"$NOMBRE_COPIA\". Esto borrara todos los datos actuales y restaurara los datos del $FECHA_COPIA."
    CHECK_SURE=0
    while [[ $CHECK_SURE -eq 0 ]];do
      echo -n "¿Desea continuar? (S/N): "
      read sure
      if [[ "$sure" =~ ^[sS]$ ]]; then
        CHECK_SURE=1
      elif [[ "$sure" =~ ^[nN]$ ]]; then
        CHECK_SURE=1
        exit 5
      else
        echo "Error, intruduzca s (si) o n (no): "
        echo ""
      fi
    done
    limpiar
    rm -r /mnt/restore/etc /mnt/restore/var /mnt/restore/home /mnt/restore/root /mnt/restore/usr/local /mnt/restore/opt /mnt/restore/srv /mnt/restore/boot 2>/dev/null
    echo "Restaurando copia de seguridad \"$NOMBRE_COPIA\" al directorio temporal..."
    SIZE=$(du -sb /mnt/backup/$NOMBRE_COPIA | awk '{print $1}')
    pv -s $SIZE /mnt/backup/$NOMBRE_COPIA | tar -xz -C /mnt/restore_tmp/
    echo ""
    echo "Restaurando copia \"$NOMBRE_COPIA\""
    rsync -ar --delete --info=progress2 /mnt/restore_tmp/* /mnt/restore/
    rm -rf /mnt/restore_tmp/*
    echo ""
    echo "El sistema ha sido restaurado a su estado el dia $FECHA_COPIA."
  elif [[ $TIPO_COPIA = "incremental" ]];then
    echo "Es una copia incremental"
    CHECK_FECHA=$FECHA_COPIA
    CHECK_WHILE=0
    DIAS_ATRAS=0
    while [ $CHECK_WHILE -eq 0 ];do
      ls /mnt/backup/completa-$CHECK_FECHA.tar.gz >/dev/null 2>/dev/null
      CHECK_LS=$?
      if [[ $CHECK_LS -ne 0 ]];then
        CHECK_FECHA=$(date -d "$CHECK_FECHA -1 day" +%Y-%m-%d)
        ((DIAS_ATRAS++))
      elif [[ $CHECK_LS -eq 0 ]];then
        COPIA_COMPLETA=$(ls /mnt/backup/completa-$CHECK_FECHA.tar.gz)
        CHECK_WHILE=1
      fi
    done
    echo ""
    echo "Se dispone a restaurar la copia \"$NOMBRE_COPIA\". Esto borrara todos los datos actuales y restaurara los datos del $FECHA_COPIA."
    CHECK_SURE=0
    while [[ $CHECK_SURE -eq 0 ]];do
      echo -n "¿Desea continuar? (S/N): "
      read sure
      if [[ "$sure" =~ ^[sS]$ ]]; then
        CHECK_SURE=1
      elif [[ "$sure" =~ ^[nN]$ ]]; then
        CHECK_SURE=1
        exit 5
      else
        echo "Error, intruduzca s (si) o n (no): "
        echo ""
      fi
    done
    NOMBRE_COPIA=$(basename $COPIA_COMPLETA)
    limpiar
    rm -r /mnt/restore/etc /mnt/restore/var /mnt/restore/home /mnt/restore/root /mnt/restore/usr/local /mnt/restore/opt /mnt/restore/srv /mnt/restore/boot 2>/dev/null
    echo "Restaurando copia de seguridad completa \"$NOMBRE_COPIA\" al directorio temporal..."
    SIZE=$(du -sb $COPIA_COMPLETA | awk '{print $1}')
    pv -s $SIZE $COPIA_COMPLETA | tar -xz -C /mnt/restore_tmp/
    echo ""
    echo "Restaruando copia \"$NOMBRE_COPIA\""
    rsync -ar --delete --info=progress2 /mnt/restore_tmp/* /mnt/restore/
    rm -rf /mnt/restore_tmp/*
    CHECK_FECHA=$(date -d "$CHECK_FECHA +1 day" +%Y-%m-%d)
    for i in $(seq 1 "$DIAS_ATRAS");do
      NOMBRE_COPIA=$(basename $(find /mnt/backup -maxdepth 1 -name "*$CHECK_FECHA*"))
      echo ""
      echo "Restaruando copia \"$NOMBRE_COPIA\""
      rsync -ar --delete --info=progress2 /mnt/backup/*$CHECK_FECHA/* /mnt/restore/
      CHECK_FECHA=$(date -d "$CHECK_FECHA +1 day" +%Y-%m-%d)
    done
    echo ""
    echo "El sistema ha sido restaurado a su estado el dia $FECHA_COPIA."
  fi
}

#----------------------------------------------------------------------------

pv_check_install
if [[ $pv_check_install -eq 1 || $rsync_check_install -eq 1 ]];then
  conexion
fi
if [[ $pv_check_install -eq 1 ]];then
  pv_install
fi
if [[ $rsync_check_install -eq 1 ]];then
  rsync_install
fi
preguntar_copia
check_copia
restaurar_copia
