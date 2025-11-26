function out_S = RegraSimpson(f, a, b, n)
%REGRA_SIMPSON Calcula a integral definida de uma função usando a regra de Simpson. 
%   Esta função calcula a integral de uma função f no intervalo [a, b] 
%   utilizando a regra de Simpson com n subintervalos. 
 
% INPUT: 
%   f - função a ser integrada 
%   a - valor inicial do intervalo de integração 
%   b - valor final do intervalo de integração 
%   n - número de subintervalos para a regra de Simpson (deve ser par) 
 
% OUTPUT: 
%   out_S - valor aproximado da integral de f no intervalo [a, b] 
    h = (b - a) / n;
    x = a;
    s = 0;
    for i = 1:n-1
        x = x + h;
        if mod(i, 2) == 0
            s = s + 2 * f(x);
        else
            s = s + 4 * f(x);
        end
    end

    out_S = h / 3 * (f(a) + s + f(b));
end
