#include "util.h"


void construir_fifo_cliente(char *fifo, int pid) {
    sprintf(fifo, FIFO_CLI, pid);
}

int abrir_fifo_cliente(char *fifo) {
    if (access(fifo, F_OK) != 0) {
        fprintf(stderr, "FIFO do cliente %s não existe mais\n", fifo);
        return -1;
    }

    int fd = open(fifo, O_WRONLY);
    if (fd == -1) {
        fprintf(stderr, "Falha ao abrir FIFO do cliente %s para escrita!\n", fifo);
    }
    return fd;
}

int enviar_resposta(char *fifo, resposta *resp) {
    int fd = abrir_fifo_cliente(fifo);
    if (fd == -1) {
        return -1;
    }

    int r = write(fd, resp, sizeof(resposta));
    if (r != sizeof(resposta)) {
        fprintf(stderr, "Erro ao enviar resposta para o cliente\n");
    }
    close(fd);
    return r;
}
void mostrar_users(pedido *users, int conta_users) {
    if(conta_users > 0){
        printf("Utilizadores Online:\n");
        for (int i = 0; i < conta_users; i++) {
            printf("\t(NOME) %s  , (NºPROCESSO) %d \n", users[i].nome, users[i].pid);
        }
    }else{
        printf("[SEM UTILIZADORES REGISTADOS]\n");
    }
}

int procuraUser(pedido *users, int conta_users, char *nome) {
    int pid;
    if(strcmp(nome, "") == 0 ){
        printf("[COMANDO INCOMPLETO]\n");
        return -1;
    }
    for (int i = 0; i < conta_users; i++) {
        if (strcmp(users[i].nome, nome) == 0) {
            return i;
        }
    }
    printf("[SERVIDOR] -> UTILIZADOR NAO EXISTENTE\n");
    return -1;
}

int procuraUserTopico(topicos topic, char *nome) {
    int pid;
    if(strcmp(nome, "") == 0 ){
        printf("[COMANDO INCOMPLETO]\n");
        return -1;
    }
    for (int i = 0; i < topic.conta_user; i++) {
        if (strcmp(topic.users[i].nome, nome) == 0) {
            return i;
        }
    }
    printf("[SERVIDOR] -> UTILIZADOR NAO EXISTENTE\n");
    return -1;
}

int procuraTopico(topicos *topics, int conta_topics, char *nome) {
    if(strcmp(nome, "") == 0 ){
        printf("[COMANDO INCOMPLETO]\n");
        return -1;
    }
    for (int i = 0; i < conta_topics; i++) {
        if (strcmp(topics[i].nome, nome) == 0) {
            return i;
        }
    }
    printf("\n[SERVIDOR] -> TOPICO NAO EXISTENTE\n");
    return -1;
}

void mostrar_topics(topicos *topics , int conta_topics){
    if(conta_topics > 0){
        printf("Topicos:\n");
        for(int i = 0 ; i < conta_topics ; i++){
            printf("\t(TOPICO %d:) %s",i , topics[i].nome);
            if(topics[i].bloqueado){
                printf("\t bloqueado: ativado");
            }else{
                printf("\t bloqueado: desativado");
            }
            printf("\t NºUsers: %d" , topics[i].conta_user);
	    printf("\t NºMSG_PRS: %d\n" , topics[i].conta_msgPrs);
        }


    }else{
        printf("[SEM TOPICOS REGISTADOS]\n");
    }

}

void mostrar_msg_persistentes(topicos topics){
    if(topics.conta_msgPrs > 0){
        printf("TOPICO %s:\n" , topics.nome);
        for(int i = 0; i <  topics.conta_msgPrs ; i++){
            printf("\t[Mensagem %d] %s" , i + 1, topics.msgPrs[i].corpo);
	    printf("\t[Tempo] %d\n",topics.msgPrs[i].tempo);
        }
    }else{
        printf("[NAO TEM MENSAGENS PERSISTENTES]\n");
    }
}

void user_login(pedido *users, int *conta_users, pedido p, resposta *resp){
	int flag = 0;
	for(int i = 0 ; i < *conta_users ; i++){
		if(strcmp(users[i].nome, p.nome) == 0){
			flag = 1;
			break;
		}
	}

	if(flag == 0 && *conta_users < MAX_CLI){
		users[(*conta_users)++] = p;
		strcpy(resp->res , "REGISTADO");
		strcpy(resp->type, "");
	}else{
		strcpy(resp->res, flag ? "JA EXISTE" : "LIMITE DE USERS CHEIO");
		strcpy(resp->type , TYPE_LOGOUT);
	}

}

