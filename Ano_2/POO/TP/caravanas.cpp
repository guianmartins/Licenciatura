#include "caravanas.h"
#include "item.h"
#include "barbaros.h"
#include <cstdlib> // Para rand()
#include <vector>
#include <iostream>
using namespace std;

// =================== Caravana ===================
Caravana::Caravana(int id, const string& tipo, int linha, int coluna,
                   int maxTripulantes, int maxAgua, int maxCarga)
    : id(id), tipo(tipo), linha(linha), coluna(coluna),
      tripulantes(maxTripulantes), agua(maxAgua), carga(0),
      maxTripulantes(maxTripulantes), maxAgua(maxAgua), maxCarga(maxCarga),
      instantesSemTripulantes(0), automatico(false), ultimaDirecao(""),
      turnos(0), destruida(false){}

void Caravana::mostrarDetalhes() const {
    cout << "Caravana (ID: " << id << ")\n";
    cout << "Tipo: " << tipo << "\n";
    cout << "Posição: (" << linha << ", " << coluna << ")\n";
    cout << "Tripulantes: " << tripulantes << "/" << maxTripulantes << "\n";
    cout << "Carga: " << carga << "/" << maxCarga << " toneladas\n";
    cout << "Água: " << agua << "/" << maxAgua << " litros\n";
    cout << "Auto: " << automatico << "\n";
}

void Caravana::mover(const string& direcao, int linhasMapa, int colunasMapa, Mapa& mapa) {
    ultimaDirecao = direcao;

    int novaLinha = linha;
    int novaColuna = coluna;

    // Calculando as novas posições com base na direção
    if (direcao == "C") {
        novaLinha = (linha - 1 + linhasMapa) % linhasMapa;
    } else if (direcao == "B") {
        novaLinha = (linha + 1) % linhasMapa;
    } else if (direcao == "E") {
        novaColuna = (coluna - 1 + colunasMapa) % colunasMapa;
    } else if (direcao == "D") {
        novaColuna = (coluna + 1) % colunasMapa;
    } else if (direcao == "CE") {
        novaLinha = (linha - 1 + linhasMapa) % linhasMapa;
        novaColuna = (coluna - 1 + colunasMapa) % colunasMapa;
    } else if (direcao == "CD") {
        novaLinha = (linha - 1 + linhasMapa) % linhasMapa;
        novaColuna = (coluna + 1) % colunasMapa;
    } else if (direcao == "BE") {
        novaLinha = (linha + 1) % linhasMapa;
        novaColuna = (coluna - 1 + colunasMapa) % colunasMapa;
    } else if (direcao == "BD") {
        novaLinha = (linha + 1) % linhasMapa;
        novaColuna = (coluna + 1) % colunasMapa;
    }

    // Verificar se a nova posição é válida
    if (mapa.posicaoValida(novaLinha, novaColuna)) {
        mapa.atualizarPosicao(linha , coluna , '.');
        linha = novaLinha;
        coluna = novaColuna;
        mapa.atualizarPosicao(linha, coluna, getCharID());
        cout << "Caravana " << id << " movida para (" << linha << ", " << coluna << ") na direção " << direcao << ".\n";
    }

}

void Caravana::carregar(int quantidade) {
    if (carga + quantidade <= maxCarga) {
        carga += quantidade;
    } else {
        cout << "Capacidade de carga excedida!\n";
    }
}

int Caravana::getID() const {
    return id;
}

int Caravana::getLinha() const {
    return linha;
}

int Caravana::getColuna() const {
    return coluna;
}

void Caravana::reabastecerAgua() {
    agua = maxAgua;
}

bool Caravana::adicionaTripulantes(int quantidade) {
    if (tripulantes + quantidade <= maxTripulantes) {
        tripulantes += quantidade;
        if(tripulantes + quantidade  <= 0){tripulantes = 0;}
        return true;
    }

    return false;
}

bool Caravana::semTripulantes() const {
    return tripulantes <= 0;
}

bool Caravana::adicionaCarga(int quantidade) {
    if (carga + quantidade <= maxCarga) {
        carga += quantidade;
        return true;
    }
    return false;
}

// =================== CaravanaComercio ===================
CaravanaComercio::CaravanaComercio(int id, int linha, int coluna)
    : Caravana(id, "comercio", linha, coluna, 20, 200, 40) {}

bool CaravanaComercio::turnosExcedidos() const {
    return getturnos() <= 2 ? true : false;
}

