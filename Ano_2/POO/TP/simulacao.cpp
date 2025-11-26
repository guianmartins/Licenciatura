#include "simulacao.h"
#include <fstream>
#include <sstream>
#include <cstdlib> // Para rand()
#include <vector>
using namespace std;


// Construtor vazio
Simulacao::Simulacao()
    : fase(1),moedas(0), turno(0), combatesVencidos(0),
      instantesEntreItens(0), duracaoItem(0), maxItens(0),
      precoVendaMercadoria(0), precoCompraMercadoria(0),
      precoCaravana(0), instantesEntreBarbaros(0), duracaoBarbaros(0){}

// Destrutor para limpar memória
Simulacao::~Simulacao() {
    for (auto caravana : caravanas) delete caravana;
    for (auto cidade : cidades) delete cidade;
    for (auto item : items) delete item;
    for (auto buffer : buffers) delete buffer;
    for (auto barbaro : barbaros) delete barbaro;
}

void Simulacao::gerirCombates() {
    vector<pair<Caravana*, CaravanaBarbara*>> combatesPendentes;

    // Verificar adjacências entre caravanas do utilizador e bárbaros
    for (auto& caravana : caravanas) {
        for (auto& barbaro : barbaros) {
            int deltaLinha = abs(caravana->getLinha() - barbaro->getLinha());
            int deltaColuna = abs(caravana->getColuna() - barbaro->getColuna());

            // Verificar se o bárbaro está em uma das 8 posições adjacentes
            if (deltaLinha <= 1 && deltaColuna <= 1 && !(deltaLinha == 0 && deltaColuna == 0)) {
                combatesPendentes.emplace_back(caravana, barbaro);
            }
        }
    }


    // Resolver os combates
    for (auto& [caravana, barbaro] : combatesPendentes) {
        int forçaCaravana = rand() % (caravana->getTripulantes() + 1);
        int forçaBarbaro = rand() % (barbaro->getTripulantes() + 1);

        if (forçaCaravana >= forçaBarbaro) {
            combatesVencidos++;
            // Caravana vence
            int perdaBarbaro = forçaCaravana * 2 / 5;  // Perda de bárbaros
            int perdaCaravana = forçaCaravana / 5;    // Perda de tripulantes da caravana

            barbaro->setTripulantes(barbaro->getTripulantes() - perdaBarbaro);
            caravana->adicionaTripulantes(-perdaCaravana);

            if (barbaro->getTripulantes() <= 0) {
                for (auto it = barbaros.begin(); it != barbaros.end(); it++) {
                    if (*it == barbaro) { // Verifica se encontrou o bárbaro a ser removido
                        mapa.atualizarPosicao((*it)->getLinha() , (*it)->getColuna() , '.');
                        barbaros.erase(it); // Remove o elemento do vetor
                        cout << "Bárbaro destruido!\n";
                        delete *it;       // Libera a memória alocada para o objeto
                        break;            // Sai do loop após encontrar e remover o bárbaro
                    }
                }

            }
        } else {
            // Bárbaro vence
            int perdaCaravana = forçaBarbaro * 2 / 5;
            int perdaBarbaro = forçaBarbaro / 5;

            caravana->adicionaTripulantes(-perdaCaravana);
            barbaro->setTripulantes(barbaro->getTripulantes() - perdaBarbaro);
        }
    }
}

void Simulacao::atualizarItens() {
    // Reduzir a duração dos itens existentes
    for (auto it = items.begin(); it != items.end();) {
        (*it)->atualizarDuracao();
        if (!(*it)->estaAtivo()) {
            if(mapa.obterConteudo((*it)->getLinha() , (*it)->getColuna()) == 'I'){
                mapa.atualizarPosicao((*it)->getLinha(), (*it)->getColuna(), '.');
            }
            delete *it;
            it = items.erase(it); // Remove o item
        } else {
            ++it;
        }
    }

    // Criar novos itens se abaixo do limite configurável
    if (items.size() < maxItens && turno % instantesEntreItens == 0 && turno > 0) {
        int linha, coluna;
        do {
            linha = rand() % mapa.getLinhas();
            coluna = rand() % mapa.getColunas();
        } while (mapa.obterConteudo(linha, coluna) != '.'); // Apenas em posições vazias

        // Criar um item aleatório
        int tipo = rand() % 5; // Tipo entre 0 e 4
        Item* novoItem;
        switch (tipo) {
            case 0: novoItem = new CaixaPandora(linha, coluna, duracaoItem); break;
            case 1: novoItem = new ArcaTesouro(linha, coluna, duracaoItem); break;
            case 2: novoItem = new Jaula(linha, coluna, duracaoItem); break;
            case 3: novoItem = new Mina(linha, coluna, duracaoItem); break;
            case 4: novoItem = new Surpresa(linha, coluna, duracaoItem); break;
        }
        items.push_back(novoItem);
        mapa.atualizarPosicao(linha, coluna, 'I'); // 'I' representa um item
    }

    // Verificar se itens foram apanhados por caravanas
    for (auto& caravana : caravanas) {
        for (auto it = items.begin(); it != items.end();) {
            if (abs(caravana->getLinha() - (*it)->getLinha()) <= 1 &&
                abs(caravana->getColuna() - (*it)->getColuna()) <= 1) {
                (*it)->aplicarEfeitoC(*caravana, moedas); // Aplica efeito do item
                if(mapa.obterConteudo((*it)->getLinha() , (*it)->getColuna()) == 'I'){
                    mapa.atualizarPosicao((*it)->getLinha(), (*it)->getColuna(), '.');
                }
                delete *it;
                it = items.erase(it);
            } else {
                ++it;
            }
        }
    }

    // Verificar se itens foram apanhados por bárbaros
    for (auto& barbaro : barbaros) {
        for (auto it = items.begin(); it != items.end();) {
            if (abs(barbaro->getLinha() - (*it)->getLinha()) <= 1 &&
                abs(barbaro->getColuna() - (*it)->getColuna()) <= 1) {
                (*it)->aplicarEfeitoB(*barbaro, moedas); // Aplica efeito do item
                if(mapa.obterConteudo((*it)->getLinha() , (*it)->getColuna()) == 'I'){
                    mapa.atualizarPosicao((*it)->getLinha(), (*it)->getColuna(), '.');
                }
                delete *it;
                it = items.erase(it);
            } else {
                ++it;
            }
        }
    }
}

