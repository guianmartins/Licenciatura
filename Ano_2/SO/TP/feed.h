#include "util.h"


int verificar_fifo_servidor(const char *fifo_srv) {
    if (access(fifo_srv, F_OK) == -1) {
        return 0;
    }
    return 1;
}

int conectar_servidor(const char *fifo_srv) {
    int fd = open(fifo_srv, O_WRONLY);
    if (fd == -1) {
        perror("Erro ao abrir FIFO do servidor");
        return -1;
    }
    printf("Conectado ao servidor (fd = %d)\n", fd);
    return fd;
}

int criar_fifo_cliente(char *fifo_cli, size_t tamanho) {
    snprintf(fifo_cli, tamanho, FIFO_CLI, getpid());
    if (mkfifo(fifo_cli, 0600) == -1) {
        perror("Erro ao criar FIFO do cliente");
        return 0;
    }
    printf("FIFO do cliente: %s\n", fifo_cli);
    return 1;
}

int abrir_fifo_cliente(const char *fifo_cli) {
    int fd_cli = open(fifo_cli, O_RDWR);
    if (fd_cli == -1) {
        perror("Erro ao abrir FIFO do cliente");
        return -1;
    }
    printf("FIFO aberto: %s\n", fifo_cli);
    return fd_cli;
}

void enviar_pedido(int fd, pedido *p) {
    printf("pid: %d type: %s\n" , p->pid , p->type);
    int r = write(fd, p, sizeof(*p));
    if (r != sizeof(*p)) {
        fprintf(stderr, "Erro ao enviar para o servidor\n");
        exit(1);
    }
}

// Função para ler resposta do servidor
void ler_resposta(int fd_cli, resposta *res) {
    int r = read(fd_cli, res, sizeof(*res));
    if (r != sizeof(*res)) {
        fprintf(stderr, "Erro ao ler resposta do servidor\n");
        exit(1);
    }
}


void realizar_login(int fd, int fd_cli, const char *nome, const char *fifo_cli) {
    // Criar e enviar o pedido de login
    pedido p = { .pid = getpid(), .type = TYPE_LOGIN };
    strcpy(p.nome, nome);
    enviar_pedido(fd, &p);

    // Ler a resposta do servidor
    resposta res;
    ler_resposta(fd_cli, &res);

    // Verificar a resposta
    if (strcmp(res.type, TYPE_LOGOUT) == 0) {
        fprintf(stderr, "Erro: %s\n", res.res);
        close(fd_cli);
        unlink(fifo_cli);
        exit(1);
    }

    printf("Login realizado com sucesso! Bem-vindo, %s.\n", nome);
}