void CaravanaComercio::atualizarAgua() {
    if (getAgua() > 0) {
        if (getTripulantes() == 0) {
            cout << "Caravana de Comércio (ID: " << getID() << ") não gasta água (sem tripulantes).\n";
        } else if (getTripulantes() <= getMaxTripulantes() / 2) {
            setAgua(getAgua() - 1);
        } else {
            setAgua(getAgua() - 2);
        }
        if (getAgua() < 0) setAgua(0);
    }

    if (getAgua() == 0 && getTripulantes() > 0) {
        adicionaTripulantes(-1);
    }
}

void CaravanaComercio::tempestadeAreia() {
    float ocupacaoCarga = static_cast<float>(getCarga()) / getMaxCarga();
    int probabilidade = (ocupacaoCarga > 0.5) ? 50 : 25;

    int sorte = rand() % 100;

    if (sorte < probabilidade) {
        cout << "Caravana de Comércio (ID: " << getID() << ") foi destruída por uma tempestade de areia!\n";
        setDestruida(true);
    } else {
        int perdaCarga = static_cast<int>(getCarga() * 0.25);
        adicionaCarga(-perdaCarga);
        cout << "Caravana de Comércio (ID: " << getID() << ") sobreviveu à tempestade, mas perdeu "
             << perdaCarga << " toneladas de carga.\n";
    }
}

bool CaravanaComercio::movimentoAutonomo(const vector<CaravanaBarbara*>& barbaros, const vector<Caravana*>& outrasCaravanas, const vector<Item*>& items, int linhasMapa, int colunasMapa, Mapa& mapa) {
    // Verificar itens próximos (até 2 posições de distância)
    for (auto& item : items) {
        if (abs(getLinha() - item->getLinha()) <= 2 && abs(getColuna() - item->getColuna()) <= 2) {
            int novaLinha = getLinha();
            int novaColuna = getColuna();
            int linhaAntiga = getLinha();
            int colunaAntiga = getColuna();

            // Calcular movimento em direção ao item
            if (item->getLinha() > novaLinha) novaLinha++;
            else if (item->getLinha() < novaLinha) novaLinha--;

            if (item->getColuna() > novaColuna) novaColuna++;
            else if (item->getColuna() < novaColuna) novaColuna--;

            if(mapa.posicaoValida(novaColuna , novaColuna)){
                mapa.atualizarPosicao(linhaAntiga , colunaAntiga ,'.');
                setPosicao(novaLinha, novaColuna);
                mapa.atualizarPosicao(novaLinha , novaColuna ,getCharID());
            }
            return true; // Movimento feito em direção ao item
        }
    }

    // Encontrar a caravana mais próxima
    Caravana* alvo = nullptr;
    int menorDistancia = linhasMapa + colunasMapa; // Distância máxima inicial

    for (auto& outraCaravana : outrasCaravanas) {
        if (outraCaravana->getID() != getID()) {
            int distancia = abs(getLinha() - outraCaravana->getLinha()) + abs(getColuna() - outraCaravana->getColuna());
            if (distancia < menorDistancia) {
                menorDistancia = distancia;
                alvo = outraCaravana;
            }
        }
    }

    // Aproximar-se da caravana mais próxima
    if (alvo) {
        int linhaAntiga = getLinha();
        int colunaAntiga = getColuna();
        int novaLinha = getLinha();
        int novaColuna = getColuna();

        // Calcular movimento em direção à caravana alvo
        if (alvo->getLinha() > novaLinha) novaLinha++;
        else if (alvo->getLinha() < novaLinha) novaLinha--;

        if (alvo->getColuna() > novaColuna) novaColuna++;
        else if (alvo->getColuna() < novaColuna) novaColuna--;

        if(mapa.posicaoValida(novaColuna , novaColuna)){
            mapa.atualizarPosicao(linhaAntiga , colunaAntiga ,'.');
            setPosicao(novaLinha, novaColuna);
            mapa.atualizarPosicao(novaLinha , novaColuna ,getCharID());
        }
        return true; // Movimento feito em direção à caravana
    }

    // Se não houver caravana para se aproximar, faz movimento aleatório
    string direcoes[] = {"C", "B", "E", "D", "CE", "CD", "BE", "BD"};
    string direcao = direcoes[rand() % 8];
    mover(direcao, linhasMapa, colunasMapa, mapa);
    return true;
}

bool CaravanaComercio::movimentoSemTripulantes(int linhasMapa, int colunasMapa, Mapa& mapa) {
    setInstantesSemTripulantes(getInstantesSemTripulantes() + 1);
    int direcao = rand() % 8;
    string direcoes[] = {"C", "B", "E", "D", "CE", "CD", "BE", "BD"};
    mover(direcoes[direcao], linhasMapa, colunasMapa, mapa);
    return getInstantesSemTripulantes() >= 5;
}

