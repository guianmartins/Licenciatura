function [t,y] = NRK4(f,a,b,n,y0)
%NRK4 Método de Runge-Kutta de ordem 4 para resolução numérica de EDO/PVI
%y'=f(t,y), t=[a,b], y(a)=y0
%  y(i+1)=y(i)+1/6(k1+2k2+2k3+k4), i=0,1,…,n−1
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

for i=1:n
    k1 = h*f(t(i),y(i));
    k2 = h*f(t(i) + (h/2) , y(i) + (k1/2));
    k3 = h*f(t(i) + (h/2) , y(i) + (k2/2));
    k4 = h*f(t(i + 1) , y(i) + k3);
    y(i+1) = y(i) + (k1 + 2*k2 + 2*k3 + k4)/6;
end