void Simulacao::atualizarBarbaros() {

    for (auto it = barbaros.begin(); it != barbaros.end();) {
        if ((*it)->turnosExcedidos() || (*it)->getDestruida()){
            mapa.atualizarPosicao((*it)->getLinha(), (*it)->getColuna(), '.');
            delete *it;
            it = barbaros.erase(it); // Remove o item
        } else {
            ++it;
        }
    }

    if (turno % instantesEntreBarbaros == 0 && turno > 0) {
        int linha, coluna;
        do {
            linha = rand() % mapa.getLinhas();
            coluna = rand() % mapa.getColunas();
        } while (mapa.obterConteudo(linha, coluna) != '.'); // Apenas em posições vazias

        CaravanaBarbara* novoBarbara = new CaravanaBarbara(linha, coluna, duracaoBarbaros);
        barbaros.push_back(novoBarbara);
        mapa.atualizarPosicao(linha, coluna, '!');
        cout << "Uma nova caravana bárbara apareceu em (" << linha << ", " << coluna << ")!\n";
    }

    // Movimentar os bárbaros existentes
    for (auto& barbaro : barbaros) {
        barbaro->moverAutonomo(mapa.getLinhas(), mapa.getColunas(), caravanas , mapa);
    }
}



void Simulacao::montarBufferLayout(Buffer& buffer) const {
    buffer.esvaziar(); // Esvaziar o buffer antes de começar

    // Adicionar o mapa ao buffer com controle de cursor
    for (int i = 0; i < mapa.getLinhas(); ++i) {
        for (int j = 0; j < mapa.getColunas(); ++j) {
            buffer.moverCursor(i, j);                  // Mover o cursor para (linha, coluna)
            buffer.escreverChar(mapa.obterConteudo(i, j)); // Escrever o símbolo no buffer
        }
    }

    // Adicionar uma linha em branco após o mapa
    buffer.moverCursor(mapa.getLinhas(), 0); // Mover o cursor para a primeira posição após o mapa
    buffer.escreverString("\n");

    // Adicionar os dados configuráveis ao buffer
    int linhaAtual = mapa.getLinhas() + 2; // Linha inicial para os dados
    buffer.moverCursor(linhaAtual++, 0);
    buffer.escreverString("Informacoes:");
    buffer.moverCursor(linhaAtual++, 0);
    buffer.escreverString("Moedas: " + std::to_string(moedas));
    buffer.moverCursor(linhaAtual++, 0);
    buffer.escreverString("Numero Items: " + std::to_string(items.size()));
    buffer.moverCursor(linhaAtual++, 0);
    buffer.escreverString("Numero bárbaros: " + std::to_string(barbaros.size()));
    buffer.moverCursor(linhaAtual++, 0);
    buffer.escreverString("Combates Vencidos: " + std::to_string(combatesVencidos));

    // Adicionar os detalhes das caravanas
    buffer.moverCursor(++linhaAtual, 0);
    buffer.escreverString("Caravanas:");
    for (const auto& e : caravanas) {
        buffer.moverCursor(++linhaAtual, 0);
        buffer.escreverString("ID: " + std::to_string(e->getID()) +
                              " Posição: (" + std::to_string(e->getLinha()) +
                              ", " + std::to_string(e->getColuna()) + ")");
    }

    // Adicionar os detalhes das cidades
    buffer.moverCursor(++linhaAtual, 0);
    buffer.escreverString("\nCidades:");
    for (const auto& e : cidades) {
        buffer.moverCursor(++linhaAtual, 0);
        buffer.escreverString("Nome: " + std::string(1, e->getNome()) +
                              " Posição: (" + std::to_string(e->getLinha()) +
                              ", " + std::to_string(e->getColuna()) + ")");
    }

    // Adicionar os detalhes dos bárbaros
    buffer.moverCursor(++linhaAtual, 0);
    buffer.escreverString("\nBárbaros:");
    for (const auto& e : barbaros) {
        buffer.moverCursor(++linhaAtual, 0);
        buffer.escreverString("Posição: (" + std::to_string(e->getLinha()) +
                              ", " + std::to_string(e->getColuna()) +
                              ") Duração: " + std::to_string(e->getTurnosRestantes()) +
                              " Tripulantes: " + std::to_string(e->getTripulantes()));
    }
}


