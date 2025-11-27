#include <math.h>
#include "algoritmo.h"
#include "utils.h"
#include <stdlib.h>
#include <stdio.h>
#define GENERATIONS_TC 100

void reparacao(int sol[], struct info d, int *valido) {
    float soma = 0.0;

    // Calcula o valor total da solução
    for (int i = 0; i < d.numObj; i++) {
        soma += sol[i] * d.moedas[i];
    }
    // Verifica se o valor total é diferente do valor desejado
    if (fabs(soma - d.valor) > 1e-6) {
        *valido = 0;
        float diff = d.valor - soma;
        // Tenta ajustar as moedas de maior valor para corrigir a diferença
        for (int i = 0; i < d.numObj; i++) {
            if (diff == 0) break;

            int max_moedas = (int)(fabs(diff) / d.moedas[i]); // Quantidade máxima de moedas que pode ser ajustada

            if (diff > 0) {
                // Se a diferença for positiva, adicionar moedas
                sol[i] += max_moedas;
                diff -= max_moedas * d.moedas[i]; // Atualiza a diferença
            } else if (diff < 0) {
                // Se a diferença for negativa, remover moedas
                int remover = fmin(sol[i], max_moedas); // Limita o número de moedas a serem removidas
                sol[i] -= remover;
                diff += remover * d.moedas[i]; // Atualiza a diferença
            }
        }
    }
}


float eval_individual(int sol[], struct info d, int *valido) {
    float soma = 0.0;
    int total_moedas = 0;

    // Calcula o valor total e o número de moedas na solução
    for (int i = 0; i < d.numObj; i++) {
        soma += sol[i] * d.moedas[i];
        total_moedas += sol[i];
    }

    // Se a diferença entre o valor total e o valor desejado for maior que uma tolerância
    if (fabs(soma - d.valor) > 1e-6) {
        *valido = 0;
        // Penalização proporcional à diferença, com um fator de normalização
        float penalizacao = fabs(d.valor - soma);
        return penalizacao * 100 + 1000;  // Ajuste a penalização se necessário
    } else {
        *valido = 1;
        // Fitness baseado no número total de moedas (menor é melhor)
        return total_moedas;
    }
}

// Avaliação da população
// Parâmetros de entrada: populacao (pop), estrutura com parâmetros (d)
// Parâmetros de saída: Atualiza os valores de fitness e validade de cada solução em `pop`
void evaluate1(pchrom pop, struct info d) {
    for (int i = 0; i < d.popsize; i++) {
        pop[i].fitness = eval_individual(pop[i].sol, d, &pop[i].valido);
    }
}


void evaluate2(pchrom pop, struct info d) {
    for (int i = 0; i < d.popsize; i++) {
        pop[i].fitness = eval_individual(pop[i].sol, d, &pop[i].valido);
        if (!pop[i].valido) {
            reparacao(pop[i].sol, d, &pop[i].valido);
            pop[i].fitness = eval_individual(pop[i].sol, d, &pop[i].valido);
        }
        if (pop[i].valido) {
            pop[i].fitness = 0;
            for (int j = 0; j < d.numObj; j++) {
                pop[i].fitness += pop[i].sol[j];
            }
        }
    }
}

void gera_vizinho(int sol[], int solViz[], int nGenes) {
    int i, pos, delta;
    for (i = 0; i < nGenes; i++) {
        solViz[i] = sol[i];
    }

    delta = random_l_h(-1, 1);
    if (delta != 0) {
        pos = random_l_h(0, nGenes - 1);
        solViz[pos] += delta;
        if (solViz[pos] < 0) {
            solViz[pos] = 0;
        }
    }
}

// Trepa Colinas para a população
void trepa_colinas(pchrom pop, struct info d) {
    int i, j;
    chrom vizinho;

    // Aloca espaço para `vizinho.sol`
    vizinho.sol = malloc(d.numObj * sizeof(int));
    if (vizinho.sol == NULL) {
        printf("Erro na alocação de memória para vizinho.\n");
        exit(1);
    }

    // Itera sobre cada indivíduo da população
    for (i = 0; i < d.popsize; i++) {
        for (j = 0; j < GENERATIONS_TC; j++) {
            // Gera um vizinho
            gera_vizinho(pop[i].sol, vizinho.sol, d.numObj);
            // Avalia o vizinho
            // Repara o vizinho se ele for inválido
            int valido = 1;
            reparacao(vizinho.sol, d, &valido);

            // Atualiza o indivíduo se o vizinho for melhor
            if (vizinho.fitness < pop[i].fitness && vizinho.valido) {
                for (int k = 0; k < d.numObj; k++) {
                    pop[i].sol[k] = vizinho.sol[k];
                }
                pop[i].fitness = vizinho.fitness;
                pop[i].valido = vizinho.valido;
            }
        }
    }

    // Libera memória alocada
    free(vizinho.sol);
}