// =================== CaravanaMilitar ===================
CaravanaMilitar::CaravanaMilitar(int id, int linha, int coluna)
    : Caravana(id,"militar",linha, coluna, 40, 400, 5) {}

void CaravanaMilitar::atualizarAgua() {
    if (getAgua() > 0) {
        if (getTripulantes() <= getMaxTripulantes() / 2) {
            setAgua(getAgua() - 1);
        } else {
            setAgua(getAgua() - 3);
        }
        if (getAgua() < 0) setAgua(0);
    }

    if (getAgua() == 0 && getTripulantes() > 0) {
        setTripulantes(getTripulantes() - 1);
    }
}

void CaravanaMilitar::tempestadeAreia() {
    int perdaTripulantes = static_cast<int>(getTripulantes() * 0.1);
    setTripulantes(getTripulantes() - perdaTripulantes);

    int sorte = rand() % 100;
    if (sorte < 33) {
        cout << "Caravana Militar (ID: " << getID() << ") foi destruída por uma tempestade de areia!\n";
        setDestruida(true);
    } else {
        cout << "Caravana Militar (ID: " << getID() << ") sobreviveu à tempestade.\n";
    }
}

bool CaravanaMilitar::movimentoSemTripulantes(int linhasMapa, int colunasMapa, Mapa& mapa) {
    setInstantesSemTripulantes(getInstantesSemTripulantes() + 1);
    std::cout << "Instantes sem tripulantes: " <<getInstantesSemTripulantes() << endl;
    mover(getUltDir(), linhasMapa, colunasMapa, mapa);
    return getInstantesSemTripulantes() >= 7;
}

bool CaravanaMilitar::turnosExcedidos() const {
    return getturnos() <= 3 ? true : false;
}

bool CaravanaMilitar::movimentoAutonomo(const vector<CaravanaBarbara*>& barbaros, const vector<Caravana*>& outrasCaravanas, const vector<Item*>& items, int linhasMapa, int colunasMapa, Mapa& mapa) {
    CaravanaBarbara* barbaroMaisProximo = nullptr;
    int menorDistancia = INT_MAX;

    // Encontrar o bárbaro mais próximo dentro do raio de 6 casas
    for (auto& barbaro : barbaros) {
        int distancia = abs(getLinha() - barbaro->getLinha()) + abs(getColuna() - barbaro->getColuna());
        if (distancia <= 6 && distancia < menorDistancia) {
            menorDistancia = distancia;
            barbaroMaisProximo = barbaro;
        }
    }

    // Se encontrou um bárbaro dentro do raio
    if (barbaroMaisProximo != nullptr) {

        int novaLinha = getLinha();
        int novaColuna = getColuna();
        int linhaAnt = getLinha();
        int colunaAnt = getColuna();
        // Mover na direção do bárbaro mais próximo
        if (barbaroMaisProximo->getLinha() > novaLinha) {
            novaLinha++; // Move uma casa para baixo
        } else if (barbaroMaisProximo->getLinha() < novaLinha) {
            novaLinha--; // Move uma casa para cima
        }

        if (barbaroMaisProximo->getColuna() > novaColuna) {
            novaColuna++; // Move uma casa para a direita
        } else if (barbaroMaisProximo->getColuna() < novaColuna) {
            novaColuna--; // Move uma casa para a esquerda
        }

        // Verificar se a nova posição é válida no mapa
        if (mapa.posicaoValida(novaLinha, novaColuna)) {
            mapa.atualizarPosicao(linhaAnt , colunaAnt , '.');
            setPosicao(novaLinha, novaColuna);
            mapa.atualizarPosicao(novaLinha , novaColuna ,getCharID());
            return true; // Movimento realizado
        }
    }

    return false; // Não há bárbaros próximos ou movimento inválido
}

// =================== CaravanaSecreta =======================
CaravanaSecreta::CaravanaSecreta(int id, int linha, int coluna)
    : Caravana(id, "Secreta", linha, coluna, 10, 300, 20) {}

