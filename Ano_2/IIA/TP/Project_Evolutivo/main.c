#define _CRT_SECURE_NO_WARNINGS 1
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include "algoritmo.h"
#include "funcao.h"
#include "utils.h"

#define DEFAULT_RUNS 100

int main(int argc, char *argv[]) {
    char nome_fich[100];
    struct info EA_param;
    pchrom pop = NULL, parents = NULL;
    chrom best_run, best_ever;
    int gen_actual, r, runs, i, inv;
    float mbf = 0.0;

    // Lê os argumentos de entrada
    if (argc == 3) {
        runs = atoi(argv[2]);
        strcpy(nome_fich, argv[1]);
    } else if (argc == 2) {
        runs = DEFAULT_RUNS;
        strcpy(nome_fich, argv[1]);
    } else {
        runs = DEFAULT_RUNS;
        printf("Nome do Ficheiro: ");
        gets(nome_fich);
    }

    if (runs <= 0) return 0;

    // Inicializa a geração de números aleatórios
    srand(time(NULL));

    // Preenche os dados do problema e parâmetros do algoritmo
    EA_param = init_data(nome_fich);

    // Ciclo de execuções
    for (r = 0; r < runs; r++) {
        printf("Execução %d\n", r + 1);

        // Inicializa população e avalia
        pop = init_pop(EA_param);

        evaluate2(pop, EA_param);
        //evaluate2(pop, EA_param);

        gen_actual = 1;
        best_run = pop[0]; // Inicializa melhor solução
        best_run = get_best(pop, EA_param, best_run);

        parents = malloc(sizeof(chrom) * EA_param.popsize);
        if (parents == NULL) {
            printf("Erro na alocação de memória\n");
            exit(1);
        }

        // Ciclo de gerações
        while (gen_actual <= EA_param.numGenerations) {
            tournament(pop, EA_param, parents); // Seleção
            //tournament_geral(pop, EA_param, parents);
            genetic_operators(parents, EA_param, pop); // Recombinação e mutação
            evaluate2(pop, EA_param);
            //evaluate2(pop, EA_param); // Avalia descendentes
            best_run = get_best(pop, EA_param, best_run); // Atualiza melhor solução
            gen_actual++;
        }

        best_run = get_best(pop, EA_param, best_run);
        // Contagem de inválidos
        inv = 0;
        for (i = 0; i < EA_param.popsize; i++) {
            if (pop[i].valido == 0) inv++;
        }

        // Resultados da execução atual
        printf("\nExecução %d:", r + 1);
        write_best(best_run, EA_param);
        printf("\nPercentagem de inválidos: %.2f%%\n", 100.0 * inv / EA_param.popsize);

        mbf += best_run.fitness;
        if (r == 0 || best_run.fitness < best_ever.fitness) {
            best_ever = best_run;
        }

        free(parents);
        free(pop);
    }

    // Resultados gerais
    printf("\n\nMBF: %.2f\n", mbf / runs);
    printf("Melhor solução encontrada:\n");
    write_best(best_ever, EA_param);

    return 0;
}