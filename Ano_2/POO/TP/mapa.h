#ifndef MAPA_H
#define MAPA_H

#include <string>
#include <iostream>

class Mapa {
private:
    int linhas, colunas;
    char** grelha; // Ponteiro para matriz bidimensional

public:
    // Construtor
    Mapa();

    // Destrutor
    ~Mapa();

    // Inicializar o mapa com dimensões e preencher com '.'
    void inicializar(int nl, int nc);

    // Mostrar o mapa
    void mostrarMapa() const;

    // Atualizar uma posição no mapa
    void atualizarPosicao(int linha, int coluna, char simbolo);

    // Verificar se a posição é válida (não é montanha '+')
    bool posicaoValida(int linha, int coluna) const;

    // Obter conteúdo da posição
    char obterConteudo(int linha, int coluna) const;

    // Getters
    int getLinhas() const { return linhas; }
    int getColunas() const { return colunas; }
    char** getGrelha() const { return grelha; }

};

#endif
