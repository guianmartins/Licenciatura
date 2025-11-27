#define _CRT_SECURE_NO_WARNINGS 1
#include <stdio.h>
#include <stdlib.h>
#include "algoritmo.h"
#include "utils.h"

// Preenche uma estrutura com os progenitores da próxima geração, de acordo com o resultados do torneio binario (tamanho de torneio: 2)
// Parâmetros de entrada: população actual (pop), estrutura com parâmetros (d) e população de pais a encher
void tournament(pchrom pop, struct info EA_param, pchrom parents) {
    for (int i = 0; i < EA_param.popsize; i++) {
        // Seleciona dois indivíduos aleatoriamente
        int a = rand() % EA_param.popsize;
        int b = 0;
        do{
             b = rand() % EA_param.popsize;
        }while(b == a);

        // Escolhe o melhor entre os dois
        if (pop[a].fitness < pop[b].fitness) {
            parents[i] = pop[a];
        } else {
            parents[i] = pop[b];
        }
    }
}



// Operadores geneticos a usar na geração dos filhos
// Parâmetros de entrada: estrutura com os pais (parents), estrutura com parâmetros (d), estrutura que guardará os descendentes (offspring)
void genetic_operators(pchrom parents, struct info d, pchrom offspring)
{
    // Recombinação com um ponto de corte
    crossover(parents, d, offspring);
    // Recombinação com dois pontos de corte
    //recombinacao_dois_pontos_corte(parents, d, offspring);
    // Recombinação uniforme
    //recombinacao_uniforme(parents, d, offspring);
    // Mutação binária
    mutation2(offspring, d);
    //mutation1(offspring, d);
}

// Preenche o vector descendentes com o resultado das operações de recombinação
// Parâmetros de entrada: estrutura com os pais (parents), estrutura com parâmetros (d), estrutura que guardará os descendentes (offspring)
void crossover(pchrom parents, struct info d, pchrom offspring) {
    int i, j, point;

    for (i = 0; i < d.popsize; i += 2) {
        // Verifica se o cruzamento ocorrerá com base na probabilidade
        if (rand_01() < d.pr) {
            // Gera um ponto de corte válido
            point = random_l_h(0, d.numObj - 1);

            // Realiza o cruzamento até o ponto gerado
            for (j = 0; j <= point; j++) {
                offspring[i].sol[j] = parents[i].sol[j];
                offspring[i + 1].sol[j] = parents[i + 1].sol[j];
            }

            // Troca os genes após o ponto
            for (j = point + 1; j < d.numObj; j++) {
                offspring[i].sol[j] = parents[i + 1].sol[j];
                offspring[i + 1].sol[j] = parents[i].sol[j];
            }
        } else {
            // Caso não haja cruzamento, copia os pais diretamente para os descendentes
            for (j = 0; j < d.numObj; j++) {
                offspring[i].sol[j] = parents[i].sol[j];
                offspring[i + 1].sol[j] = parents[i + 1].sol[j];
            }
        }
    }
}

void recombinacao_dois_pontos_corte(pchrom parents, struct info d, pchrom offspring) {
    int i, j, point1, point2;
    // Percorre a população de pais e gera os filhos
    for (i = 0; i < d.popsize; i += 2) {
        if (rand_01() < d.pr) {  // Se a probabilidade de recombinação for satisfeita
            // Define os pontos de corte aleatórios
            point1 = random_l_h(0, d.numObj - 2);  // Point1 no intervalo [0, numObj-2]
            point2 = random_l_h(point1 + 1, d.numObj - 1);  // Point2 entre point1+1 e numObj-1
            // Realiza a recombinação no primeiro segmento (antes de point1)
            for (j = 0; j < point1; j++) {
                offspring[i].sol[j] = parents[i].sol[j];
                offspring[i + 1].sol[j] = parents[i + 1].sol[j];
            }
            // Realiza a troca entre os pais no segmento entre point1 e point2
            for (j = point1; j < point2; j++) {
                offspring[i].sol[j] = parents[i + 1].sol[j];
                offspring[i + 1].sol[j] = parents[i].sol[j];
            }
            // Realiza a recombinação no último segmento (após point2)
            for (j = point2; j < d.numObj; j++) {
                offspring[i].sol[j] = parents[i].sol[j];
                offspring[i + 1].sol[j] = parents[i + 1].sol[j];
            }
        } else {
            // Se não ocorrer recombinação, os filhos são cópias dos pais
            offspring[i] = parents[i];
            offspring[i + 1] = parents[i + 1];
        }
    }
}

void recombinacao_uniforme(pchrom parents, struct info d, pchrom offspring) {
    int i, j;

    // Percorre a população de pais e gera os filhos
    for (i = 0; i < d.popsize; i += 2) {
        if (rand_01() < d.pr) {  // Se a probabilidade de recombinação for satisfeita
            // Recombinação uniforme para cada objeto (moeda)
            for (j = 0; j < d.numObj; j++) {  // numObj representa o número de moedas ou objetos
                if (flip() == 1) {
                    // Copia o valor da solução do pai 1 para o filho 1 e do pai 2 para o filho 2
                    offspring[i].sol[j] = parents[i].sol[j];
                    offspring[i + 1].sol[j] = parents[i + 1].sol[j];
                } else {
                    // Copia o valor da solução do pai 2 para o filho 1 e do pai 1 para o filho 2
                    offspring[i].sol[j] = parents[i + 1].sol[j];
                    offspring[i + 1].sol[j] = parents[i].sol[j];
                }
            }
        } else {
            // Se não ocorrer recombinação, os filhos são cópias dos pais
            offspring[i] = parents[i];
            offspring[i + 1] = parents[i + 1];
        }
    }
}

// Mutação binária com vários pontos de mutação
// Parâmetros de entrada: estrutura com os descendentes (offspring) e estrutura com parâmetros (d)

void mutation1(pchrom offspring, struct info d) {
    for (int i = 0; i < d.popsize; i++) {
        for (int j = 0; j < d.numObj; j++) {
            if (rand_01() < d.pm) {
                int delta = random_l_h(-1, 1); // Incrementa ou decrementa uma moeda
                if (offspring[i].sol[j] + delta >= 0) {
                    offspring[i].sol[j] += delta;
                }
            }
        }
    }
}


void mutation2(pchrom offspring, struct info d) {
    for (int i = 0; i < d.popsize; i++) {
        if (rand_01() < d.pm) {  // Apenas alguns indivíduos sofrem mutação
            // Seleciona duas posições aleatórias
            int pos1 = random_l_h(0, d.numObj - 1);
            int pos2 = random_l_h(0, d.numObj - 1);

            // Garante que as posições sejam diferentes
            while (pos2 == pos1){
                pos2 = random_l_h(0, d.numObj - 1);
            }

            // Redistribui moedas entre as duas posições
            if (offspring[i].sol[pos1] > 0) {
                offspring[i].sol[pos1]--;  // Remove 1 moeda de pos1
                offspring[i].sol[pos2]++;  // Adiciona 1 moeda a pos2
            }
        }
    }
}