bool Simulacao::config(const string& nomeFicheiro) {
    ifstream ficheiro(nomeFicheiro);
    if (!ficheiro.is_open()) {
        cerr << "Erro ao abrir o ficheiro: " << nomeFicheiro << endl;
        return false;
    }

    string linha;
    int linhas, colunas;

    string palavra;

    // Ler "linhas" e o número correspondente
    ficheiro >> palavra;
    if (palavra != "linhas") {
        std::cerr << "Formato inválido: esperado 'linhas'" << std::endl;
        exit(1);
    }
    ficheiro >> linhas;

    // Ler "colunas" e o número correspondente
    ficheiro >> palavra;
    if (palavra != "colunas") {
        std::cerr << "Formato inválido: esperado 'colunas'" << std::endl;
        exit(1);
    }
    ficheiro >> colunas;
    ficheiro.ignore();

    mapa.inicializar(linhas , colunas);

    // Ler o conteúdo do mapa
    for (int i = 0; i < linhas; ++i) {
        getline(ficheiro, linha);
        for (int j = 0; j < colunas; ++j) {
            char simbolo = linha[j];
            switch (simbolo) {
                case '.':
                    mapa.atualizarPosicao(i, j, '.'); // Espaço vazio
                    break;
                case '+':
                    mapa.atualizarPosicao(i, j, '+'); // Obstáculo
                    break;
                case 'a' ... 'z': {
                    // Criar uma cidade com o nome do símbolo
                    Cidade* novaCidade = new Cidade(simbolo, i, j);
                    if(novaCidade->ladoAcessivel(mapa, i , j)){
                        cidades.push_back(novaCidade);
                        mapa.atualizarPosicao(i, j, simbolo);
                    }else{
                        cout << "Cidade " << simbolo << "nao está bem posicionado!!" << endl;
                    }
                    break;
                }
                case '1' ... '9': {
                    int id = simbolo - '0';
                    int tipoCaravana = rand() % 3 + 1;
                    Caravana* novaCaravana = nullptr;
                    switch(tipoCaravana){
                        case 1:  novaCaravana = new CaravanaComercio(id, i, j); break;
                        case 2:  novaCaravana = new CaravanaMilitar(id, i, j); break;
                        case 3:  novaCaravana = new CaravanaSecreta(id, i, j); break;
                    }

                    caravanas.push_back(novaCaravana);
                    mapa.atualizarPosicao(i, j, simbolo);
                    break;
                }
                case '!': {
                    // Criar um bárbaro
                    CaravanaBarbara* novoBarbara = new CaravanaBarbara(i, j, duracaoBarbaros);
                    barbaros.push_back(novoBarbara);
                    mapa.atualizarPosicao(i, j, simbolo);
                    break;
                }
                default:
                    cerr << "Símbolo desconhecido no mapa: " << simbolo << endl;
            }
        }
    }

    // Ler os valores configuráveis
    while (ficheiro >> linha) {
        if (linha == "moedas") {
            ficheiro >> moedas;
        } else if (linha == "instantes_entre_novos_itens") {
            ficheiro >> instantesEntreItens;
        } else if (linha == "duração_item") {
            ficheiro >> duracaoItem;
        } else if (linha == "max_itens") {
            ficheiro >> maxItens;
        } else if (linha == "preço_venda_mercadoria") {
            ficheiro >> precoVendaMercadoria;
        } else if (linha == "preço_compra_mercadoria") {
            ficheiro >> precoCompraMercadoria;
        } else if (linha == "preço_caravana") {
            ficheiro >> precoCaravana;
        } else if (linha == "instantes_entre_novos_barbaros") {
            ficheiro >> instantesEntreBarbaros;
        } else if (linha == "duração_barbaros") {
            ficheiro >> duracaoBarbaros;
        }
    }

    for(int i = 0 ; i < barbaros.size() ; i++){
        barbaros.at(i)->setTurnosRestantes(duracaoBarbaros);
    }

    mapa.mostrarMapa(); // Mostrar o estado inicial do mapa
    montarBufferLayout(layout);
    cout << "Configuração carregada com sucesso.\n";
    return true;
}

void Simulacao::caravana(int idCaravana) const {
    for(auto &e : caravanas){
        if(e->getID() == idCaravana){
            e->mostrarDetalhes();
        }
    }
}

void Simulacao::cidade(const char nomeCidade) const {
    for(auto &e : cidades){
        if(e->getNome() == nomeCidade){
            e->mostrarDetalhes();
            e->inspecionarCaravanas();
        }
    }
}

void Simulacao::precos() const {
    cout << "Preco por venda Mercadoria: " << precoVendaMercadoria << endl
    << "Preco por compra Mercadoria: " << precoCompraMercadoria << endl
    << "Preco por Caravana: " << precoCaravana << endl;
}

void Simulacao::autoGestao(int idCaravana) {
    for(auto &e: caravanas){
        if(e->getID() == idCaravana){
            e->alteraAutomatico(true);
        }
    }
}

void Simulacao::stop(int idCaravana) {
    for(auto &e: caravanas){
        if(e->getID() == idCaravana){
            e->alteraAutomatico(false);
        }
    }
}

void Simulacao::addMoedas(int valor) {
    moedas += valor;
    cout << "Moedas atualizadas para " << moedas << endl;
}

void Simulacao::barbaro(int linha, int coluna) {
    if(mapa.posicaoValida(linha ,coluna)){
        CaravanaBarbara* novoBarbara = new CaravanaBarbara(linha , coluna , duracaoBarbaros);
        barbaros.push_back(novoBarbara);
        mapa.atualizarPosicao(linha, coluna, '!');
        mapa.mostrarMapa();
    }else{
        cout << "Posicao nao valida" << endl;
    }
}

void Simulacao::comprac(const char& nomeCidade, char tipo) {
    // Verificar se a cidade existe
    Cidade* cidadeEncontrada = nullptr;
    for (auto& cidade : cidades) {
        if (cidade->getNome() == nomeCidade) { // Supondo que a cidade tem o método getNome()
            cidadeEncontrada = cidade;
            break;
        }
    }

    if (!cidadeEncontrada) {
        cout << "Erro: Cidade " << nomeCidade << " não encontrada.\n";
        return;
    }

    // Verificar se o limite de caravanas foi atingido
    if (caravanas.size() >= 9) {
        cout << "Erro: Não é possível criar mais caravanas. Limite máximo de 9 atingido.\n";
        return;
    }

    // Gerar um ID único para a nova caravana
    int novoID = -1;
    for (int id = 1; id <= 9; ++id) {
        bool idEmUso = false;
        for (const auto& caravana : caravanas) {
            if (caravana->getID() == id) {
                idEmUso = true;
                break;
            }
        }
        if (!idEmUso) {
            novoID = id;
            break;
        }
    }

    if (novoID == -1) {
        cout << "Erro: Não foi possível gerar um ID único para a nova caravana.\n";
        return;
    }

    // Verificar se há moedas suficientes
    if (moedas < precoCaravana) {
        cout << "Erro: Moedas insuficientes para comprar uma caravana. Custo: " << precoCaravana << ", Moedas disponíveis: " << moedas << ".\n";
        return;
    }

    // Criar a caravana com base no tipo
    Caravana* novaCaravana = nullptr;

    switch (tipo) {
        case 'C': // Caravana de Comércio
            novaCaravana = new CaravanaComercio(novoID, cidadeEncontrada->getLinha(), cidadeEncontrada->getColuna());
            cidadeEncontrada->adicionarCaravana(novaCaravana);
            break;

        case 'M': // Caravana Militar
            novaCaravana = new CaravanaMilitar(novoID, cidadeEncontrada->getLinha(), cidadeEncontrada->getColuna());
            cidadeEncontrada->adicionarCaravana(novaCaravana);
            break;
        case 'S':
            novaCaravana = new CaravanaSecreta(novoID, cidadeEncontrada->getLinha(), cidadeEncontrada->getColuna());
            cidadeEncontrada->adicionarCaravana(novaCaravana);
            break;
        default:
            cout << "Erro: Tipo de caravana inválido.\n";
            return;
    }

    // Adicionar a caravana à lista de caravanas e atualizar moedas
    if (novaCaravana) {
        caravanas.push_back(novaCaravana);
        moedas -= precoCaravana; // Reduzir o número de moedas
        cout << "Caravana do tipo " << tipo << " criada com sucesso na cidade " << nomeCidade << " com ID " << novoID << ".\n";
        cout << "Moedas restantes: " << moedas << ".\n";
    }
}


