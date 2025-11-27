
// EStrutura para armazenar parametros
struct info
{
    // Tamanho da população
    int     popsize;
    // Probabilidade de mutação
    float   pm;
    // Probabilidade de recombinação
    float   pr;
    // Tamanho do torneio para seleção do pai da próxima geração
	int     tsize;
	// Constante para avaliação com penalização
	float   ro;
	// Capacidade da mochila
	int     capacity;
	// Número de gerações
    int   numGenerations;
    float valor;
    int numObj;
    float *moedas;
};

// Individuo (solução)
typedef struct individual chrom, *pchrom;

struct individual
{
    // Solução (objetos que estão dentro da mochila)
    int     *sol;
    // Valor da qualidade da solução
	float   fitness;
    // 1 se for uma solução válida e 0 se não for
	int     valido;
};

void tournament(pchrom pop, struct info EA_param, pchrom parents);

void genetic_operators(pchrom parents, struct info d, pchrom offspring);

void crossover(pchrom parents, struct info d, pchrom offspring);

void mutation1(pchrom offspring,struct info d);
void mutation2(pchrom offspring, struct info d);

void tournament_geral(pchrom pop, struct info d, pchrom parents);
void recombinacao_dois_pontos_corte(pchrom parents, struct info d, pchrom offspring);
void recombinacao_uniforme(pchrom parents, struct info d, pchrom offspring);
