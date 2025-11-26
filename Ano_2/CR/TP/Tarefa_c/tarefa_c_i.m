function tarefa_c_i()
    clear all; close all;

    SomaPrecisaoTeste = 0;
    SomaTempo = 0;

    % Carregar dados apenas da pasta "test"
    [p, t] = loadImagensGeometricas('test');  

     % Carregar rede treinada
    nomeFicheiro = '../Tarefa_b/rede_3.mat'; % rede_1.mat , rede_2.mat , rede_3.mat
    if isfile(nomeFicheiro)
        load(nomeFicheiro, 'net');
    else
        warning('Ficheiro %s não encontrado. A saltar ...', nomeFicheiro);
        return;
    end

    for i = 1:10
        tic;

        % Simular rede com dados da pasta test
        y = sim(net, p);

        % Cálculo da precisão
        [~, pred] = max(y);
        [~, real] = max(t);
        precisaoTeste = sum(pred == real) / numel(real);
        SomaPrecisaoTeste = SomaPrecisaoTeste + precisaoTeste;

        % Mostrar resultados
        fprintf('Rede_1 - Iteração %d - Precisão Teste: %.2f%%\n',i , precisaoTeste * 100);

         % Tempo
        tempoExecucao = toc;
        SomaTempo = SomaTempo + tempoExecucao;
        
        if i == 10
            figure;
            plotconfusion(t, y);
            title(sprintf('Matriz de Confusão - Rede %d', i));
        end

    end

    % Resultados finais
    mediaPrecisao = SomaPrecisaoTeste / 10;
    mediaTempo = SomaTempo / 10;
    fprintf('\nPrecisão média no conjunto TEST (sem treinar): %.2f%%\n', mediaPrecisao * 100);
    fprintf('Tempo médio por execução: %.2f segundos\n', mediaTempo);
    fprintf('Tempo total da execução: %.2f segundos\n', SomaTempo);
end
