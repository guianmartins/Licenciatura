function [t, y] = ODE45(f, a, b, n, y0)
% Esta função resolve uma equação diferencial ordinária (EDO) usando o método de ode45.
% f é a função que define a equação diferencial.
% a é o limite inferior do intervalo de tempo.
% b é o limite superior do intervalo de tempo.
% n é o número de pontos de grade.
% y0 é o valor inicial do vetor de estado da EDO.

% Calcula o tamanho do passo de tempo
h = (b - a) / n;

% Gera um vetor de tempo com pontos uniformemente espaçados no intervalo [a, b]
t = a:h:b;

% Resolve a EDO usando ode45
[t, y] = ode45(f, t, y0);
y = y';

end