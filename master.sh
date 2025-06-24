#!/bin/bash

#Todo: Problematica: Como podemos conectarnos a los Workers distribuidos, desde Nginx. y solo tener acceso a ellos.

declare -A ips
declare -A containers
all_ips=""
for arg in "$@"; do
  case $arg in
    c*)
      key="${arg%%=*}"          # extrae 'c1', 'c2', etc
      value="${arg#*=}"
      containers[$key]="$value"
      ;;
  esac
done

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
RESET="\033[0m" #

PID=$(lsof -i :8000 -t)
if [ -n "$PID" ]; then
    echo "Matar el proceso con PID: $PID"
    kill -9 $PID
else
    echo "No se encontró ningún proceso utilizando el puerto 8000"
fi


#COmprimo lo que voy a enviar
LOCAL_IP=$(ip addr show enp4s0f0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)

tar -czf dockers.tar.gz src/dockers src/docker-compose.yml src/.env
#Abro un servicio que envia el archivo
echo "0.0.0.0"
NODE_SRV=$!



SLEEP_TIME=3
for key in "${!containers[@]}"; do
  index="${key//c/}"
  container="${containers[c$index]}"

  echo -n "nc escuchando: "
  echo 900"$index"
  PID_NC=$(lsof -i :900"$index" -t)
  if [ -n "$PID_NC" ]; then
      echo "Matar el proceso con PID: $PID_NC"
      kill -9 $PID_NC
  else
      echo "No se encontró ningún proceso utilizando el puerto 900"$index""
  fi

  echo "" > input-wrk[$key]
  echo "" > tmp
  # Ejecutar nc con entrada de tail y salida a tee que escribe en output
  tail -f "input-wrk[$key]" | nc -lnv 900"$index" 2> tmp | tee "output-wrk[$key]" &
  NC_PID=$!
  #Capturamos LA IP QUE SE CONECTO A LA SESION,
  while true; do
    line=$(tail -n 1 tmp)
    if [[ $line == *"Connection received"* ]]; then
      ip=$(echo "$line" | awk '{print $4}')
      ips[$index]=$ip
      echo "IP guardada para $key: ${ips[$index]}"
      break
    fi
  done
  echo "IP: $ip";
  #Agregamos las IPS permitidas para el servidor de descarga
  all_ips+="$ip "

done

echo "all_ips: $all_ips";
node server.js $all_ips $LOCAL_IP &

sleep 2

for key in "${!containers[@]}"; do
  index="${key//c/}"
  ip="${ips[$index]}"
  container="${containers[c$index]}"
  WORKER="ip=\"$ip\" c=\"$container\""
  echo -e "${GREEN}$WORKER${RESET}"
  CMD="{ wget -q --server-response http://$LOCAL_IP:8000/worker.sh -O worker.sh && chmod +x worker.sh &&  ./worker.sh "$WORKER" IPS="$LOCAL_IP" } > logs 2>&1 &"
  # Ejecuta el comando en el Worker
  echo "$CMD" > "input-wrk[$key]" #SI le agrego un & a CMD lo dejo en segundo plano y puedo seguir ejecutando cosas. de todas formas finalizara su proceso enviandome su ultimo estado.

  echo -e "${BLUE}El PID de nc es: $NC_PID${RESET}"
done




#Escuchamos constantemente a los Workers conectados

#Todo: en caso de que un Worker muera debemos quitarlo de la red.
while true; do
    # Listar todas las IPs y contenedores ordenados por índice
    for key in "${!containers[@]}"; do
      index="${key//c/}"
      ip="${ips[$index]}"
      container="${containers[c$index]}"

      # Ejecuta el comando y recibe la salida

      # Guardamos la salida en RESPONSE
      RESPONSE=$( echo "tail -n 1 logs" >> "input-wrk[$key]" && tail -n 1 "output-wrk[$key]")
      
      # Colorear la salida según el contenido
      if [[ "$RESPONSE" == "200 OK" ]]; then
        echo -e "${GREEN}$RESPONSE${RESET}"  # 200 OK en verde
      elif [[ "$RESPONSE" == "403 OK" ]]; then
        echo -e "${GREEN}$RESPONSE${RESET}"  # 200 OK en verde
        kill $NODE_SRV;
        exit
      elif [[ "$RESPONSE" == "Started" ]]; then
        echo -e "${BLUE}$RESPONSE${RESET}"  # Started en azul
        echo -e "${YELLOW}Estado 'Started' recibido. Saliendo del bucle...${RESET}"
        break # Salir del bucle exterior
      elif [[ "$RESPONSE" == "EXIT" ]]; then
        echo "Finalizo la creacion de contenedores"  # 200 OK en verde
        echo "cd src && docker compose logs $container" >> "input-wrk[$key]" 
      elif [[ "$RESPONSE" =~ "Started" || "$RESPONSE" =~ "Running" ]]; then
        echo "✅ El cliente:$ip ejecutó $container con éxito"
      else
        echo -ne "$ip: $RESPONSE\r"  # 200 OK en verde
      fi
      sleep 2;
    done


done
echo -e "Saliendo"



PID=$(lsof -i :8000 -t)
PID_NC=$(lsof -i :9001 -t)
if [ -n "$PID" ]; then
    echo "Matar el proceso con PID: $PID"
    kill -9 $PID
else
    echo "No se encontró ningún proceso utilizando el puerto 8000"
fi
if [ -n "$PID_NC" ]; then
    echo "Matar el proceso con PID: $PID_NC"
    kill -9 $PID_NC
else
    echo "No se encontró ningún proceso utilizando el puerto 9001"
fi