void adicionar_mensagem_a_topico(topicos* topics,int indice_topico, mensagensP mensagem) {
    topicos *topic = &topics[indice_topico];
    if (topic->conta_msgPrs < MAX_MSG_PRS) {
        topic->msgPrs[topic->conta_msgPrs++] = mensagem;
    } else {
        printf("[SERVIDOR] Limite de mensagens persistentes no tópico '%s' excedido.\n", topic->nome);
    }
}

int criar_topico(topicos* topics , int* conta_topics ,const char *nome_topico) {
    if ((*conta_topics) < MAX_TCS) {
        strncpy(topics[(*conta_topics)].nome, nome_topico, TAM - 1);
        topics[(*conta_topics)].conta_msgPrs = 0;
        topics[(*conta_topics)].conta_user = 0;
        topics[(*conta_topics)].bloqueado = 0;
        return (*conta_topics)++;
    } else {
        printf("[SERVIDOR] Limite de tópicos excedido.\n");
        return -1;
    }
}

void remover_cliente(topicos* topics, pedido* users, int* conta_users, int* conta_topics, char* nome, resposta* resp) {

    int i, j, k, fd_cli;
    char fifo_cli[20];

    i  = procuraUser(users, (*conta_users) , nome);
    snprintf(resp->res, sizeof(resp->res), "[NOTIFICAÇÃO] Utilizador '%s' saiu da plataforma.", nome);

    for (int u = 0; u < (*conta_users); u++) {
        if(users[u].pid != users[i].pid){
             construir_fifo_cliente(fifo_cli, users[u].pid);
             fd_cli = abrir_fifo_cliente(fifo_cli);
             enviar_resposta(fifo_cli, resp);
        }

    }

    // Remover o cliente da lista de utilizadores
    strcpy(resp->res, "[LOGOUT] concluído!");
    strcpy(resp->type, TYPE_LOGOUT);
    if (i != -1 && i >= 0) {
        users[i] = users[(*conta_users) - 1];
        memset(&users[(*conta_users) - 1], 0, sizeof(pedido));
        (*conta_users)--;
    }

    // Remover o cliente dos tópicos em que está inscrito
    for (j = 0; j < *conta_topics; j++) {
        k = procuraUserTopico(topics[j], nome);
        if(k != -1 && k >= 0){
           topics[j].users[k] = topics[j].users[topics[j].conta_user - 1];
           memset(&topics[j].users[topics[j].conta_user - 1], 0, sizeof(pedido));
           topics[j].conta_user--;
        }

        if(topics[j].conta_user == 0 && topics[j].conta_msgPrs == 0){
            printf("[TOPICO DESTRUIDO] %s \n" , topics[i].nome);
            topics[i] = topics[*conta_topics - 1];
            memset(&topics[*conta_topics - 1], 0, sizeof(topicos));
            (*conta_topics)--;
        }
    }

}


void remover_todos_clientes(pedido *users, int *conta_users, resposta resp) {
    int fd_cli;
    char fifo_cli[TAM];
    strcpy(resp.res, "[SERVIDOR ENCERROU]");
    strcpy(resp.type, TYPE_LOGOUT);
    for (int i = 0; i < *conta_users; i++) {
        construir_fifo_cliente(fifo_cli, users[i].pid);
        fd_cli = abrir_fifo_cliente(fifo_cli);
        enviar_resposta(fifo_cli, &resp);
        close(fd_cli);
        unlink(fifo_cli);
    }
    *conta_users = 0; // Atualiza a quantidade de utilizadores para 0
}



void bloquearTopico(topicos *topics , int pos){
    topics[pos].bloqueado = 1;
}

void desbloquearTopico(topicos *topics , int pos){
    topics[pos].bloqueado = 0;
}

void broadcast_users(topicos topic , char *corpo , int pid , char* nome) {
    char fifo_cli[TAM];
    resposta resp = {0};

    for (int i = 0; i < topic.conta_user; i++) {
        if (topic.users[i].pid != pid) {
            construir_fifo_cliente(fifo_cli, topic.users[i].pid);
            sprintf(resp.res, "[%s][%s]: %s",topic.nome,nome, corpo);
            strcpy(resp.type, TYPE_MESSAGE);
            enviar_resposta(fifo_cli, &resp);
        }
    }
}


