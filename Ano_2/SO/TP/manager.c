#include "manager.h"

// Função para inicializar o manager e carregar mensagens do ficheiro
void iniciar_manager(void *arg) {
    servidor_data *servidor = (servidor_data *)arg;
    char *ficheiro_log = getenv("MSG_FICH");
    if (ficheiro_log == NULL) {
        printf("[SERVIDOR] Variável de ambiente MSG_FICH não está definida\n");
        return;
    }

    FILE *file = fopen(ficheiro_log, "r+");
    if (file == NULL) {
        perror("[SERVIDOR] Ficheiro nao está criado.");
        return;
    }

    mensagensP mensagem;
    while (fscanf(file, "%19s %19s %d %299[^\n]", mensagem.topico, mensagem.nome,&mensagem.tempo,mensagem.corpo) == 4) {
        int indice_topico = procuraTopico(servidor->topics, servidor->conta_topics, mensagem.topico);
        if (indice_topico == -1) {
            indice_topico = criar_topico(servidor->topics , &servidor->conta_topics ,mensagem.topico);
            if (indice_topico == -1) {
                continue;
            }
        }
        adicionar_mensagem_a_topico(servidor->topics ,indice_topico, mensagem);
    }

    fclose(file);
    printf("[SERVIDOR] Mensagens carregadas do ficheiro.\n");
}


void escrever_ficheiro(void *arg) {
    servidor_data *servidor = (servidor_data *)arg;
    char *ficheiro_log = getenv("MSG_FICH");

    if (ficheiro_log == NULL) {
        printf("[SERVIDOR] Variável de ambiente MSG_FICH não está definida.\n");
        return;
    }

    FILE *file = fopen(ficheiro_log, "w");
    if (file == NULL) {
        perror("[SERVIDOR] Erro ao abrir o ficheiro de log para escrita");
        return;
    }

    // Percorrer todos os tópicos e escrever as mensagens persistentes no ficheiro
    for (int i = 0; i < servidor->conta_topics; i++) {
        for (int j = 0; j < servidor->topics[i].conta_msgPrs; j++) {
            mensagensP *msg = &servidor->topics[i].msgPrs[j];
            fprintf(file, "%s %s %d %s\n",
                    msg->topico,
                    msg->nome,
                    msg->tempo,
                    msg->corpo);
        }
    }

    fclose(file);
    printf("[SERVIDOR] Mensagens persistentes foram salvas no ficheiro '%s'.\n", ficheiro_log);
}

// Função para lidar com comandos (stdin)
void *handle_commands(void *arg) {
    servidor_data *servidor = (servidor_data *)arg;
    char str[40];

    while (1) {
        if (fgets(str, sizeof(str), stdin) != NULL) {
            str[strcspn(str, "\n")] = '\0'; // Remover newline
            if(strcmp(str,"") == 0){continue;}
            if (strcmp(str, "close") == 0) {
                pthread_mutex_lock(&servidor->mutex_users);
                pthread_mutex_lock(&servidor->mutex_topics);
                remover_todos_clientes(servidor->users, &servidor->conta_users, (resposta){0});
                pthread_mutex_unlock(&servidor->mutex_topics);
                pthread_mutex_unlock(&servidor->mutex_users);
                close(servidor->fd);
                printf("[SERVIDOR] Encerrando...\n");
                break;
            }
            pthread_mutex_lock(&servidor->mutex_users);
            pthread_mutex_lock(&servidor->mutex_topics);
            verificaCMD(str, servidor->users, servidor->topics, &servidor->conta_users, &servidor->conta_topics);
            pthread_mutex_unlock(&servidor->mutex_topics);
            pthread_mutex_unlock(&servidor->mutex_users);

            printf("[COMANDO EXECUTADO] %s\n", str);
        }
    }
    return NULL;
}

