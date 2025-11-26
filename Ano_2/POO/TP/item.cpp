#include "item.h"
#include "caravanas.h"  // Assumindo que você tenha uma classe Caravana definida em algum lugar


// Classe Item
Item::Item(const std::string& tipo, int linha, int coluna, int duracao)
    : tipo(tipo), linha(linha), coluna(coluna), duracao(duracao) {}

// Mostrar detalhes do item
void Item::mostrarDetalhes() const {
    std::cout << "Item: " << tipo << "\nPosição: (" << linha << ", " << coluna
              << ")\nDuração: " << duracao << " turnos restantes.\n";
}

// Atualizar duração (reduzir em 1 turno)
void Item::atualizarDuracao() {
    if (duracao > 0) duracao--;
}

// Verificar se o item ainda está ativo
bool Item::estaAtivo() const {
    return duracao > 0;
}

// Implementação das classes derivadas (itens específicos)
// Implementação do construtor de CaixaPandora
CaixaPandora::CaixaPandora(int linha, int coluna, int duracao)
    : Item("CaixaPandora", linha, coluna, duracao) {}

// Implementação do construtor de ArcaTesouro
ArcaTesouro::ArcaTesouro(int linha, int coluna, int duracao)
    : Item("ArcaTesouro", linha, coluna, duracao) {}

// Implementação do construtor de Jaula
Jaula::Jaula(int linha, int coluna, int duracao)
    : Item("Jaula", linha, coluna, duracao) {}

// Implementação do construtor de Mina
Mina::Mina(int linha, int coluna, int duracao)
    : Item("Mina", linha, coluna, duracao) {}

// Implementação do construtor de Surpresa
Surpresa::Surpresa(int linha, int coluna, int duracao)
    : Item("Surpresa", linha, coluna, duracao) {}

void CaixaPandora::aplicarEfeitoC(Caravana& caravana, int& moedas) {
    int perda = caravana.getTripulantes() * 0.2;
    caravana.adicionaTripulantes(-perda);
    std::cout << "Caixa de Pandora: Caravana perdeu " << perda << " tripulantes!\n";
}

void ArcaTesouro::aplicarEfeitoC(Caravana& caravana, int& moedas) {
    int ganho = moedas * 0.1;
    moedas += ganho;
    std::cout << "Arca do Tesouro: Ganhaste " << ganho << " moedas!\n";
}

void Jaula::aplicarEfeitoC(Caravana& caravana, int& moedas) {
    int ganho = 5;
    caravana.adicionaTripulantes(ganho);
    std::cout << "Jaula: Adicionou " << ganho << " tripulantes à caravana!\n";
}

void Mina::aplicarEfeitoC(Caravana& caravana, int& moedas) {
    caravana.setDestruida(true);
    std::cout << "Mina: A caravana foi destruída!\n";
}

void Surpresa::aplicarEfeitoC(Caravana& caravana, int& moedas) {
    int efeito = rand() % 2; // Determina se o efeito será positivo ou negativo

    if (efeito == 0) {
        // Efeito positivo
        cout << "Surpresa! Caravana (ID: " << caravana.getID() << ") encontrou algo útil.\n";
        caravana.reabastecerAgua();
        caravana.adicionaTripulantes(2); // Adiciona 2 tripulantes
        moedas += 10; // Ganha 10 moedas
        cout << "Caravana reabastecida, +2 tripulantes, +10 moedas.\n";
    } else {
        // Efeito negativo
        cout << "Surpresa! Caravana (ID: " << caravana.getID() << ") encontrou algo perigoso.\n";
        caravana.setAgua(caravana.getAgua()-20); // Reduz 20 litros de água
        caravana.adicionaCarga(- 5); // Danifica 5 toneladas de carga
        moedas -= 10; // Perde 10 moedas
        cout << "Caravana perdeu 20 litros de água, 5 toneladas de carga, e 10 moedas.\n";
    }
}


void CaixaPandora::aplicarEfeitoB(CaravanaBarbara& barbaro, int& moedas) {
    int perda = barbaro.getTripulantes() * 0.2;
    barbaro.adicionaTripulantes(-perda);
    std::cout << "Caixa de Pandora: Caravana Barbara perdeu " << perda << " tripulantes!\n";
}

void ArcaTesouro::aplicarEfeitoB(CaravanaBarbara& barbaro, int& moedas) {
    int ganho = moedas * 0.1;
    moedas += ganho;
    std::cout << "Arca do Tesouro: Ganhaste " << ganho << " moedas!\n";
}

void Jaula::aplicarEfeitoB(CaravanaBarbara& barbaro, int& moedas) {
    int ganho = 5;
    barbaro.adicionaTripulantes(ganho);
    std::cout << "Jaula: Adicionou " << ganho << " tripulantes à Caravana Barbara!\n";
}

void Mina::aplicarEfeitoB(CaravanaBarbara& barbaro, int& moedas) {
    barbaro.setDestruida(true);
    std::cout << "Mina: A caravana foi destruída!\n";
}

void Surpresa::aplicarEfeitoB(CaravanaBarbara& barbaro, int& moedas) {
    int efeito = rand() % 2; // Determina se o efeito será útil ou perigoso

    if (efeito == 0) {
        // Efeito positivoconfig
        cout << "Surpresa! Bárbaro encontrou algo útil.\n";
        barbaro.setTurnosRestantes(barbaro.getTurnosRestantes() + 10); // Aumenta 10 turnos restantes
        moedas -= 5; // Jogador perde 5 moedas devido ao ganho do bárbaro
        cout << "Bárbaro ganhou 10 turnos. Jogador perdeu 5 moedas.\n";
    } else {
        // Efeito negativo
        cout << "Surpresa! Bárbaro encontrou algo perigoso.\n";
        barbaro.adicionaTripulantes(-5); // Reduz 5 bárbaros
        if (barbaro.getTripulantes() <= 0) {
            barbaro.setDestruida(true); // Destrói o bárbaro se não houver mais tripulantes
            cout << "Bárbaro foi destruído pela surpresa!\n";
        } else {
            cout << "Bárbaro perdeu 5 tripulantes.\n";
        }
    }
}
