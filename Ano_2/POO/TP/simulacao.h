#ifndef SIMULACAO_H
#define SIMULACAO_H

#include <iostream>
#include <vector>
#include <string>
#include "mapa.h"
#include "caravanas.h"
#include "cidade.h"
#include "item.h"
#include "buffer.h"
#include "barbaros.h"

using namespace std;

class Simulacao {
private:
    int fase;
    Mapa mapa;                        // Mapa do deserto
    Buffer layout;
    vector<Caravana*> caravanas;      // Lista de caravanas do utilizador
    vector<Cidade*> cidades;          // Lista de cidades
    vector<Item*> items;              // Lista de itens
    vector<Buffer*> buffers;          // Lista de buffers
    vector<CaravanaBarbara*> barbaros; // Lista de bárbaros
    int moedas;                       // Moedas do utilizador
    int turno;                        // Contador de turnos
    int combatesVencidos;             // Total de combates vencidos
    int instantesEntreItens;          // Intervalo entre geração de itens
    int duracaoItem;                  // Duração dos itens
    int maxItens;                     // Número máximo de itens
    int precoVendaMercadoria;         // Preço de venda por tonelada
    int precoCompraMercadoria;        // Preço de compra por tonelada
    int precoCaravana;                // Preço por caravana
    int instantesEntreBarbaros;       // Intervalo entre geração de bárbaros
    int duracaoBarbaros;              // Duração máxima de bárbaros

    void processarComando(const string& comando);  // Interpreta um comando
    void atualizarItens();                         // Gera e remove itens
    void atualizarBarbaros();                          // Gera novos bárbaros
    void gerirCombates();                           // verifica combates
    void montarBufferLayout(Buffer& buffer) const;
    void atualizarCaravanas();

public:
    Simulacao();
    ~Simulacao(); // Destrutor para limpar memória

    void iniciaSimulacao();

    bool config(const string& nomeFicheiro);
    void exec(const string& nomeFicheiro);
    void prox(int n = 1);
    void comprac(const char& nomeCidade, char tipo);
    void precos() const;
    void cidade(const char nomeCidade) const;
    void caravana(int idCaravana) const;
    void compra(int idCaravana, int toneladas);
    void vende(int idCaravana);
    void move(int idCaravana, const string& direcao);
    void autoGestao(int idCaravana);
    void stop(int idCaravana);
    void barbaro(int linha, int coluna);
    void areia(int linha, int coluna, int raio);
    void addMoedas(int valor);
    void tripul(int idCaravana, int quantidade);
    void saves(const string& nome);
    void loads(const string& nome);
    void lists() const;
    void dels(const string& nome);
    void terminar();
};

#endif