void Simulacao::compra(int idCaravana, int toneladas) {
    // Verificar se a caravana existe
    Caravana* caravanaEncontrada = nullptr;
    for (auto& caravana : caravanas) {
        if (caravana->getID() == idCaravana) {
            caravanaEncontrada = caravana;
            break;
        }
    }

    if (!caravanaEncontrada) {
        cout << "Erro: Caravana com ID " << idCaravana << " não encontrada.\n";
        return;
    }

    // Verificar se a caravana está numa cidade
    Cidade* cidadeEncontrada = nullptr;
    for (auto& cidade : cidades) {
        if (cidade->getLinha() == caravanaEncontrada->getLinha() &&
            cidade->getColuna() == caravanaEncontrada->getColuna()) {
            cidadeEncontrada = cidade;
            break;
        }
    }

    if (!cidadeEncontrada) {
        cout << "Erro: Caravana não está numa cidade.\n";
        return;
    }

    // Calcular custo total da compra
    int custoTotal = toneladas * precoCompraMercadoria;

    // Verificar se há moedas suficientes
    if (moedas < custoTotal) {
        cout << "Erro: Moedas insuficientes. Custo da compra: " << custoTotal
             << ", Moedas disponíveis: " << moedas << ".\n";
        return;
    }

    // Realizar a compra
    if (caravanaEncontrada->adicionaCarga(toneladas)) { // Supondo que existe um método para adicionar mercadorias
        moedas -= custoTotal;
        cout << "Compra realizada com sucesso! " << toneladas
             << " toneladas de mercadorias adicionadas à caravana "
             << idCaravana << ".\n";
        cout << "Moedas restantes: " << moedas << ".\n";
    } else {
        cout << "Erro: A caravana não pode transportar mais mercadorias.\n";
    }
}

void Simulacao::vende(int idCaravana) {
    // Verificar se a caravana existe
    Caravana* caravanaEncontrada = nullptr;
    for (auto& caravana : caravanas) {
        if (caravana->getID() == idCaravana) {
            caravanaEncontrada = caravana;
            break;
        }
    }

    if (!caravanaEncontrada) {
        cout << "Erro: Caravana com ID " << idCaravana << " não encontrada.\n";
        return;
    }

    // Verificar se a caravana está numa cidade
    bool estaNaCidade = false;
    for (auto& cidade : cidades) {
        if (cidade->getLinha() == caravanaEncontrada->getLinha() &&
            cidade->getColuna() == caravanaEncontrada->getColuna()) {
            estaNaCidade = true;
            break;
        }
    }

    if (!estaNaCidade) {
        cout << "Erro: A caravana deve estar numa cidade para vender mercadorias.\n";
        return;
    }

    // Vender mercadorias
    int mercadorias = caravanaEncontrada->getCarga();
    if (mercadorias <= 0) {
        cout << "Erro: A caravana não possui mercadorias para vender.\n";
        return;
    }

    int lucro = mercadorias * precoVendaMercadoria; // `precoVendaMercadoria` é o preço por tonelada
    moedas += lucro; // Atualiza as moedas do jogador
    caravanaEncontrada->adicionaCarga(-mercadorias); // Remove todas as mercadorias da caravana

    cout << "Venda realizada com sucesso! " << mercadorias << " toneladas de mercadorias vendidas.\n";
    cout << "Lucro obtido: " << lucro << " moedas.\n";
    cout << "Moedas totais: " << moedas << ".\n";
}

void Simulacao::tripul(int idCaravana, int quantidade) {
    // Verificar se a caravana existe
    Caravana* caravanaEncontrada = nullptr;
    for (auto& caravana : caravanas) {
        if (caravana->getID() == idCaravana) {
            caravanaEncontrada = caravana;
            break;
        }
    }

    if (!caravanaEncontrada) {
        cout << "Erro: Caravana com ID " << idCaravana << " não encontrada.\n";
        return;
    }

    // Verificar se a caravana está numa cidade
    bool estaNaCidade = false;
    for (auto& cidade : cidades) {
        if (cidade->getLinha() == caravanaEncontrada->getLinha() &&
            cidade->getColuna() == caravanaEncontrada->getColuna()) {
            estaNaCidade = true;
            break;
        }
    }

    if (!estaNaCidade) {
        cout << "Erro: A caravana deve estar numa cidade para contratar tripulantes.\n";
        return;
    }

    // Calcular o custo e tentar adicionar tripulantes
    int custoTotal = quantidade * 1;
    if (moedas < custoTotal) {
        cout << "Erro: Moedas insuficientes para contratar " << quantidade << " tripulantes.\n";
        return;
    }

    if (caravanaEncontrada->adicionaTripulantes(quantidade)) {
        moedas -= custoTotal; // Deduzir moedas apenas se a adição foi bem-sucedida
        cout << "Sucesso: " << quantidade << " tripulantes adicionados à caravana " << idCaravana << ".\n";
        cout << "Custo total: " << custoTotal << " moedas.\n";
        cout << "Moedas restantes: " << moedas << ".\n";
    }else{
         cout << "Aviso: Excede o limite de tripulantes. \n";
    }
}

