# Uso

Para ejecutar el proyecto es requerido tener, archivos de docker, en este caso se precisa
un directorio `src` que contenga los archivos de docker en `dockers` y el ejecutable `docker-compose.yml` asi como el env si se precisa.


Comencemos configurando el Entorno, para eso generemos `shell` que contendra el codigo para hacer ReverseShell de **Worker** y **Master**, **Master** se conectara a **Worker** luego de iniciar ``master.sh`, y **Worker** siempre se mantendra en escucha al ejecutar shell y darle permisos.

```bash
gcc shell.c -o shell

```
se generara un binario que se le debe enviar al Worker para configurar su maquina.

En **Worker**, ejecutamos la configuracion
```bash
chmod +x shell

./shell "10.11.13.2" "9001"

```
- Primer Argumento: Es la Ip del **Master**, es necesario para solo autorizar a **Master** acceder al *ReverseShell*
- Segundo Argumento: Es el puerto al que escuchara, es su posicion como worker.

Luego de esto nos olvidamos de Worker, ya que master se encargara de configurar su entorno.


Ahora controlamos con **Master** a **Worker**, debemos agregarle los contenedores que se distribuiran a los distintos **Workers** configurados

```bash

chmod +x master.sh

./master.sh c1="frontend"
```
Ejemplo de parametros
- c1="frontend": El primer worker que se conecte al puerto 9001 se ejecutara el contenedor backend.
- c2=backend": El primer worker que se conecte al puerto 9002 se ejecutara el contenedor backend

Si todo esta bien configurado ahora podemos esperar y ver los logs para conocer si se esta ejecutando el contenedor distribuido


## Consideraciones

1. En caso de que los **Workers** sean 1 y 2  y se enviaron c1, c2 y c3 a `master.sh` es posible que se quede esperando, *hay que arreglar esto y hacer que los contenedores se agregen a master luego de tres intentos de busqueda del tercer worker*

2. En caso que no haya **Workers**, `master.sh` deberia ejecutar todos los contenedores en su maquina. *No se implemento*

3. En caso de que caiga un contenedor en **Worker**, master deberia enviar ese contenedor al **Worker** mas cercano o directamente al **Master**.

