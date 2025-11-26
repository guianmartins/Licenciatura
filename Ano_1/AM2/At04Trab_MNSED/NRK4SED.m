function [t,u,v] = NRK4SED(~,f,g,a,b,n,u0,v0)
    % Esta função resolve um sistema de equações diferenciais ordinárias (EDOs) 
    % de segunda ordem utilizando o método de Runge-Kutta de quarta ordem (RK4).
	% Formulas:
	%	k1u = f(t(i), u(i), v(i));
    %   k1v = g(t(i), u(i), v(i));
	%
    %   k2u = f(t(i) + h/2, u(i) + h*(k1u/2), v(i) + h*(k1v/2));
    %   k2v = g(t(i) + h/2, u(i) + h*(k1u/2), v(i) + h*(k1v/2));  
	%
    %   k3u = f(t(i) + h/2, u(i) + h*(k2u/2), v(i) + h*(k2v/2));  
    %   k3v = g(t(i) + h/2, u(i) + h*(k2u/2), v(i) + h*(k2v/2));  
	%
    %   k4u = f(t(i) + h, u(i) + h*k3u, v(i) + h*k3v);
    %   k4v = g(t(i) + h, u(i) + h*k3u, v(i) + h*k3v);
	%
	%	u(i+1) = u(i) + (h / 6) * (k1u + 2*k2u + 2*k3u + k4u); 
	%	v(i+1) = v(i) + (h / 6) * (k1v + 2*k2v + 2*k3v + k4v); 
	
    % Entradas:
    % - ~: Argumento não utilizado (pode ser removido)
    % - f: Função que define a derivada de u em relação ao tempo t, ou seja, du/dt = f(t, u, v)
    % - g: Função que define a derivada de v em relação ao tempo t, ou seja, dv/dt = g(t, u, v)
    % - a: Tempo inicial
    % - b: Tempo final
    % - n: Número de passos de integração
    % - u0: Valor inicial de u em t = a
    % - v0: Valor inicial de v em t = a

    % Saídas:
    % - t: Vetor de tempos onde foram calculadas as soluções
    % - u: Vetor de soluções para a variável u
    % - v: Vetor de soluções para a variável v

    h = (b-a)/n; % Calcula o tamanho do passo
    t = a:h:b; % Vetor de tempos desde a até b com incrementos de h
    u = zeros(1,n+1); v = zeros(1,n+1); % Inicializa os vetores de soluções
    u(1) = u0; v(1) = v0; % Estabelece as condições iniciais

    % Ciclo principal de integração
    for i = 1:n
        % Calcula os coeficientes k para u e v usando as funções f e g
        
        k1u = f(t(i), u(i), v(i));
        k1v = g(t(i), u(i), v(i));

        k2u = f(t(i) + h/2, u(i) + h*(k1u/2), v(i) + h*(k1v/2));
        k2v = g(t(i) + h/2, u(i) + h*(k1u/2), v(i) + h*(k1v/2));  

        k3u = f(t(i) + h/2, u(i) + h*(k2u/2), v(i) + h*(k2v/2));  
        k3v = g(t(i) + h/2, u(i) + h*(k2u/2), v(i) + h*(k2v/2));  

        k4u = f(t(i) + h, u(i) + h*k3u, v(i) + h*k3v);
        k4v = g(t(i) + h, u(i) + h*k3u, v(i) + h*k3v);

        % Atualiza os valores de u e v no próximo passo de tempo
        u(i+1) = u(i) + (h / 6) * (k1u + 2*k2u + 2*k3u + k4u); 
        v(i+1) = v(i) + (h / 6) * (k1v + 2*k2v + 2*k3v + k4v); 
    end            
end