void Simulacao::areia(int linha, int coluna, int raio) {
    cout << "Criando tempestade de areia na posição (" << linha << ", " << coluna
         << ") com raio " << raio << ".\n";

    // Percorrer todas as posições dentro do quadrado de lado 2*raio + 1
    for (int i = linha - raio; i <= linha + raio; ++i) {
        for (int j = coluna - raio; j <= coluna + raio; ++j) {
            if (i >= 0 && i < mapa.getLinhas() && j >= 0 && j < mapa.getColunas()) {
                // Verificar se há uma caravana do utilizador na posição
                for (int k = 0; k < caravanas.size(); ++k) {
                    Caravana* caravana = caravanas[k];
                    if (caravana->getLinha() == i && caravana->getColuna() == j) {
                        caravana->tempestadeAreia(); // Aplicar o efeito da tempestade

                        // Se a caravana foi destruída
                        if (caravana->getDestruida()) {
                            cout << "Caravana " << caravana->getID() << " foi destruída pela tempestade.\n";
                            char simb = '.';
                             for (auto& cidade : cidades) {
                                if (cidade->possuiCaravana(caravana->getID())) {
                                    cidade->removerCaravana(caravana); // Remove a caravana da cidade
                                    simb = cidade->getNome();
                                    break;
                                }
                            }

                             mapa.atualizarPosicao(caravana->getLinha(), caravana->getColuna(), simb);
                            delete caravana;

                            // Substituir o elemento removido pelo último
                            caravanas[k] = caravanas.back();
                            caravanas.pop_back(); // Remover o último elemento
                            continue; // Evitar incrementar o índice manualmente
                        }
                    }

                }

                // Verificar se há um bárbaro na posição
                for (int k = 0; k < barbaros.size(); ++k) {
                    CaravanaBarbara* barbaro = barbaros[k];
                    if (barbaro->getLinha() == i && barbaro->getColuna() == j) {
                        barbaro->tempestadeAreia(); // Aplicar o efeito da tempestade

                        // Se o bárbaro foi destruído
                        if (barbaro->getDestruida()) {

                            mapa.atualizarPosicao(barbaro->getLinha(), barbaro->getColuna(), '.'); // Atualizar o mapa
                            delete barbaro; // Liberar memória

                            // Substituir o elemento removido pelo último
                            barbaros[k] = barbaros.back();
                            barbaros.pop_back(); // Remover o último elemento
                            continue; // Evitar incrementar o índice manualmente
                        }
                    }
                }
            }
        }
    }

    cout << "Tempestade de areia concluída.\n";
    mapa.mostrarMapa();
}



void Simulacao::move(int idCaravana, const string& direcao){
    for (auto& caravana : caravanas) {
        if (caravana->getID() == idCaravana) {
            if (caravana->turnosExcedidos()) {
                int linhaAtual = caravana->getLinha();
                int colunaAtual = caravana->getColuna();
                int novaLinha = linhaAtual;
                int novaColuna = colunaAtual;

                // Determinar a nova posição com base na direção
                if (direcao == "D") {
                    novaColuna = (colunaAtual + 1) % mapa.getColunas();
                } else if (direcao == "E") {
                    novaColuna = (colunaAtual - 1 + mapa.getColunas()) % mapa.getColunas();
                } else if (direcao == "C") {
                    novaLinha = (linhaAtual - 1 + mapa.getLinhas()) % mapa.getLinhas();
                } else if (direcao == "B") {
                    novaLinha = (linhaAtual + 1) % mapa.getLinhas();
                } else if (direcao == "CE") {
                    novaLinha = (linhaAtual - 1 + mapa.getLinhas()) % mapa.getLinhas();
                    novaColuna = (colunaAtual - 1 + mapa.getColunas()) % mapa.getColunas();
                } else if (direcao == "CD") {
                    novaLinha = (linhaAtual - 1 + mapa.getLinhas()) % mapa.getLinhas();
                    novaColuna = (colunaAtual + 1) % mapa.getColunas();
                } else if (direcao == "BE") {
                    novaLinha = (linhaAtual + 1) % mapa.getLinhas();
                    novaColuna = (colunaAtual - 1 + mapa.getColunas()) % mapa.getColunas();
                } else if (direcao == "BD") {
                    novaLinha = (linhaAtual + 1) % mapa.getLinhas();
                    novaColuna = (colunaAtual + 1) % mapa.getColunas();
                } else {
                    cout << "Erro: Direção inválida.\n";
                    return;
                }

                // Verificar se a nova posição é válida
                char conteudo = mapa.obterConteudo(novaLinha, novaColuna);
                if (conteudo == '+') {
                    cout << "Erro: A posição (" << novaLinha << ", " << novaColuna << ") é uma montanha. Movimento não permitido.\n";
                    return;
                }


                // Verificar se a caravana está em uma cidade e remover da cidade
                for (auto& cidade : cidades) {
                    if (cidade->possuiCaravana(idCaravana)) {
                        cidade->removerCaravana(caravana); // Remove a caravana da cidade
                        cout << "Caravana " << idCaravana << " saiu da cidade " << cidade->getNome() << ".\n";
                        caravana->setPosicao(novaLinha, novaColuna); // Atualizar posição da caravana
                        mapa.atualizarPosicao(novaLinha, novaColuna, '1' + idCaravana - 1); // Atualizar o mapa
                        cout << "Caravana " << idCaravana << " movida para (" << novaLinha << ", " << novaColuna << ") na direção " << direcao << ".\n";
                        caravana->adicionaTurno();
                        caravana->reabastecerAgua();
                        return;
                    }
                }


                // Verificar se a nova posição é uma cidade
                for (auto& cidade : cidades) {
                    if (cidade->getLinha() == novaLinha && cidade->getColuna() == novaColuna) {
                        cidade->adicionarCaravana(caravana); // Adicionar a caravana à nova cidade
                        mapa.atualizarPosicao(linhaAtual, colunaAtual, '.'); // Limpar posição antiga no mapa
                        cout << "Caravana " << idCaravana << " entrou na cidade " << cidade->getNome() << ".\n";
                        caravana->setPosicao(novaLinha,novaColuna);
                        caravana->adicionaTurno();
                        caravana->reabastecerAgua();
                        return;
                    }
                }

                 // Verificar se já existe uma caravana na nova posição
                for (const auto& outraCaravana : caravanas) {
                    if (outraCaravana->getLinha() == novaLinha && outraCaravana->getColuna() == novaColuna) {
                        cout << "Erro: A posição (" << novaLinha << ", " << novaColuna << ") já está ocupada por outra caravana.\n";
                        return;
                    }
                }

                // Verificar se a nova posição está ocupada por um bárbaro
                for (const auto& barbaro : barbaros) {
                    if (barbaro->getLinha() == novaLinha && barbaro->getColuna() == novaColuna) {
                        cout << "Erro: A posição (" << novaLinha << ", " << novaColuna << ") está ocupada por um bárbaro.\n";
                        return;
                    }
                }

                // Mover a caravana para a nova posição
                mapa.atualizarPosicao(linhaAtual, colunaAtual, '.'); // Limpar posição antiga no mapa
                caravana->setPosicao(novaLinha, novaColuna); // Atualizar posição da caravana
                mapa.atualizarPosicao(novaLinha, novaColuna, '1' + idCaravana - 1); // Atualizar o mapa
                cout << "Caravana " << idCaravana << " movida para (" << novaLinha << ", " << novaColuna << ") na direção " << direcao << ".\n";
                caravana->adicionaTurno();
                return;
            } else {
                cout << "Erro: A caravana excedeu o limite de movimentos permitidos.\n";
                return;
            }
        }
    }

    cout << "Erro: Caravana com ID " << idCaravana << " não encontrada.\n";
}