void verificaCMD(char *str, pedido *users , topicos *topics , int *conta_users, int *conta_topics) {
    char cmd1[20] = {0};
    char cmd2[20] = {0};
    char fifo_cli[20];
    int fd_cli;
    resposta resp = {0};
    sscanf(str, "%19s %399[^\n]",cmd1, cmd2);

    if (strcmp(cmd1, "users") == 0) {
        mostrar_users(users, *conta_users);
    } else if (strcmp(cmd1, "remove") == 0) {
        int i = procuraUser(users, *conta_users, cmd2);
        if (i >=  0) {
             construir_fifo_cliente(fifo_cli, users[i].pid);
             fd_cli = abrir_fifo_cliente(fifo_cli);
             strcpy(resp.res, "[LOGOUT] concluído!");
             strcpy(resp.type, TYPE_LOGOUT);
             sleep(1);
             enviar_resposta(fifo_cli, &resp);
             remover_cliente(topics,users, conta_users,conta_topics, cmd2, &resp);

        }else{
            printf("[UTILIZADOR NAO EXISTE!]\n");
        }
    } else if (strcmp(cmd1, "topics") == 0) {
        mostrar_topics(topics, *conta_topics);
    }else if(strcmp(cmd1 , "lock") == 0) {
        int pos = 0;
        if ((pos = procuraTopico(topics,*conta_topics, cmd2)) >= 0) {
            bloquearTopico(topics,pos);
        }
    } else if (strcmp(cmd1 , "unlock") == 0) {
        int pos = 0;
        if ((pos = procuraTopico(topics, *conta_topics, cmd2)) >= 0) {
            desbloquearTopico(topics, pos);
        }
    } else if (strcmp(cmd1 , "show") == 0){
        int pos = 0;
        if ((pos = procuraTopico(topics, *conta_topics, cmd2)) >= 0) {
            mostrar_msg_persistentes(topics[pos]);
        }
    }else {
        printf("Comando desconhecido: %s\n", cmd1);
    }
}


void subscreve_topico(topicos *topics, int *conta_topics, pedido p, resposta *resp) {
    int i, j;

    // Procurar pelo tópico
    for (i = 0; i < *conta_topics && strcmp(topics[i].nome, p.str) != 0; i++);
    if (i == (*conta_topics)) {
        if (*conta_topics < MAX_TCS) {
            // Criar novo tópico
            strcpy(topics[(*conta_topics)].nome, p.str);

            topics[(*conta_topics)].conta_msgPrs = 0;
            topics[(*conta_topics)].bloqueado = 0;

            // Adicionar usuário ao novo tópico
            strcpy(topics[(*conta_topics)].users[0].nome, p.nome);
            topics[(*conta_topics)].users[0].pid = p.pid;
            topics[(*conta_topics)].conta_user = 1;

            (*conta_topics)++; // Incrementar número total de tópicos

            // Resposta
            strcpy(resp->type, TYPE_SUBSCRIBETOPIC);
            strncpy(resp->res, "[SERVIDOR] Tópico criado e usuário adicionado\n", sizeof(resp->res) - 1);
        } else {
            strcpy(resp->type, TYPE_SUBSCRIBETOPIC);
            strncpy(resp->res, "[SERVIDOR] Limite de tópicos excedido\n", sizeof(resp->res) - 1);
        }
    } else {
        for (j = 0; j < topics[i].conta_user && strcmp(topics[i].users[j].nome, p.nome) != 0; j++);
        if (j == topics[i].conta_user) {
            if (topics[i].conta_user < MAX_CLI) {
                strcpy(topics[i].users[j].nome, p.nome);
                topics[i].users[j].pid = p.pid;
                topics[i].conta_user++;

                strcpy(resp->type, TYPE_SUBSCRIBETOPIC);
                strncpy(resp->res, "[SERVIDOR] Foi adicionado ao tópico já existente\n", sizeof(resp->res) - 1);
                // Enviar mensagens persistentes ao cliente
                if (topics[i].conta_msgPrs > 0) {
                    char fifo_cli[TAM];
                    construir_fifo_cliente(fifo_cli, p.pid);
                    int fd_cli = abrir_fifo_cliente(fifo_cli);
                    if (fd_cli != -1) {
                        for (int k = 0; k < topics[i].conta_msgPrs; k++) {
                            resposta msg_persistente = {0};
                            strcpy(msg_persistente.type, TYPE_MESSAGE);
                            snprintf(msg_persistente.res, sizeof(msg_persistente.res), "[%s][%s] %s",topics[i].nome,topics[i].msgPrs[k].nome ,topics[i].msgPrs[k].corpo);
                            enviar_resposta(fifo_cli, &msg_persistente);
                        }
                        close(fd_cli);
                    }
                }
            } else {
                strcpy(resp->type, TYPE_SUBSCRIBETOPIC);
                strncpy(resp->res, "[SERVIDOR] Limite de usuários no tópico excedido\n", sizeof(resp->res) - 1);
            }
        } else {
            strcpy(resp->type, TYPE_SUBSCRIBETOPIC);
            strncpy(resp->res, "[SERVIDOR] Tópico já existente e já lhe pertence\n", sizeof(resp->res) - 1);
        }
    }
}


