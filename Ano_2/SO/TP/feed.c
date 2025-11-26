#include "feed.h"

int main(int argc, char *argv[]) {
    int fd, r;
    pedido p = {0};
    resposta res = {0};
    char fifo_cli[TAM] = {0}, str[400] = {0};
    int fd_cli, n;
    fd_set fds;

    if (argc != 2) {
        fprintf(stderr, "Falta parametros! Exemplo: ./feed <nome>\n");
        return -1;
    }

    if (!verificar_fifo_servidor(FIFO_SRV)) {
        fprintf(stderr, "N\u00e3o existe servidor!\n");
        return 1;
    }

    fd = conectar_servidor(FIFO_SRV);
    if (fd == -1) {
        return 1;
    }

    if (!criar_fifo_cliente(fifo_cli, sizeof(fifo_cli))) {
        close(fd);
        return 1;
    }

    fd_cli = abrir_fifo_cliente(fifo_cli);
    if (fd_cli == -1) {
        unlink(fifo_cli);
        close(fd);
        return 1;
    }


    // Realizar login
    strncpy(str, argv[1], sizeof(str) - 1);
    realizar_login(fd, fd_cli, str, fifo_cli);
    p.pid = getpid();
    strncpy(p.nome, argv[1], sizeof(p.nome) - 1);
    // Loop principal
    do {
        FD_ZERO(&fds);
        FD_SET(0, &fds);
        FD_SET(fd_cli, &fds);
        fflush(stdin);
        n = select(fd_cli + 1, &fds, NULL, NULL, NULL);
        if (n == -1) {
            perror("[ERRO] select");
            break;
        }

        if (FD_ISSET(0, &fds)) {
            // Ler entrada do usuário
            if (fgets(str, sizeof(str), stdin) != NULL) {
                str[strcspn(str, "\n")] = '\0';

                if(strcmp(str , "") == 0) continue;
                char cmd1[20] = {0}, cmd2[400] = {0};
                sscanf(str, "%19s %399[^\n]",cmd1, cmd2);

                // Interpretar comandos
                if (strcmp(cmd1, "exit") == 0) {
                    strcpy(p.type, TYPE_LOGOUT);
                } else if (strcmp(cmd1, "topics") == 0) {
                    strcpy(p.type, TYPE_SHOWTOPICS);
                } else if (strcmp(cmd1, "subscribe") == 0) {
                    strncpy(p.str, cmd2, sizeof(p.str) - 1);
                    strcpy(p.type, TYPE_SUBSCRIBETOPIC);
                } else if (strcmp(cmd1, "unsubscribe") == 0) {
                    strncpy(p.str, cmd2, sizeof(p.str) - 1);
                    strcpy(p.type, TYPE_UNSUBSCRIBETOPIC);
                } else if (strcmp(cmd1, "msg") == 0) {
                    strncpy(p.str, cmd2, sizeof(p.str) - 1);
                    strcpy(p.type, TYPE_MESSAGE);
                }else{
                    printf("[COMANDO INVALIDO]\n");
                    strcpy(p.type, "");
                    strcpy(p.str, "");
                }

                // Enviar pedido ao servidor
                r = write(fd, &p, sizeof(p));
                if (r != sizeof(p)) {
                    fprintf(stderr, "[ERRO] Falha ao enviar pedido\n");
                } /*else {
                    printf("[ENVIEI] (%d bytes)\n", (int)strlen(p.str));
                }*/
            }


        }

        if (FD_ISSET(fd_cli, &fds)) {
            r = read(fd_cli, &res, sizeof(res));
            if (r == sizeof(res)) {
                if (strcmp(res.type, TYPE_LOGOUT) == 0) {
                    printf("\n%s\n", res.res);
                    break; // Encerrar cliente
                } else {
                    printf("%s\n", res.res);
                }
            }
        }
    } while (1);

    // Limpeza final
    printf("CLIENTE SAIU\n");
    close(fd_cli);
    unlink(fifo_cli);
    close(fd);
    return 0;
}
