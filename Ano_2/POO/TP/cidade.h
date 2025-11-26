#ifndef CIDADE_H
#define CIDADE_H

#include <iostream>
#include <vector>
#include <string>
#include "caravanas.h"
#include "mapa.h"
using namespace std;

class Cidade {
private:
    char nome;                   // Nome único da cidade
    int linha, coluna;           // Posição no mapa
    vector<Caravana*> caravanas; // Lista de caravanas na cidade (ponteiros para ponteiros)

public:

    Cidade(char nome, int linha, int coluna);

    // Métodos básicos
    char getNome() const;
    int getLinha() const;
    int getColuna() const;
    void mostrarDetalhes() const;

    // Métodos para interagir com caravanas
    void adicionarCaravana(Caravana* caravana);
    void removerCaravana(Caravana* caravana);
    void inspecionarCaravanas() const;

    // Ações específicas
    void comprarMercadorias(Caravana* caravana, int quantidade);
    void venderMercadorias(Caravana* caravana, int quantidade);
    void contratarTripulantes(Caravana* caravana, int quantidade);

    bool possuiCaravana(int idCaravana) const;
    // Validação de acessibilidade
    bool ladoAcessivel(const Mapa& mapa, int linhasMapa, int colunasMapa) const;
};


#endif