#include "buffer.h"

// Construtor
Buffer::Buffer()
    : linhas(40), colunas(60), cursorLinha(0), cursorColuna(0), nome(" ") {
    buffer = new char[linhas * colunas]; // Aloca o buffer unidimensional
    esvaziar(); // Inicializa o buffer com espaços
}

Buffer::Buffer(const Buffer& outro , const std::string& nm) {
    // Copiar as dimensões
    linhas = outro.linhas;
    colunas = outro.colunas;

    // Alocar memória para o novo buffer
    buffer = new char[linhas * colunas];

    // Copiar o conteúdo do buffer
    for (int i = 0; i < linhas * colunas; ++i) {
        buffer[i] = outro.buffer[i];
    }

    // Copiar a posição do cursor
    cursorLinha = outro.cursorLinha;
    cursorColuna = outro.cursorColuna;

    // Copiar o nome
    nome = nm;
}

// Destrutor
Buffer::~Buffer() {
    delete[] buffer; // Libera a memória alocada para o buffer
}

// Esvaziar o buffer (preencher com espaços)
void Buffer::esvaziar() {
    for (int i = 0; i < linhas * colunas; ++i) {
        buffer[i] = ' ';
    }
}

// Mover o cursor para uma posição específica
void Buffer::moverCursor(int linha, int coluna) {
    if (linha >= 0 && linha < linhas && coluna >= 0 && coluna < colunas) {
        cursorLinha = linha;
        cursorColuna = coluna;
    } else {
        std::cerr << "Posição inválida para o cursor!" << std::endl;
    }
}

// Escrever um caracter na posição atual do cursor
void Buffer::escreverChar(char c) {
    if (cursorLinha >= 0 && cursorLinha < linhas && cursorColuna >= 0 && cursorColuna < colunas) {
        buffer[calcularIndice(cursorLinha, cursorColuna)] = c;
        cursorColuna++; // Move o cursor para a direita após escrever
    }
}

// Escrever uma string na posição atual do cursor
void Buffer::escreverString(const std::string& str) {
    for (char c : str) {
        escreverChar(c);
    }
}

// Imprimir o conteúdo do buffer na consola
void Buffer::imprimir() const {
    for (int i = 0; i < linhas; ++i) {
        for (int j = 0; j < colunas; ++j) {
            std::cout << buffer[calcularIndice(i, j)];
        }
        std::cout << std::endl;
    }
}

// Suporte ao operador <<
Buffer& Buffer::operator<<(const std::string& str) {
    escreverString(str);
    return *this;
}

Buffer& Buffer::operator<<(char c) {
    escreverChar(c);
    return *this;
}

Buffer& Buffer::operator<<(int valor) {
    escreverString(std::to_string(valor));
    return *this;
}

// Converte coordenadas (linha, coluna) em índice do array unidimensional
int Buffer::calcularIndice(int linha, int coluna) const {
    return linha * colunas + coluna;
}
