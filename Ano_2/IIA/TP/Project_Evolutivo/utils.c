#define _CRT_SECURE_NO_WARNINGS 1
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "algoritmo.h"
#include "utils.h"

// Inicialização do gerador de números aleatórios
void init_rand()
{
	srand((unsigned)time(NULL));
}

// Leitura dos parâmetros e dos dados do problema
// Parâmetros de entrada: Nome do ficheiro e matriz a preencher com os dados dos objectos (peso e valor)
// Parâmetros de saída: Devolve a estrutura com os parâmetros
struct info init_data(char *nome_fich) {
    struct info EA_param;
    FILE *f;

    // Abre o ficheiro em modo de leitura
    f = fopen(nome_fich, "r");
    if (f == NULL) {
        printf("Erro ao abrir o ficheiro %s\n", nome_fich);
        exit(1);
    }

    // Lê o número de moedas e o valor a alcançar (V)
    fscanf(f, "%d %f", &EA_param.numObj, &EA_param.valor);

    // Aloca memória para o vetor de moedas
    EA_param.moedas = (float *)malloc(EA_param.numObj * sizeof(float));
    if (EA_param.moedas == NULL) {
        printf("Erro ao alocar memória para as moedas.\n");
        exit(1);
    }

    // Lê os valores das moedas
    for (int i = 0; i < EA_param.numObj; i++) {
        fscanf(f, "%f", &EA_param.moedas[i]);
    }

    // Define os parâmetros do algoritmo evolutivo
    EA_param.popsize = 100;               // Tamanho da população
    EA_param.numGenerations = 2500;      // Número de gerações
    EA_param.pr = 0.3;       // Probabilidade de Recombinacao
    EA_param.pm = 0.01;        // Probabilidade de mutação
    EA_param.tsize = 2;

    // Fecha o ficheiro
    fclose(f);

    return EA_param;
}

// Simula o lançamento de uma moeda, retornando o valor 0 ou 1
int flip()
{
	if ((((float)rand()) / RAND_MAX) < 0.5)
		return 0;
	else
		return 1;
}

void gera_sol_inicial(int *sol, float *values, float val, int v) {
    float valor_restante = val;

    // Inicializa o vetor solução com zeros
    for (int i = v; i >= 0; i--) {
        sol[i] = 0;
    }

    // Para cada moeda, gera um número aleatório entre 0 e o máximo possível
    for (int i = v; i >= 0; i--){
        if (valor_restante <= 0) break; // Se não há mais valor para distribuir, para o loop
        int max_moedas = valor_restante / values[i]; // Máximo possível de moedas deste tipo
        sol[i] = random_l_h(max_moedas/2, max_moedas);         // Gera um valor aleatório entre 0 e max_moedas
        valor_restante -= sol[i] * values[i];       // Atualiza o valor restante
    }
}

pchrom init_pop(struct info d) {
    int i, j;
    pchrom indiv;

    // Aloca memória para a população
    indiv = malloc(sizeof(chrom) * d.popsize);
    if (indiv == NULL) {
        printf("Erro na alocação de memória\n");
        exit(1);
    }

    // Inicializa cada indivíduo da população
    for (i = 0; i < d.popsize; i++) {
        // Aloca memória para o vetor de moedas de cada indivíduo
        indiv[i].sol = malloc(d.numObj * sizeof(int));
        if (indiv[i].sol == NULL) {
            printf("Erro na alocação de memória para indivíduo %d\n", i);
            exit(1);
        }

        // Inicializa as soluções
        for (j = 0; j < d.numObj; j++) {
            indiv[i].sol[j] = 0; // Inicializa com 0
        }

        // Chama a função para gerar a solução inicial
        gera_sol_inicial(indiv[i].sol, d.moedas, d.valor, d.numObj);

        // Inicializa outros campos do indivíduo
        indiv[i].fitness = 0.0; // O fitness será calculado posteriormente
        indiv[i].valido = 0;    // A validade será determinada posteriormente
    }

    return indiv;
}



// Actualiza a melhor solução encontrada
// Parâmetro de entrada: populacao actual (pop), estrutura com parâmetros (d) e a melhor solucao encontrada até a geraçãoo imediatamente anterior (best)
// Parâmetro de saída: a melhor solucao encontrada até a geração actual
chrom get_best(pchrom pop, struct info EA_param, chrom best) {
    for (int i = 0; i < EA_param.popsize; i++) {
        if (pop[i].valido == 1) {
            // Verifica se o indivíduo é válido
            int total_moedas_pop = 0;

            // Calcula o número total de moedas
            for (int j = 0; j < EA_param.numObj; j++) {
                total_moedas_pop += pop[i].sol[j];
            }

            int total_moedas_best = 0;
            for (int k = 0; k < EA_param.numObj; k++) {
                total_moedas_best += best.sol[k];
            }

            // Verifica se o indivíduo actual é melhor que o melhor indivíduo encontrado até agora
            if (total_moedas_pop < total_moedas_best) {
                best = pop[i];
            }
        }
    }
    return best;
}

// Devolve um valor inteiro distribuido uniformemente entre min e max
int random_l_h(int min, int max)
{
	return min + rand() % (max-min+1);
}

// Devolve um valor real distribuido uniformemente entre 0 e 1
float rand_01()
{
	return ((float)rand())/RAND_MAX;
}

// Escreve uma solução na consola
// Parâmetro de entrada: populacao actual (pop) e estrutura com parâmetros (d)
void write_best(chrom x, struct info d) {
    int i;
    float valor_total = 0.0;

    // Calcula o valor total gerado pela solução
    for (i = 0; i < d.numObj; i++) {
        valor_total += x.sol[i] * d.moedas[i];  // Soma o valor de cada moeda multiplicada pela quantidade
    }

    // Exibe o melhor indivíduo
    printf("\nMelhor indivíduo:\n");
    printf("Fitness (numero de moedas): %.1f\n", x.fitness);

    // Exibe a solução completa (quantidade de moedas de cada tipo)
    printf("Solução (quantidade de moedas): ");
    for (i = 0; i < d.numObj; i++) {
        printf("%d ", x.sol[i]);  // Imprime a quantidade de moedas de cada tipo
    }
    printf("\n");

    // Exibe o valor total gerado pela solução
    printf("Valor total gerado: %.2f\n", valor_total);
}