void Simulacao::lists() const {
    if (buffers.empty()) {
        cout << "Nenhuma cópia de buffer encontrada.\n";
        return;
    }

    cout << "Cópias do buffer existentes:\n";
    for (const auto& buffer : buffers) {
        cout << "- " << buffer->getNome() << "\n";
    }
}

void Simulacao::dels(const string& nome) {
    bool encontrado = false;

    // Percorre todos os buffers para encontrar o que tem o nome correspondente
    for (auto it = buffers.begin(); it != buffers.end(); ++it) {
        if ((*it)->getNome() == nome) {
            delete *it;  // Apaga a memória alocada
            buffers.erase(it);  // Remove o ponteiro do vetor
            cout << "Cópia do buffer '" << nome << "' apagada com sucesso.\n";
            encontrado = true;
            break;  // Sai do loop após excluir o buffer
        }
    }

    if (!encontrado) {
        cout << "Erro: Cópia do buffer '" << nome << "' não encontrada.\n";
    }
}

void Simulacao::terminar() {
    // Exibir a pontuação final
    cout << "Simulação terminada. Combates Vencidos: " << combatesVencidos << endl << "Numero de Instantes Decorridos: " << turno << endl << "Numero Moedas: " << moedas << endl;


    // Reiniciar a simulação (fazendo a limpeza e reinicializando os valores)
    // Reinicia os parâmetros e variáveis da simulação
    // Exemplo de redefinir variáveis:
    moedas = 0;
    turno = 0;
    combatesVencidos = 0;
    instantesEntreItens = 0;
    duracaoItem = 0;
    maxItens = 0;
    precoVendaMercadoria = 0;
    precoCompraMercadoria = 0;
    precoCaravana = 0;
    instantesEntreBarbaros = 0;
    duracaoBarbaros = 0;

    // Apagar todos os objetos criados (caravanas, cidades, itens, etc.)
    for (auto& caravana : caravanas) {
        delete caravana;
    }
    caravanas.clear();

    for (auto& cidade : cidades) {
        delete cidade;
    }
    cidades.clear();

    for (auto& item : items) {
        delete item;
    }
    items.clear();

    for (auto& buffer : buffers) {
        delete buffer;
    }
    buffers.clear();

    for (auto& barbaro : barbaros) {
        delete barbaro;
    }
    barbaros.clear();

    fase = 1;
    iniciaSimulacao();
}

void Simulacao::loads(const string& nome) {
    // Itera sobre o vetor de buffers manualmente
    for (Buffer* buffer : buffers) {
        // Comparando o nome do buffer com o nome fornecido
        if (buffer->getNome() == nome) {
            // Se o buffer for encontrado, exibe as informações dele
            cout << "Buffer '" << nome << "' recuperado com sucesso.\n";
            buffer->imprimir();  // Assumindo que você tem uma função para mostrar o estado
            return;  // Sai da função após encontrar o buffer
        }
    }

    // Caso não tenha encontrado o buffer
    cout << "Erro: Cópia do buffer '" << nome << "' não encontrada.\n";
}

void Simulacao::saves(const string& nome) {
    // Verifica se o nome do buffer já existe
    for (const auto& buffer : buffers) {
        if (buffer->getNome() == nome) {
            cout << "Erro: Já existe um buffer com o nome '" << nome << "'.\n";
            return;
        }
    }

    // Cria uma nova cópia do buffer visual
    Buffer* novoBuffer = new Buffer(layout , nome);
    cout << novoBuffer->getNome() << endl;

    // Armazena a cópia do buffer na lista de buffers
    buffers.push_back(novoBuffer);
    cout << "Cópia do estado visual do buffer '" << nome << "' armazenada com sucesso.\n";
}

