#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>
#include <string.h>
#include <fcntl.h>
#include <sys/types.h> 
#include <sys/stat.h> 
#include <sys/select.h>
#include <pthread.h>

#define FIFO_SRV "tubo"
#define FIFO_CLI "f_%d"

// tipos
#define TYPE_LOGIN "login"
#define TYPE_MESSAGE "message"
#define TYPE_LOGOUT "logout"
#define TYPE_SUBSCRIBETOPIC "subscribe_topic"
#define TYPE_UNSUBSCRIBETOPIC "unsubscribe_topic"
#define TYPE_SHOWTOPICS "show_topics"

// tamanhos
#define TAM 20
#define MAX_CLI 10
#define MAX_TCS 20
#define MAX_MSG_PRS 5
#define MAX_MSG_CORP 300


typedef struct{
	char type[TAM];
	char nome[TAM];
	char str[400];
	int pid;
}pedido;


typedef struct{
	char res[200];
    char type[TAM];
}resposta;

typedef struct{
    char topico[TAM];
    char nome[TAM];
    char corpo[MAX_MSG_CORP];
    int tempo;
}mensagensP;

typedef struct{
    pedido users[MAX_CLI];
    char nome[TAM];
    mensagensP msgPrs[MAX_MSG_PRS];
    int conta_msgPrs;
    int conta_user;
    int bloqueado;
}topicos;

typedef struct {
    int fd;
    pedido users[MAX_CLI];
    topicos topics[MAX_TCS];
    int conta_users;
    int conta_topics;
    pthread_mutex_t mutex_users;
    pthread_mutex_t mutex_topics;
} servidor_data;


