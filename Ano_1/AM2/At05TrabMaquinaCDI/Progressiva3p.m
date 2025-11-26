function [x,y,dydx] = Progressiva3p(f,a,b,h,y)
% Calcula a derivada numérica de primeira ordem utilizando o método das diferenças progressivas com 3 pontos.
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
    for k = 1:n-2
        dydx(k) = (-3*y(k)+ 4*y(k+1)-y(k+2))/(2*h);
    end
    dydx(n) = (y(n-2)- 4*y(n-1) + 3*y(n))/(h*2);
    dydx(n - 1) = (y(n-3) - 4*y(n-2) + 3*y(n-1))/(h*2);
end