void Simulacao::atualizarCaravanas() {
    for (auto it = caravanas.begin(); it != caravanas.end(); ++it) {
        auto& caravana = *it;

        caravana->resetTurnos();
        caravana->atualizarAgua();

        if(caravana->getDestruida()){
            mapa.atualizarPosicao(caravana->getLinha(), caravana->getColuna(), '.');
            delete caravana;
            it = caravanas.erase(it); // Remover e avançar o iterador
        }

        if (caravana->getAutomatico()) {
            if (caravana->getTripulantes() > 0) {
                // Movimento autónomo (modo automático)
                caravana->movimentoAutonomo(barbaros, caravanas, items, mapa.getLinhas(), mapa.getColunas(), mapa);
                ++it; // Avançar se a caravana não for removida
            } else {
                // Movimento sem tripulantes
                if (caravana->movimentoSemTripulantes(mapa.getLinhas(), mapa.getColunas(), mapa)) {
                    mapa.atualizarPosicao(caravana->getLinha(), caravana->getColuna(), '.');
                    cout << "Caravana " << caravana->getID() << " desapareceu por falta de tripulantes.\n";
                    delete caravana;
                    it = caravanas.erase(it); // Remover e avançar o iterador
                } else {
                    ++it; // Apenas avançar se a caravana não for removida
                }
            }
        }
    }
}


void Simulacao::prox(int n) {
    if (n <= 0) {
        cout << "Erro: O número de instantes deve ser maior que 0.\n";
        return;
    }

    cout << "Avançando " << n << " instantes...\n";

    for (int i = 0; i < n; ++i) {
        cout << "Turno " << (turno + 1) << ":\n";

        // Atualizar caravanas (modo automático ou sem tripulantes)
        atualizarCaravanas();

        // Atualizar os itens no mapa
        atualizarItens();

        // Gerar e mover bárbaros
        atualizarBarbaros();

        // Gerir combates entre caravanas e bárbaros
        gerirCombates();

        // Atualizar o buffer/layout do mapa
        montarBufferLayout(layout);

        // Mostrar o estado do mapa e informações adicionais
        layout.imprimir();

        // Incrementar o contador de turnos
        turno++;

        // Separador entre turnos (para melhor visualização)
        if (i < n - 1) {
            cout << "===========================\n";
        }
    }

    cout << "Avanço concluído.\n";
}



void Simulacao::exec(const string& nomeFicheiro) {
    ifstream ficheiro(nomeFicheiro);
    if (!ficheiro.is_open()) {
        cout << "Erro: Não foi possível abrir o ficheiro '" << nomeFicheiro << "'.\n";
        return;
    }

    cout << "Executando comandos do ficheiro '" << nomeFicheiro << "':\n";

    string linha;
    int linhaAtual = 1; // Contador de linhas
    while (getline(ficheiro, linha)) {
        if (!linha.empty()) {
            cout << "Linha " << linhaAtual << ": " << linha << "\n";
            try {
                processarComando(linha); // Reutiliza o método para interpretar o comando
            } catch (const exception& e) {
                cout << "Erro ao processar o comando na linha " << linhaAtual << ": " << e.what() << "\n";
            }
        }
        linhaAtual++;
    }

    ficheiro.close();
    cout << "Execução concluída.\n";
}

