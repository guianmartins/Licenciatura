struct info init_data(char *nome_fich);

pchrom init_pop(struct info d);

void print_pop(pchrom pop, struct info d);

chrom get_best(pchrom pop, struct info EA_param, chrom best);

void write_best(chrom x, struct info d);

void init_rand();

int random_l_h(int min, int max);

float rand_01();

int flip();
