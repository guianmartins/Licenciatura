function classificarImagemCriada(nomeImagem)
    % Lista das redes
    redes = {'../Tarefa_c/rede_1_c.mat', '../Tarefa_c/rede_2_c.mat', '../Tarefa_c/rede_3_c.mat'};
    categorias = {'Circle', 'Kite', 'Parallelogram', 'Square', 'Trapezoid', 'Triangle'};

    % Carregar imagem desenhada
    vetor = lerImagemBinaria(nomeImagem);

    fprintf('\nClassificação da imagem "%s":\n', nomeImagem);

    for i = 1:length(redes)
        load(redes{i}, 'net');
        y = net(vetor);
        [~, pred] = max(y);
        fprintf(' → Rede %d: %s\n', i, categorias{pred});
      
    end
end
