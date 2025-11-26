function [t,u,v] = NEulerMelhoradoSED(f,g,a,b,n,u0,v0)
    % Método de Euler Melhorado para resolução numérica de sistemas de EDOs
    %   u' = f(t, u, v)
    %   v' = g(t, u, v)
    %   t = [a, b], u(a) = u0, v(a) = v0
    %   k1u = f(t(i), u(i), v(i))
    %   k1v = g(t(i), u(i), v(i))
    %   k2u = f(t(i) + h, u(i) + k1u * h, v(i) + k1v * h)
    %   k2v = g(t(i) + h, u(i) + k1u * h, v(i) + k1v * h)
    %   u(i+1) = u(i) + (h/2) * (k1u + k2u)
    %   v(i+1) = v(i) + (h/2) * (k1v + k2v)
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
        k1u = f(t(i), u(i), v(i));
        k1v = g(t(i), u(i), v(i));
       
        k2u = f(t(i) + h, u(i) + k1u * h, v(i) + k1v * h);
        k2v = g(t(i) + h, u(i) + k1u * h, v(i) + k1v * h);
    
        u(i+1) = u(i) + (h/2) * (k1u + k2u);
        v(i+1) = v(i) + (h/2) * (k1v + k2v);
    end
end