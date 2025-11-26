function [x,y,dydx] = Regressiva3p(f,a,b,h,y)
% Calcula a derivada numérica de primeira ordem utilizando o método das diferenças 
% regressivas com 3 pontos. 
% INPUT: 
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
    if nargin == 4
        y = f(x);
    end
    dydx = zeros(1,n);
    for k = 3:n
        dydx(k) = (y(k-2) - 4*y(k-1) + 3*y(k)) / (2*h);
    end
    dydx(1) = (-3*y(1) + 4*y(2) - y(3))/(h*2);
    dydx(2) = (-3*y(2) + 4*y(3) - y(4))/(h*2);
end