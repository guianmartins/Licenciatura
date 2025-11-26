function T = RegraTrapezios(f, a, b ,n)
%REGRA_TRAPEZIOS Calcula a integral definida de uma função usando a regra dos trapézios. 
%   Esta função calcula a integral de uma função f no intervalo [a, b] 
%   utilizando a regra dos trapézios com n subintervalos. 

% INPUT: 
%   f - função a ser integrada 
%   a - valor inicial do intervalo de integração 
%   b - valor final do intervalo de integração 
%   n - número de subintervalos para a regra dos trapézios 
 
% OUTPUT: 
%   T - valor aproximado da integral de f no intervalo [a, b] 
h = (b-a)/n;
x = a;
s = 0;
for i = 1:n-1
   x = x + h;
   s = s + f(x);
end 
T = h/2*(f(a)+2*s+f(b));
end

