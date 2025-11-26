#include "cidade.h"
#include "caravanas.h"
#include <algorithm>

// Construtor
Cidade::Cidade(char nome, int linha, int coluna)
    : nome(nome), linha(linha), coluna(coluna) {}

// Métodos básicos
char Cidade::getNome() const {
    return nome;
}

int Cidade::getLinha() const {
    return linha;
}

int Cidade::getColuna() const {
    return coluna;
}

void Cidade::mostrarDetalhes() const {
    cout << "Cidade " << nome << " na posição (" << linha << ", " << coluna << ")\n";
    cout << "Número de caravanas presentes: " << caravanas.size() << "\n";
}

bool Cidade::possuiCaravana(int idCaravana) const {
    for (const auto& caravana : caravanas) {
        if (caravana->getID() == idCaravana) {
            return true;
        }
    }
    return false;
}
// Adicionar uma caravana à cidade
void Cidade::adicionarCaravana(Caravana* caravana) {
    caravanas.push_back(caravana);
    cout << "Caravana " << caravana->getID() << " entrou na cidade " << nome << ".\n";
}

// Remover uma caravana da cidade
void Cidade::removerCaravana(Caravana* caravana) {
    auto it = find(caravanas.begin(), caravanas.end(), caravana);
    if (it != caravanas.end()) {
        caravanas.erase(it);
        cout << "Caravana " << caravana->getID() << " saiu da cidade " << nome << ".\n";
    } else {
        cout << "Caravana não encontrada na cidade " << nome << ".\n";
    }
}

// Inspecionar as caravanas presentes na cidade
void Cidade::inspecionarCaravanas() const {
    cout << "Caravanas na cidade " << nome << ":\n";
    for (const auto& caravana : caravanas) {
        caravana->mostrarDetalhes();
    }
}

// Comprar mercadorias de uma caravana
void Cidade::comprarMercadorias(Caravana* caravana, int quantidade) {
    caravana->carregar(-quantidade); // Remove mercadorias da caravana
    cout << "Caravana " << caravana->getID() << " vendeu " << quantidade << " toneladas de mercadorias na cidade " << nome << ".\n";
}

// Vender mercadorias a uma caravana
void Cidade::venderMercadorias(Caravana* caravana, int quantidade) {
    caravana->carregar(quantidade); // Adiciona mercadorias à caravana
    cout << "Caravana " << caravana->getID() << " comprou " << quantidade << " toneladas de mercadorias na cidade " << nome << ".\n";
}

// Contratar tripulantes para uma caravana
void Cidade::contratarTripulantes(Caravana* caravana, int quantidade) {
    if (caravana->adicionaTripulantes(quantidade)) {
        cout << "Caravana " << caravana->getID() << " contratou " << quantidade << " tripulantes na cidade " << nome << ".\n";
    } else {
        cout << "Caravana " << caravana->getID() << " não pode adicionar mais tripulantes (capacidade máxima atingida).\n";
    }
}

// Verificar se a cidade tem pelo menos um lado acessível (deserto)
bool Cidade::ladoAcessivel(const Mapa& mapa, int linhasMapa, int colunasMapa) const {
    // Verificar as 4 posições adjacentes (cima, baixo, esquerda, direita)
    int direcoes[4][2] = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}};
    char** map = mapa.getGrelha();
    for (const auto& dir : direcoes) {
        int novaLinha = (linha + dir[0] + linhasMapa) % linhasMapa;
        int novaColuna = (coluna + dir[1] + colunasMapa) % colunasMapa;


        if (map[novaLinha][novaColuna] == '.') { // '.' representa deserto
            return true; // Pelo menos um lado acessível
        }
    }
    return false; // Nenhum lado acessível
}
