#ifndef CARAVANASBARBARAS_H
#define CARAVANASBARBARAS_H

#include <iostream>
#include <cstdlib>
#include <cmath>
#include "caravanas.h"
#include "mapa.h"
#include <vector>
using namespace std;

class Caravana;
class mapa;

class CaravanaBarbara{
private:
    int turnosRestantes;
    int linha , coluna;
    int tripulantes;
    bool destruida;

public:
    // Construtor
    CaravanaBarbara(int linha, int coluna, int turnosMax);

    ~CaravanaBarbara(){}

    int getTripulantes() const {return tripulantes;}
    void setTripulantes(int quantidade){ tripulantes = quantidade;}
    int getLinha() const {return linha;}
    int getColuna() const {return coluna;}
    int getTurnosRestantes() const {return turnosRestantes;}
    bool getDestruida() const {return destruida;}
    void setDestruida(bool b) {destruida = b;}
    void setTurnosRestantes(int quant){turnosRestantes = quant;}
    void mover(const std::string& direcao, int linhasMapa, int colunasMapa , Mapa& mapa);

    void adicionaTripulantes(int quant){tripulantes += quant;}
    // Movimento autónomo
    void moverAutonomo(int linhasMapa, int colunasMapa, const vector<Caravana*>& caravanas, Mapa& mapa);

    // Tempestade de areia
    void tempestadeAreia();

    // Métodos adicionais
    bool turnosExcedidos() const;
    bool semTripulantes() const {return tripulantes <= 0;}
    int calcularDistancia(int linhaAlvo, int colunaAlvo) const;
};

#endif