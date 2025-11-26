function [x,y,dydx] = Regressiva2p(~,f,a,b,h,y)
 % Calcula a derivada numérica de primeira ordem utilizando o método das diferenças 
% regressivas com 2 pontos. 
% INPUT: 
%   ~ - ignorado, pode ser usado para compatibilidade de chamada 
%   f - função a ser derivada (opcional se y for fornecido) 
%   a - valor inicial do intervalo 
%   b - valor final do intervalo 
%   h - passo de incremento no intervalo 
%   y - valores da função f nos pontos de x (opcional se f for fornecido)
% OUTPUT: 
%   x - vetor de pontos no intervalo [a, b] com espaçamento h 
%   y - valores da função f nos pontos de x 
%   dydx - vetor das derivadas de y em cada ponto de x 
    x = a:h:b;
    n = length(x);
    if nargin == 5
        y = f(x);
    end
    dydx = zeros(1,n);
    for k = 2:n
        dydx(k) = (y(k) - y(k-1)) / h;
    end
    dydx(1) = (y(2)-y(1))/h;
end