// Função para processar pedidos dos clientes
void *handle_requests(void *arg) {
    servidor_data *servidor = (servidor_data *)arg;
    char fifo_cli[20];

    while (1) {
        resposta resp = {0};
        pedido p = {0};

        if (read(servidor->fd, &p, sizeof(p)) > 0) {
            construir_fifo_cliente(fifo_cli, p.pid);

            pthread_mutex_lock(&servidor->mutex_users);
            pthread_mutex_lock(&servidor->mutex_topics);

            if (strcmp(p.type, TYPE_LOGIN) == 0) {
                user_login(servidor->users, &servidor->conta_users, p, &resp);
            } else if (strcmp(p.type, TYPE_SHOWTOPICS) == 0) {
                mostrar_topicos_utilizadores(servidor->topics, servidor->conta_topics, &resp);
            } else if (strcmp(p.type, TYPE_SUBSCRIBETOPIC) == 0) {
                subscreve_topico(servidor->topics, &servidor->conta_topics, p, &resp);
            } else if (strcmp(p.type, TYPE_UNSUBSCRIBETOPIC) == 0) {
                sair_topico(servidor->topics, &servidor->conta_topics, p, &resp);
            } else if (strcmp(p.type, TYPE_LOGOUT) == 0) {
                remover_cliente(servidor->topics, servidor->users, &servidor->conta_users , &servidor->conta_topics, p.nome , &resp);
            } else if (strcmp(p.type, TYPE_MESSAGE) == 0) {
               char *topico = NULL, *tempo_str = NULL, *corpo = NULL;
               int tempo;

               // Tokenizar a string usando strtok
               topico = strtok(p.str, " ");
               tempo_str = strtok(NULL, " ");
               corpo = strtok(NULL, "");


               // Validação dos tokens
               if (!topico || !tempo_str || !corpo) {
                   printf("Erro: Formato inválido da mensagem.\n");
                   pthread_mutex_unlock(&servidor->mutex_topics);
                   pthread_mutex_unlock(&servidor->mutex_users);
                   continue;
               }

               // Converter tempo para inteiro
               tempo = atoi(tempo_str);
               if (tempo < 0) {
                   printf("Erro: Tempo inválido.\n");
                   pthread_mutex_unlock(&servidor->mutex_topics);
                   pthread_mutex_unlock(&servidor->mutex_users);
                   continue;
               }

               // Verificar limites
               if (strlen(topico) > 20 || strlen(corpo) > 300) {
                   printf("Erro: Tamanho de tópico ou corpo excede o limite permitido.\n");
                   pthread_mutex_unlock(&servidor->mutex_topics);
                   pthread_mutex_unlock(&servidor->mutex_users);
                   continue;
               }

               if(tempo == 0 || tempo > 0){
                   int pos = procuraTopico (servidor->topics, servidor->conta_topics, topico);
                   if(pos >= 0){
                       int pid = procuraUserTopico(servidor->topics[pos] , p.nome);
                       if(pid == 0 || pid > 0){
                           if(!servidor->topics[pos].bloqueado){
                                broadcast_users(servidor->topics[pos] , corpo , servidor->topics[pos].users[pid].pid , p.nome);
                               if(tempo > 0){
                                   mensagensP msgP = {0};
                                   strcpy(msgP.topico , topico);
                                   strcpy(msgP.nome , p.nome);
                                   strcpy(msgP.corpo , corpo);
                                   msgP.tempo = tempo;
                                   if(servidor->topics[pos].conta_msgPrs < 5){
                                       servidor->topics[pos].msgPrs[servidor->topics[pos].conta_msgPrs++] = msgP;
                                   }

                               }
                           }else{
                                strcpy(resp.type, TYPE_MESSAGE);
                                strncpy(resp.res, "[SERVIDOR] Tópico Bloqueado\n", sizeof(resp.res) - 1);
                           }
                       }
                   }
               }
            }

            pthread_mutex_unlock(&servidor->mutex_topics);
            pthread_mutex_unlock(&servidor->mutex_users);
            enviar_resposta(fifo_cli, &resp);
        }
    }
    return NULL;
}

void *handle_tempMsg(void *arg) {
    servidor_data *servidor = (servidor_data *)arg;
    while (1) {
        pthread_mutex_lock(&servidor->mutex_topics);
        for (int i = 0; i < servidor->conta_topics; i++) {
            for (int j = 0; j < servidor->topics[i].conta_msgPrs; j++) {
                servidor->topics[i].msgPrs[j].tempo--; // Decrementar o tempo
                if (servidor->topics[i].msgPrs[j].tempo <= 0) {
                    for (int k = j; k < servidor->topics[i].conta_msgPrs - 1; k++) {
                        servidor->topics[i].msgPrs[k] = servidor->topics[i].msgPrs[k + 1];
                    }
                    servidor->topics[i].conta_msgPrs--;
                    j--;
                }
            }
	    if(servidor->topics[i].conta_user == 0 && servidor->topics[i].conta_msgPrs == 0){
		printf("[TOPICO DESTRUIDO] %s\n" , servidor->topics[i].nome);
		servidor->topics[i] = servidor->topics[servidor->conta_topics - 1];
		memset(&servidor->topics[servidor->conta_topics - 1] , 0 , sizeof(topicos));
		servidor->conta_topics--;
	    }
        }
        pthread_mutex_unlock(&servidor->mutex_topics);
        sleep(1);
    }

    return NULL;
}


int main() {
    pthread_t thread_commands, thread_requests , thread_tempMsgPrs;
    servidor_data servidor;
    servidor.conta_users = 0;
    servidor.conta_topics = 0;
    pthread_mutex_init(&servidor.mutex_users, NULL);
    pthread_mutex_init(&servidor.mutex_topics, NULL);

    iniciar_manager(&servidor);


    if (access(FIFO_SRV, F_OK) == 0) {
        fprintf(stderr, "Já existe um servidor\n");
        exit(1);
    }

    if (mkfifo(FIFO_SRV, 0660) == -1) {
        perror("Erro ao criar FIFO do servidor");
        exit(1);
    }

    servidor.fd = open(FIFO_SRV, O_RDWR);
    if (servidor.fd == -1) {
        perror("Erro ao abrir FIFO do servidor");
        unlink(FIFO_SRV);
        exit(1);
    }

    printf("Servidor aberto (f = %d)\n", servidor.fd);

    // Criar threads
    pthread_create(&thread_commands, NULL, handle_commands, &servidor);
    pthread_create(&thread_requests, NULL, handle_requests, &servidor);
    pthread_create(&thread_tempMsgPrs, NULL, handle_tempMsg, &servidor);

    // Aguardar a thread de comandos terminar
    pthread_join(thread_commands, NULL);
    sleep(1);

    escrever_ficheiro(&servidor);
    // Limpeza final
    close(servidor.fd);
    unlink(FIFO_SRV);
    printf("[SERVIDOR ENCERRADO!]\n");
    return 0;
}