void Simulacao::processarComando(const string& comando) {
    // Dividir o comando em palavras
    istringstream ss(comando);
    vector<string> args;
    string arg;
    while (ss >> arg) {
        args.push_back(arg);
    }

    if (args.empty()) return;


    if(fase == 1){
        if (args[0] == "config") {
            if (args.size() == 2) {
                config(args[1]);
                fase = 2;
            } else {
                cout << "Erro: Argumentos inválidos para comando 'config'.\n";
            }
        }
        else if (args[0] == "sair") {
            // Encerra o programa
            cout << "Saindo do programa...\n";
            exit(0);
        }else {
            cout << "Comando desconhecido: " << args[0] << "\n";
        }
    } else if(fase == 2){
        if(args[0] == "caravana"){
            if (args.size() == 2) {
                // Convertendo o argumento de string para inteiro
                try {
                    int idCaravana = stoi(args[1]);
                    caravana(idCaravana);  // Passa o id como inteiro
                } catch (const invalid_argument& e) {
                    cout << "Erro: ID da caravana inválido.\n";
                }
            } else {
                cout << "Erro: Argumentos inválidos para comando 'caravana'.\n";
            }
        }
        else if(args[0] == "cidade"){
            if (args.size() == 2) {
                char c = args[1][0];
                cidade(c);
            }else {
                cout << "Erro: Argumentos inválidos para comando 'cidade'.\n";
            }
        }
        else if(args[0] == "precos"){
            precos();
        }
        else if(args[0] == "auto"){
            if(args.size() == 2){
                try {
                    int idCaravana = stoi(args[1]);
                    autoGestao(idCaravana);  // Passa o id como inteiro
                } catch (const invalid_argument& e) {
                    cout << "Erro: ID da caravana inválido.\n";
                }
            }else {
                cout << "Erro: Argumentos inválidos para comando 'auto'.\n";
            }
        }
        else if(args[0] == "stop"){
            if(args.size() == 2){
                try {
                    int idCaravana = stoi(args[1]);
                    stop(idCaravana);  // Passa o id como inteiro
                } catch (const invalid_argument& e) {
                    cout << "Erro: ID da caravana inválido.\n";
                }
            }else {
                cout << "Erro: Argumentos inválidos para comando 'stop'.\n";
            }
        }
        else if(args[0] == "moedas"){
            if(args.size() == 2){
                int quantMoedas = stoi(args[1]);
                addMoedas(quantMoedas);  // Passa o id como inteiro
            }else {
                cout << "Erro: Argumentos inválidos para comando 'moedas'.\n";
            }
        }
        else if(args[0] == "barbaro"){
            if(args.size() == 3){
                barbaro(stoi(args[1]) , stoi(args[2]));
            }else {
                cout << "Erro: Argumentos inválidos para comando 'barbaro'.\n";
            }
        }
        else if (args[0] == "comprac") {
            if (args.size() == 3) {
                char cidade = args[1][0];  // Obter a cidade
                char tipoCaravana = args[2][0];  // Obter o tipo de caravana

                // Validar o tipo de caravana
                if (tipoCaravana == 'C' || tipoCaravana == 'M') {
                    comprac(cidade, tipoCaravana);
                } else {
                    cout << "Erro: Tipo de caravana inválido. Use 'C', 'M' ou 'S'.\n";
                }
            } else {
                cout << "Erro: Argumentos inválidos para comando 'comprac'.\n";
            }
        }
        else if (args[0] == "compra") {
            if (args.size() == 3) {
                try {
                    int idCaravana = stoi(args[1]); // Converte o ID da caravana para inteiro
                    int toneladas = stoi(args[2]); // Converte o número de toneladas para inteiro

                    if (toneladas <= 0) {
                        cout << "Erro: O número de toneladas deve ser maior que zero.\n";
                        return;
                    }

                    compra(idCaravana, toneladas); // Chama a função de compra
                } catch (const invalid_argument& e) {
                    cout << "Erro: Argumentos inválidos para o comando 'compra'. Certifique-se de usar números inteiros.\n";
                }
            } else {
                cout << "Erro: Uso correto do comando: compra <ID_Caravana> <Toneladas>\n";
            }
        }
        else if (args[0] == "vende") {
            if (args.size() == 2) {
                try {
                    int idCaravana = stoi(args[1]); // Converte o ID da caravana para inteiro
                    vende(idCaravana); // Chama a função de venda
                } catch (const invalid_argument& e) {
                    cout << "Erro: ID da caravana inválido.\n";
                }
            } else {
                cout << "Erro: Uso correto do comando: vende <ID_Caravana>\n";
            }
        }
        else if (args[0] == "tripul") {
            if (args.size() == 3) {
                try {
                    int idCaravana = stoi(args[1]);  // Convertendo ID da caravana
                    int quantidade = stoi(args[2]);  // Convertendo a quantidade de tripulantes
                    tripul(idCaravana, quantidade);  // Chama a função de adicionar tripulantes
                } catch (const invalid_argument& e) {
                    cout << "Erro: Argumentos inválidos para comando 'tripul'.\n";
                }
            } else {
                cout << "Erro: Argumentos inválidos para comando 'tripul'.\n";
            }
        }
        else if (args[0] == "areia") {  // Adicionado o comando areia
            if (args.size() == 4) {
                try {
                    int linha = stoi(args[1]); // Linha da tempestade
                    int coluna = stoi(args[2]); // Coluna da tempestade
                    int raio = stoi(args[3]); // Raio da tempestade

                    if (raio < 0) {
                        cout << "Erro: O raio da tempestade deve ser não negativo.\n";
                    } else {
                        areia(linha, coluna, raio); // Chama o método correspondente
                    }
                } catch (const invalid_argument& e) {
                    cout << "Erro: Argumentos inválidos para comando 'areia'.\n";
                }
            } else {
                cout << "Erro: Uso correto do comando: areia <linha> <coluna> <raio>\n";
            }
        }
        else if (args[0] == "move") {
            if (args.size() == 3) {
                try {
                    int idCaravana = stoi(args[1]); // Obter o ID da caravana
                    string direcao = args[2];       // Obter a direção de movimento

                    // Validar a direção
                    if (direcao == "D" || direcao == "E" || direcao == "C" || direcao == "B" ||
                        direcao == "CE" || direcao == "CD" || direcao == "BE" || direcao == "BD") {
                        move(idCaravana, direcao); // Chama o método de movimentação
                        mapa.mostrarMapa();
                    } else {
                        cout << "Erro: Direção inválida. Use D, E, C, B, CE, CD, BE, BD.\n";
                    }
                } catch (const invalid_argument& e) {
                    cout << "Erro: Argumentos inválidos para comando 'move'.\n";
                }
            } else {
                cout << "Erro: Uso correto do comando: move <ID_Caravana> <Direção>\n";
            }
        }
        else if (args[0] == "saves") {
            if (args.size() == 2) {
                saves(args[1]);  // Chama o método saves para criar uma cópia do estado visual do buffer
            } else {
                cout << "Erro: Argumentos inválidos para comando 'saves'.\n";
            }
        }
        else if(args[0] == "loads") {
            if (args.size() == 2) {
                loads(args[1]);  // Chama o método loads para recuperar o buffer
            } else {
                cout << "Erro: Argumentos inválidos para comando 'loads'.\n";
            }
        }

        else if (args[0] == "lists") {
            lists();  // Chama o método lists
        }
        else if (args[0] == "dels") {
            if (args.size() == 2) {
                dels(args[1]);  // Chama o método dels
            } else {
                cout << "Erro: Argumentos inválidos para comando 'dels'.\n";
            }
        }
        else if (args[0] == "prox") {
            if (args.size() == 1) {
                // Se nenhum valor for especificado, avança 1 turno por padrão
                prox(1);
            } else if (args.size() == 2) {
                try {
                    int n = stoi(args[1]); // Converte o argumento para inteiro
                    if (n > 0) {
                        prox(n); // Chama o método prox com o valor especificado
                    } else {
                        cout << "Erro: O número de turnos deve ser maior que 0.\n";
                    }
                } catch (const invalid_argument&) {
                    cout << "Erro: Argumento inválido para comando 'prox'. Certifique-se de usar um número inteiro.\n";
                }
            } else {
                cout << "Erro: Uso correto do comando 'prox <n>'.\n";
            }
        }
        else if (args[0] == "exec") {
            if (args.size() == 2) {
                exec(args[1]); // Chama o método `exec` com o nome do ficheiro
            } else {
                cout << "Erro: Uso correto do comando 'exec <nomeFicheiro>'.\n";
            }
        }

        else if(args[0] == "terminar"){
            terminar();
        }
        else {
            cout << "Comando desconhecido: " << args[0] << "\n";
        }
    }

    montarBufferLayout(layout);
}



void Simulacao::iniciaSimulacao() {
    string cmd;
    while (1) {
        getline(cin, cmd);
        processarComando(cmd);
    }
}