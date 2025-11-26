function [x,y,dydx] = SDerivada(f,a,b,h,y)
%SDERIVADA Calcula a segunda derivada numérica de uma função. 
%   Esta função calcula a segunda derivada de uma função utilizando o método das 
%   diferenças centradas para os pontos internos e diferenças regressivas ou progressivas 
%   para os pontos das extremidades. 

% INPUT: 
%   f - função a ser derivada (opcional se y for fornecido) 
%   a - valor inicial do intervalo 
%   b - valor final do intervalo 
%   h - passo de incremento no intervalo 
%   y - valores da função f nos pontos de x (opcional se f for fornecido) 
 
% OUTPUT: 
%   x - vetor de pontos no intervalo [a, b] com espaçamento h 
%   y - valores da função f nos pontos de x 
%   dydx - vetor das segundas derivadas de y em cada ponto de x 
    x = a:h:b;
    n = length(x);
    if nargin == 4
        y = f(x);
    end
    dydx = zeros(1,n);

    
    for k = 2:n-1
        dydx(k) = (y(k+1) - 2*y(k) + y(k-1)) / (h^2);
    end

    temp1 = (-3*y(1) + 4*y(2) - y(3))/(2*h);
    temp2 = (-3*y(2) + 4*y(3) - y(4))/(2*h);
    temp3 = (-3*y(3) + 4*y(4) - y(5))/(2*h);
    dydx(1) = (-3*temp1 + 4*temp2 - temp3) / (h*2); 

    tempn1 = (y(n-3) - 4*y(n-2) + 3*y(n-1))/(2*h);
    tempn2 = (y(n-4) - 4*y(n-3) + 3*y(n-2))/(2*h);
    tempn = (y(n-2) - 4*y(n-1) + 3*y(n))/(2*h);
    dydx(n) = (tempn2 - 4*tempn1 + 3*tempn) / (2*h);
end

