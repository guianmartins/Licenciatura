function [f, a, b, n, y0, sExata, g, h, t, yExata] = introduzirFuncao()
    syms y(t)
    strF = input('\n f(t,y) = ','s');
    f = @(t,y) eval(vectorize(strF));
    a = input('a = ');
    b = input('b = ');
    n = input('n = ');
    y0 = input('y0 = ');
    sExata = dsolve(diff(y,t)==f(t,y),y(a)==y0);
    fplot(sExata,[a,b]);
    g = @(t) eval(vectorize(char(sExata)));
    h = (b-a)/n;
    t = a:h:b;
    yExata = g(t);
end