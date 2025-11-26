function [t,y] = NRK2(f,a,b,n,y0)
%NRK2 Método de Runge-Kutta de ordem 2 para resolução numérica de EDO/PVI
%   y'=f(t,y), t=[a,b], y(a)=y0
%   y(i+1)=y(i)+1/2(k1+k2)
%INPUT:
%   f - função da EDO y'=f(t,y)
%   [a,b] - intervalo de valores da variável independente t
%   n - número de subintervalos ou iterações do método
%   y0 - aproximação inicial y(a)=y0
%OUTPUT:
%   t - vetor do intervalo [a,b] discretizado 
%   y - vetor das soluções aproximadas do PVI em cada um dos t(i)


h = (b-a)/n;
t = a:h:b;
y = zeros(1,n+1);
y(1) = y0;
for i = 1:n
    k1 = h*f(t(i),y(i));
    k2 = h*f(t(i+1),y(i)+k1);
    y(i+1) = y(i)+(k1+k2)/2;
end
end