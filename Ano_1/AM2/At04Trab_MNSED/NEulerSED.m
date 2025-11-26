function [t,u,v] = NEulerSED(f,g,a,b,n,u0,v0)
    % Método de Euler para resolução numérica de sistema de EDOs
    %   u' = f(t, u, v)
    %   v' = g(t, u, v)
    %   t = [a, b], u(a) = u0, v(a) = v0
    %   u(i+1) = u(i) + h * f(t(i), u(i), v(i))
    %   v(i+1) = v(i) + h * g(t(i), u(i), v(i))
    % INPUT:
    %   f - função da EDO u' = f(t, u, v)
    %   g - função da EDO v' = g(t, u, v)
    %   [a, b] - intervalo de valores da variável independente t
    %   n - número de iterações do método
    %   u0 - aproximação inicial u(a) = u0
    %   v0 - aproximação inicial v(a) = v0
    % OUTPUT:
    %   t - vetor do intervalo [a, b] 
    %   u - vetor das soluções aproximadas de u em cada um dos t(i)
    %   v - vetor das soluções aproximadas de v em cada um dos t(i)
    h = (b-a)/n;
    t = a:h:b;
    u = zeros(1,n+1); v = zeros(1,n+1);
    u(1) = u0; v(1) = v0;
    for i = 1:n
        u(i+1) = u(i)+h*f(t(i),u(i),v(i));
        v(i+1) = v(i)+h*g(t(i),u(i),v(i));
    end
end