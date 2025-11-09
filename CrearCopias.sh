#!/usr/bin/bash
FECHA_HOY=$(date +%F)
FECHA_AYER=$(date -d "yesterday" +%F)

rsync_check_install() {
  if apt policy rsync 2>/dev/null | egrep -qoe "\(ninguno\)|\(none\)"; then
    echo "El comando rsync no esta instalado" > /var/log/copia-$FECHA_HOY
    rsync_check_install=1
  else
    echo "El comando rsync esta instalado" > /var/log/copia-$FECHA_HOY
    return 0
  fi
}

conexion() {
  ping 8.8.8.8 -c 3 >/dev/null 2>/dev/null
  if [[ $? -eq 0 ]];then
    echo "La prueba de conexion ha funcionado correctamente" >> /var/log/copia-$FECHA_HOY
  else
    echo "La prueba de conexion ha fallado, compruebe su conexion" >> /var/log/copia-$FECHA_HOY
    exit 2
  fi
}

rsync_install() {
  apt install rsync >/dev/null 2>/dev/null
  if [[ $? -eq 0 ]];then
    echo "¡rsync se ha instalado con exito!" >> /var/log/copia-$FECHA_HOY
  else
    echo "Ha ocurrido un problema, rsync no se ha podido instalar" >> /var/log/copia-$FECHA_HOY
    exit 3
  fi
}

copia_rsync() {
  DIRECTORIOS="/etc /var /home /root /usr/local /opt /srv /boot"
  ULTIMA_COMPLETA=$(ls -1d /mnt/backup/completa-*.tar.gz 2>/dev/null | sort -r | head -n1)
  FECHA_ULTIMA=$(basename "$ULTIMA_COMPLETA" | cut -d'-' -f2- | cut -d'.' -f1)
  if [[ -z $ULTIMA_COMPLETA ]];then
    DIAS_DESDE_COMPLETA=7
    TEXTO_COMPLETA="Esta es la primera copia de seguridad del sistema por lo que se hara una copia compeleta"
  else
    DIAS_DESDE_COMPLETA=$((( $(date -d "$FECHA_HOY" +%s) - $(date -d "$FECHA_ULTIMA" +%s) ) / 86400 ))
    TEXTO_COMPLETA="La ultima copia completa se realizo hace 7 dias por lo que hoy se hara otra copia completa"
  fi

  if [[ $DIAS_DESDE_COMPLETA -eq 7 ]];then
    echo $TEXTO_COMPLETA >> /var/log/copia-$FECHA_HOY
    rsync -ar --info=progress2 --delete $DIRECTORIOS /mnt/backup/completa-$FECHA_HOY 2>>/var/log/copia-$FECHA_HOY
    echo "Archivos copiados" >> /var/log/copia-$FECHA_HOY
    tar -C /mnt/backup/completa-$FECHA_HOY -cf - $DIRECTORIOS | gzip > /mnt/backup/completa-$FECHA_HOY.tar.gz 2>>/var/log/copia-$FECHA_HOY
    echo "Archivos comprimidos" >> /var/log/copia-$FECHA_HOY
  elif [[ $DIAS_DESDE_COMPLETA -eq 0 ]];then
    echo "La ultima copia completa se realizo hoy por lo que no se realizaran copias" >> /var/log/copia-$FECHA_HOY
  elif [[ $DIAS_DESDE_COMPLETA -eq 1 ]];then
    echo "La ultima copia completa se realizo hace 1 dia por lo que hoy se hara una copia incremental" >> /var/log/copia-$FECHA_HOY
    rsync -ar --info=progress2 --delete --link-dest=/mnt/backup/completa-$FECHA_ULTIMA/ $DIRECTORIOS /mnt/backup/incremental-$FECHA_HOY 2>>/var/log/copia-$FECHA_HOY
    rm -r /mnt/backup/completa-$FECHA_ULTIMA 2>/dev/null
    echo "Archivos copiados" >> /var/log/copia-$FECHA_HOY
  elif [[ $DIAS_DESDE_COMPLETA -gt 1 && $DIAS_DESDE_COMPLETA -lt 7 ]];then
    echo "La ultima copia completa se realizo hace $DIAS_DESDE_COMPLETA dias por lo que hoy se hara una copia incremental" >> /var/log/copia-$FECHA_HOY
    rsync -ar --info=progress2 --delete --link-dest=/mnt/backup/incremental-$FECHA_AYER/ $DIRECTORIOS /mnt/backup/incremental-$FECHA_HOY 2>>/var/log/copia-$FECHA_HOY
    echo "Archivos copiados" >> /var/log/copia-$FECHA_HOY
  fi
}

remove_files() {
  MONT=$(date -d "-30 day" +%Y-%m-%d)
  find /mnt/backup/incremental* -maxdepth 0 ! -newermt $MONT -delete
}
#----------------------------------------------------------------------------

rsync_check_install
if [[ $rsync_check_install -eq 1 ]];then
  conexion
  rsync_install
fi
copia_rsync
remove_files
