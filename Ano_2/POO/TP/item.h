#ifndef ITEM_H
#define ITEM_H

#include <iostream>
#include <string>
#include "barbaros.h"
#include "caravanas.h"

class Caravana;
class CaravanaBarbara;

class Item {
    std::string tipo;
    int linha, coluna;
    int duracao;

public:
    // Construtor
    Item(const std::string& tipo, int linha, int coluna, int duracao);

    // Mostrar detalhes do item
    virtual void mostrarDetalhes() const;

    // Atualizar duração (reduzir em 1 turno)
    void atualizarDuracao();

    // Verificar se o item ainda está ativo
    bool estaAtivo() const;

    // Aplicar o efeito do item a uma caravana
    virtual void aplicarEfeitoC(Caravana& caravana, int& moedas) = 0;
    virtual void aplicarEfeitoB(CaravanaBarbara& barbaro, int& moedas) = 0;
    // Getters
    int getLinha() const { return linha; }
    int getColuna() const { return coluna; }
    std::string getTipo() const { return tipo; }
};

class CaixaPandora : public Item {
public:
    CaixaPandora(int linha, int coluna, int duracao);

    void aplicarEfeitoC(Caravana& caravana, int& moedas) override;
    void aplicarEfeitoB(CaravanaBarbara& barbaro, int& moedas) override;
};

class ArcaTesouro : public Item {
public:
    ArcaTesouro(int linha, int coluna, int duracao);

    void aplicarEfeitoC(Caravana& caravana, int& moedas) override;
    void aplicarEfeitoB(CaravanaBarbara& barbaro, int& moedas) override;
};

class Jaula : public Item {
public:
    Jaula(int linha, int coluna, int duracao);

    void aplicarEfeitoC(Caravana& caravana, int& moedas) override;
    void aplicarEfeitoB(CaravanaBarbara& barbaro, int& moedas) override;
};

class Mina : public Item {
public:
    Mina(int linha, int coluna, int duracao);

    void aplicarEfeitoC(Caravana& caravana, int& moedas) override;
    void aplicarEfeitoB(CaravanaBarbara& barbaro, int& moedas) override;
};

class Surpresa : public Item {
public:
    Surpresa(int linha, int coluna, int duracao);
    void aplicarEfeitoC(Caravana& caravana, int& moedas) override;
    void aplicarEfeitoB(CaravanaBarbara& barbaro, int& moedas) override;
};


#endif