void sair_topico(topicos *topics, int *conta_topics, pedido p, resposta *resp) {
    int i, j;

    for (i = 0; i < *conta_topics && strcmp(topics[i].nome, p.str) != 0; i++);
    if (i == *conta_topics) {
        strcpy(resp->type, TYPE_UNSUBSCRIBETOPIC);
        strncpy(resp->res, "[SERVIDOR] Tópico não existente\n", sizeof(resp->res) - 1);
    } else {
        for (j = 0; j < topics[i].conta_user && strcmp(topics[i].users[j].nome, p.nome) != 0; j++);
        if (j == topics[i].conta_user) {
            strcpy(resp->type, TYPE_UNSUBSCRIBETOPIC);
            strncpy(resp->res, "[SERVIDOR] Utilizador não encontrado no tópico\n", sizeof(resp->res) - 1);
        } else {
            topics[i].users[j] = topics[i].users[topics[i].conta_user - 1];
            memset(&topics[i].users[topics[i].conta_user - 1], 0, sizeof(pedido));
            topics[i].conta_user--;

            strcpy(resp->type, TYPE_UNSUBSCRIBETOPIC);
            strncpy(resp->res, "[SERVIDOR] Saiu do tópico\n", sizeof(resp->res) - 1);

            if (topics[i].conta_user == 0 && topics[i].conta_msgPrs == 0) {
                printf("[TOPICO DESTRUIDO] %s \n" , topics[i].nome);
                topics[i] = topics[*conta_topics - 1];
                memset(&topics[*conta_topics - 1], 0, sizeof(topicos));
                (*conta_topics)--;

            }
        }
    }
}

void mostrar_topicos_utilizadores(topicos *topics, int conta_topics, resposta *resp) {
    strcpy(resp->type, TYPE_SHOWTOPICS);
    strncpy(resp->res, "\n-----------------\nTópicos Ativos\n-----------------\n", sizeof(resp->res) - 1);

    for (int i = 0; i < conta_topics; i++) {
        char buffer[20];
        sprintf(buffer, "%d", topics[i].conta_msgPrs);
        strncat(resp->res, topics[i].nome, sizeof(resp->res) - strlen(resp->res) - 1);
        strncat(resp->res, "\t", sizeof(resp->res) - strlen(resp->res) - 1);
        strncat(resp->res, "N.Mensagems Persistentes: ", sizeof(resp->res) - strlen(resp->res) - 1);
        strncat(resp->res, buffer, sizeof(resp->res) - strlen(resp->res) - 1);
        strncat(resp->res, "\t", sizeof(resp->res) - strlen(resp->res) - 1);
        strncat(resp->res, "Estado: ", sizeof(resp->res) - strlen(resp->res) - 1);
        strncat(resp->res, topics[i].bloqueado ? "Bloqueado" : "Desbloqueado", sizeof(resp->res) - strlen(resp->res) - 1);
        strncat(resp->res, "\n", sizeof(resp->res) - strlen(resp->res) - 1);
    }

    if (conta_topics == 0) {
        strncat(resp->res, "[SERVIDOR] Nao temos topicos registados\n", sizeof(resp->res) - strlen(resp->res) - 1);
    }
}
