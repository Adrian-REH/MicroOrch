#!/bin/bash
for arg in "$@"; do
  case $arg in
    ip=*)
      IP="${arg#*=}"
      ;;
    c=*)
      CONTAINERS="${arg#*=}"
      ;;
    IPS=*)
      IPS="${arg#*=}"
      ;;
  esac
done
# Lista blanca de IPs permitidas (pueden ser varias)
ALLOWED_IPS=("$IP")

# Obtener IP local: (ejemplo con ifconfig y grep)
# Ajusta la interfaz si sabes cuál usar, por ejemplo eth0 o enp0s3
LOCAL_IP=$(ip addr show enp4s0f0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)

# Alternativa con ip (más moderna)
# LOCAL_IP=$(ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | head -n1)

echo "IP local detectada: $LOCAL_IP"

# Verificar si IP está en la lista blanca
IP_ALLOWED=false
for ip in "${ALLOWED_IPS[@]}"; do
  if [[ "$LOCAL_IP" == "$ip" ]]; then
    IP_ALLOWED=true
    break
  fi
done

if [ "$IP_ALLOWED" = true ]; then
  echo "IP permitida. Ejecutando comando..."
  
  # Aquí pones tu comando real, por ejemplo:
  wget -q --server-response http://$IPS:8000/dockers.tar.gz -O dockers.tar.gz && tar -xzf dockers.tar.gz
  
  cd src
  echo "Ejecutando contenedor..."
  docker compose build $CONTAINERS
  docker compose up $CONTAINERS 

  echo "EXIT"
  exit
  
else
  echo "❌ IP $LOCAL_IP :$ALLOWED_IPSno está en la lista de permitidas. Abortando."
  exit 1
fi
