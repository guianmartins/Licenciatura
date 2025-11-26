#ifndef BUFFER_H
#define BUFFER_H

#include <string>
#include <iostream>

class Buffer {
private:
    std::string nome;
    int linhas, colunas;        // Dimensões do buffer
    char* buffer;               // Array unidimensional para armazenar os caracteres
    int cursorLinha, cursorColuna; // Posição atual do cursor

    // Converte coordenadas (linha, coluna) em índice do array unidimensional
    int calcularIndice(int linha, int coluna) const;

public:
    // Construtor
    Buffer();

    Buffer(const Buffer& outro, const std::string& nm);
    // Destrutor
    ~Buffer();

    // Esvaziar o buffer (preencher com espaços)
    void esvaziar();

    std::string getNome() const { return nome;}

    void setNome(const std::string& nm){ nome = nm;}

    // Mover o cursor para uma posição específica
    void moverCursor(int linha, int coluna);

    // Escrever um caracter na posição atual do cursor
    void escreverChar(char c);

    // Escrever uma string na posição atual do cursor
    void escreverString(const std::string& str);

    // Imprimir o conteúdo do buffer na consola
    void imprimir() const;

    // Suporte ao operador <<
    Buffer& operator<<(const std::string& str);
    Buffer& operator<<(char c);
    Buffer& operator<<(int valor);
};

#endif // BUFFER_H
