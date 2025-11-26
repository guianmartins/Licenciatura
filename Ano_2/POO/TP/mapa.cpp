#include "mapa.h"
#include <iostream>
using namespace std;

// Construtor
Mapa::Mapa() : linhas(0), colunas(0), grelha(nullptr) {}

// Destrutor
Mapa::~Mapa() {
    if (grelha != nullptr) {
        for (int i = 0; i < linhas; ++i) {
            delete[] grelha[i];
        }
        delete[] grelha;
    }
}

// Inicializar o mapa com dimensões e preencher com '.'
void Mapa::inicializar(int nl, int nc) {
    linhas = nl;
    colunas = nc;

    // Liberar memória anterior, se existir
    if (grelha != nullptr) {
        for (int i = 0; i < linhas; ++i) {
            delete[] grelha[i];
        }
        delete[] grelha;
    }

    // Alocar memória para a matriz
    grelha = new char*[linhas];
    for (int i = 0; i < linhas; ++i) {
        grelha[i] = new char[colunas];
        for (int j = 0; j < colunas; ++j) {
            grelha[i][j] = '.'; // Inicializar com '.'
        }
    }
}

// Mostrar o mapa
void Mapa::mostrarMapa() const {
    for (int i = 0; i < linhas; ++i) {
        for (int j = 0; j < colunas; ++j) {
            cout << grelha[i][j];
        }
        cout << endl;
    }
}

// Atualizar uma posição no mapa
void Mapa::atualizarPosicao(int linha, int coluna, char simbolo) {
    if (linha >= 0 && linha < linhas && coluna >= 0 && coluna < colunas) {
        grelha[linha][coluna] = simbolo;
    }
}

// Verificar se a posição é válida (não é montanha '+')
bool Mapa::posicaoValida(int linha, int coluna) const {
    if (linha < 0 || linha >= linhas || coluna < 0 || coluna >= colunas) {
        return false; // Fora dos limites
    }
    return grelha[linha][coluna] == '.'; // verifica se a posicao é um "."
}

// Obter conteúdo da posição
char Mapa::obterConteudo(int linha, int coluna) const {
    if (linha >= 0 && linha < linhas && coluna >= 0 && coluna < colunas) {
        return grelha[linha][coluna];
    }
    return '\0'; // Retorna caractere nulo se fora dos limites
}
