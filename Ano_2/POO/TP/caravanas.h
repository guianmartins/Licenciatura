#ifndef CARAVANAS_H
#define CARAVANAS_H

#include <iostream>
#include <string>
#include <vector>
#include "item.h"
#include "barbaros.h"
#include "mapa.h"
using namespace std;

class Item;
class CaravanaBarbara;
class Mapa;

class Caravana{
    int id;
    string tipo;
    int linha, coluna;
    int tripulantes;
    int agua;
    int carga;
    int maxTripulantes, maxAgua, maxCarga;
    int instantesSemTripulantes;
    bool automatico;
    bool destruida;
    string ultimaDirecao;
    int turnos;

public:
    Caravana(int id, const string& tipo, int linha, int coluna,
             int maxTripulantes, int maxAgua, int maxCarga);

    virtual ~Caravana() {}

    virtual void mover(const string& direcao, int linhasMapa, int colunasMapa, Mapa& mapa);

    virtual void mostrarDetalhes() const;

    virtual void atualizarAgua() = 0;
    virtual void tempestadeAreia() = 0 ;

    void carregar(int quantidade);

    int getID() const;
    char getCharID() const {return ('0' + id);}
    int getLinha() const;
    int getColuna() const;
    int getAgua() const { return agua; }
    bool getAutomatico() const { return automatico; }
    int getTripulantes() const { return tripulantes; }
    int getMaxTripulantes() const { return maxTripulantes; }
    int getCarga() const { return carga; }
    int getMaxCarga() const { return maxCarga; }
    int getInstantesSemTripulantes() const { return instantesSemTripulantes; }
    int getMaxAgua() const { return maxAgua; }
    int getturnos() const {return turnos;}
    string getUltDir() const { return ultimaDirecao; }
    bool getDestruida() const {return destruida;}
    string getTipo() const {return tipo;}


    void setDestruida(bool b){destruida = b;}
    void setTripulantes(int quantidade) { tripulantes = quantidade; }
    void setCarga(int quantidade) { carga = quantidade; }
    void setAgua(int quantidade) { agua = quantidade; }
    void setPosicao(int l , int c){
        linha = l;
        coluna = c;
    }

    void resetTurnos(){turnos = 0;}
    void reabastecerAgua();
    void alteraAutomatico(bool at) { automatico = at; }
    bool adicionaTripulantes(int quantidade);
    bool semTripulantes() const;
    void adicionaTurno() { turnos++; }
    bool adicionaCarga(int quantidade);
    void setInstantesSemTripulantes(int quantidade){instantesSemTripulantes = quantidade;}

    virtual bool turnosExcedidos() const = 0;
    virtual  bool movimentoAutonomo(const vector<CaravanaBarbara*>& barbaros, const vector<Caravana*>& outrasCaravanas, const vector<Item*>& items, int linhasMapa, int colunasMapa, Mapa& mapa) = 0;
    virtual bool movimentoSemTripulantes(int linhasMapa, int colunasMapa, Mapa& mapa) = 0;
};

class CaravanaComercio : public Caravana {
public:
    CaravanaComercio(int id, int linha, int coluna);

    void atualizarAgua() override;

    void tempestadeAreia() override;

    bool movimentoSemTripulantes(int linhasMapa, int colunasMapa, Mapa& mapa) override;

    bool turnosExcedidos() const override;
    bool movimentoAutonomo(const vector<CaravanaBarbara*>& barbaros, const vector<Caravana*>& outrasCaravanas, const vector<Item*>& items, int linhasMapa, int colunasMapa,Mapa& mapa) override;
};

class CaravanaMilitar : public Caravana {
public:
    CaravanaMilitar(int id, int linha, int coluna);

    void atualizarAgua() override;

    void tempestadeAreia() override;

    bool movimentoSemTripulantes(int linhasMapa, int colunasMapa, Mapa& mapa) override;

    bool turnosExcedidos() const override;

    bool movimentoAutonomo(const vector<CaravanaBarbara*>& barbaros, const vector<Caravana*>& outrasCaravanas, const vector<Item*>& items, int linhasMapa, int colunasMapa, Mapa& mapa) override;

};


class CaravanaSecreta : public Caravana {
public:
    CaravanaSecreta(int id, int linha, int coluna);

    void atualizarAgua() override;

    void tempestadeAreia() override;

    bool movimentoSemTripulantes(int linhasMapa, int colunasMapa, Mapa& mapa) override;

    bool turnosExcedidos() const override;

    bool movimentoAutonomo(const vector<CaravanaBarbara*>& barbaros, const vector<Caravana*>& outrasCaravanas, const vector<Item*>& items, int linhasMapa, int colunasMapa, Mapa& mapa) override;

};

#endif
