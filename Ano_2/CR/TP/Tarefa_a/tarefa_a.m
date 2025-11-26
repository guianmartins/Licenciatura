function tarefa_a()
    clear all;
    SomaPrecisao = 0;
    SomaTempo = 0;

    for i = 1:10
        % Limpar figuras
        close all;

        % Medir tempo de execução desta iteração
        tic;

        % Carregar dados
        [p, t] = loadImagensGeometricas();

        % Criar RN feedforward com 10 neurónios na camada escondida
        net = feedforwardnet([10,10,10]);

        % Configurar parâmetros
        net.layers{1}.transferFcn = 'tansig';
        net.layers{2}.transferFcn = 'tansig';
        net.layers{3}.transferFcn = 'tansig';
        net.layers{4}.transferFcn = 'purelin';
        net.trainFcn = 'trainlm';
        net.trainParam.epochs = 100;
        net.divideFcn = '';

        % Treinar a rede
        [net, tr] = train(net, p, t);

        % Simular a rede
        %y = net(p);
        y = sim(net, p);
        % Calcular erro e precisão
        erro = perform(net, t, y);
        [~, predicted] = max(y);
        [~, expected] = max(t);
        precisao = sum(predicted == expected) / numel(expected);
        SomaPrecisao = SomaPrecisao + precisao;

        % Calcular tempo da iteração
        tempoExecucao = toc;
        SomaTempo = SomaTempo + tempoExecucao;

        % Resultados da iteração
        fprintf('Iteração %d - Erro: %.6e - Precisão: %.2f%% - Tempo: %.2fs\n', ...
                i, erro, precisao * 100, tempoExecucao);
    end

    % Mostrar médias finais
    mediaPrecisao = SomaPrecisao / 10;
    mediaTempo = SomaTempo / 10;
    fprintf('\nPrecisão média após 10 execuções: %.2f%%\n', mediaPrecisao * 100);
    fprintf('Tempo médio por execução: %.2f segundos\n', mediaTempo);
    fprintf('Tempo total da execução: %.2f segundos\n', SomaTempo);
end
