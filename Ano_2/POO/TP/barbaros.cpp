#include "barbaros.h"
#include "caravanas.h"
#include <vector>
using namespace std;
// Construtor
CaravanaBarbara::CaravanaBarbara(int linha, int coluna, int turnosMax)
    : linha(linha), coluna(coluna) , turnosRestantes(turnosMax) , tripulantes(40), destruida(false){}

void CaravanaBarbara::mover(const std::string& direcao, int linhasMapa, int colunasMapa, Mapa& mapa) {

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
        mapa.atualizarPosicao(linha, coluna, '!');
    }
}


void CaravanaBarbara::moverAutonomo(int linhasMapa, int colunasMapa, const vector<Caravana*>& caravanas, Mapa& mapa) {
    // Reduzir turnos restantes
    turnosRestantes--;

    // Variáveis para armazenar a caravana mais próxima e a sua distância
    const Caravana* caravanaMaisProxima = nullptr;
    int menorDistancia = INT_MAX;

    // Encontrar a caravana mais próxima dentro do raio de alcance (8 posições)
    for (const auto& caravana : caravanas) {
        int distancia = calcularDistancia(caravana->getLinha(), caravana->getColuna());
        if (distancia <= 8 && distancia < menorDistancia) {
            caravanaMaisProxima = caravana;
            menorDistancia = distancia;
        }
    }

    // Movimento em direção à caravana mais próxima
    if (caravanaMaisProxima != nullptr) {
        int linhaAlvo = caravanaMaisProxima->getLinha();
        int colunaAlvo = caravanaMaisProxima->getColuna();
        int novaLinha = linha;
        int novaColuna = coluna;

        // Determinar direção do movimento
        if (linha < linhaAlvo) novaLinha++;
        else if (linha > linhaAlvo) novaLinha--;

        if (coluna < colunaAlvo) novaColuna++;
        else if (coluna > colunaAlvo) novaColuna--;

        // Verificar se a nova posição é válida
        if (mapa.posicaoValida(novaLinha, novaColuna)) {
            mapa.atualizarPosicao(linha, coluna, '.'); // Limpar posição atual no mapa
            linha = novaLinha;
            coluna = novaColuna;
            mapa.atualizarPosicao(linha, coluna, '!'); // Atualizar posição no mapa
            cout << "Bárbaro movido para (" << linha << ", " << coluna << ") em direção à caravana mais próxima.\n";
        }
    } else {
        // Caso contrário, movimento aleatório
        string direcoes[] = {"C", "B", "E", "D", "CE" , "CD" , "BE" , "BD"};
        string direcao = direcoes[rand() % 8]; // Escolher uma direção aleatória

        // Tentar mover na direção aleatória
        mover(direcao, linhasMapa, colunasMapa, mapa);
        cout << "Bárbaro movido aleatoriamente para (" << linha << ", " << coluna << ").\n";
    }

}



// Tempestade de areia
void CaravanaBarbara::tempestadeAreia() {
    // Perde 10% dos tripulantes
    int perdaTripulantes = static_cast<int>(getTripulantes() * 0.1);
    tripulantes -= perdaTripulantes;

    // 25% de chance de destruição total
    int sorte = rand() % 100;
    if (sorte < 25) {
        setDestruida(true);
    }
}

// Verifica se os turnos excederam o limite
bool CaravanaBarbara::turnosExcedidos() const{
    return turnosRestantes <= 0;
}

// Calcula a distância Manhattan entre a caravana bárbara e uma posição-alvo
int CaravanaBarbara::calcularDistancia(int linhaAlvo, int colunaAlvo) const {
    return abs(linha - linhaAlvo) + abs(coluna - colunaAlvo);
}