void CaravanaSecreta::atualizarAgua() {
    if (getAgua() > 0) {
        if (getTripulantes() == 0) {
            cout << "Caravana Secreta (ID: " << getID() << ") não gasta água (sem tripulantes).\n";
        } else {
            setAgua(getAgua() - 3); // Consome mais água que outras caravanas
            cout << "Caravana Secreta (ID: " << getID() << ") consumiu 3 litros de água.\n";
        }

        if (getAgua() < 0) setAgua(0);
    }

    if (getAgua() == 0 && getTripulantes() > 0) {
        adicionaTripulantes(-1); // Perde um tripulante por turno sem água
    }
}

void CaravanaSecreta::tempestadeAreia() {
    int sorte = rand() % 100;
    if (sorte < 10) { // Apenas 10% de chance de destruição
        cout << "Caravana Secreta (ID: " << getID() << ") foi destruída pela tempestade.\n";
        setDestruida(true);
    } else {
        cout << "Caravana Secreta (ID: " << getID() << ") sobreviveu à tempestade\n";
        setAgua(getAgua() - 20); // Perde 20 litros de água adicional
        if (getAgua() < 0) setAgua(0);
    }
}

bool CaravanaSecreta::movimentoSemTripulantes(int linhasMapa, int colunasMapa, Mapa& mapa) {
    setInstantesSemTripulantes(getInstantesSemTripulantes() + 1);
    // Move-se aleatoriamente enquanto não desaparece
    string direcoes[] = {"C", "B", "E", "D", "CE", "CD", "BE", "BD"};
    string direcao = direcoes[rand() % 8];
    mover(direcao, linhasMapa, colunasMapa, mapa);
     return getInstantesSemTripulantes() >= 3;
}

bool CaravanaSecreta::turnosExcedidos() const {
    // Pode mover-se até 2 vezes por turno
    return getturnos() <= 2 ? true : false;
}

bool CaravanaSecreta::movimentoAutonomo(const vector<CaravanaBarbara*>& barbaros, const vector<Caravana*>& outrasCaravanas, const vector<Item*>& items, int linhasMapa, int colunasMapa, Mapa& mapa) {
    // Priorizar evitar bárbaros
    for (auto& barbaro : barbaros) {
        int distancia = abs(barbaro->getLinha() - getLinha()) + abs(barbaro->getColuna() - getColuna());
        if (distancia <= 3) { // Foge se um bárbaro estiver a 3 posições de distância
            cout << "Caravana Secreta (ID: " << getID() << ") fugiu de um bárbaro próximo.\n";
             string direcoes[] = {"C", "B", "E", "D", "CE", "CD", "BE", "BD"};
            mover(direcoes[rand() % 8], linhasMapa, colunasMapa, mapa); // Move-se aleatoriamente para fugir
            return true;
        }
    }

    // Encontrar o item mais próximo dentro de um raio de 6 posições
    Item* itemMaisProximo = nullptr;
    int menorDistancia = INT_MAX;

    for (auto& item : items) {
        int distancia = abs(item->getLinha() - getLinha()) + abs(item->getColuna() - getColuna());
        if (distancia <= 6 && distancia < menorDistancia) {
            menorDistancia = distancia;
            itemMaisProximo = item;
        }
    }

    // Aproximar-se do item mais próximo, se encontrado
    if (itemMaisProximo != nullptr) {
        cout << "Caravana Secreta (ID: " << getID() << ") movendo-se em direção ao item mais próximo em ("
             << itemMaisProximo->getLinha() << ", " << itemMaisProximo->getColuna() << ").\n";

        int novaLinha = getLinha();
        int novaColuna = getColuna();

        if (itemMaisProximo->getLinha() > getLinha()) novaLinha++;
        else if (itemMaisProximo->getLinha() < getLinha()) novaLinha--;

        if (itemMaisProximo->getColuna() > getColuna()) novaColuna++;
        else if (itemMaisProximo->getColuna() < getColuna()) novaColuna--;

        if (mapa.posicaoValida(novaLinha, novaColuna)) {
            mapa.atualizarPosicao(getLinha(), getColuna(), '.'); // Limpar posição atual no mapa
            setPosicao(novaLinha , novaColuna);
            mapa.atualizarPosicao(novaLinha, novaColuna, 'S'); // Atualizar o mapa com a identificação da caravana secreta
            return true;
        } else {
            cout << "Movimento bloqueado por obstáculo.\n";
        }
    }

    // Movimento aleatório se nenhum item for encontrado ou movimento falhar
    string direcoes[] = {"C", "B", "E", "D"};
    string direcao = direcoes[rand() % 4];
    mover(direcao, linhasMapa, colunasMapa, mapa);
    cout << "Caravana Secreta (ID: " << getID() << ") moveu-se aleatoriamente.\n";
    return true;
}

