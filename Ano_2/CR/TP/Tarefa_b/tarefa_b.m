function tarefa_b()
    clear all;
    SomaPrecisaoGlobal = 0;
    SomaPrecisaoTeste = 0;
    SomaTempo = 0;

    % Variáveis para plotconfusion final
    tFinal = [];
    yFinal = [];
    for i = 1:10
        % Limpar figuras
        close all;

        % Medir tempo de execução desta iteração
        tic;

        % Carregar dados
        [p, t] = loadImagensGeometricas();

        % Criar RN feedforwamrd com 10 neurónios na camada escondida
        net = feedforwardnet([10,10]);

        % Configurar parâmetros
        net.layers{1}.transferFcn = 'logsig';
        net.layers{2}.transferFcn = 'logsig';
        net.layers{3}.transferFcn = 'purelin';
        net.trainFcn = 'trainlm';
        net.trainParam.epochs = 100;
        net.divideFcn = 'dividerand';
        net.divideParam.trainRatio = 0.7;
        net.divideParam.valRatio = 0.15;
        net.divideParam.testRatio = 0.15;

        % Treinar a rede
        [net, tr] = train(net, p, t);

        % Simular a rede global
        y = sim(net, p);
        erro = perform(net, t, y);

        [~, predicted] = max(y);
        [~, expected] = max(t);
        precisao = sum(predicted == expected) / numel(expected);
        SomaPrecisaoGlobal = SomaPrecisaoGlobal + precisao;

        % Conjunto de teste
        pTeste = p(:, tr.testInd);
        tTeste = t(:, tr.testInd);
        yTeste = sim(net, pTeste);
        [~, predTeste] = max(yTeste);
        [~, realTeste] = max(tTeste);
        precisaoTeste = sum(predTeste == realTeste) / numel(realTeste);
        SomaPrecisaoTeste = SomaPrecisaoTeste + precisaoTeste;

        % Guardar teste final para plotconfusion
        if i == 10
            tFinal = t;
            yFinal = y;
        end

        % Tempo
        tempoExecucao = toc;
        SomaTempo = SomaTempo + tempoExecucao;

        % Resultados
        fprintf('Iteração %d - Erro: %.6e - Precisão Global: %.2f%% - Tempo: %.2fs\n', ...
                i, erro, precisao * 100, tempoExecucao);
        fprintf('Precisão Teste:  %.2f%%\n', precisaoTeste * 100);
    end

    % Médias finais
    mediaPrecisaoGlobal = SomaPrecisaoGlobal / 10;
    mediaPrecisaoTeste = SomaPrecisaoTeste / 10;
    mediaTempo = SomaTempo / 10;

    fprintf('\nPrecisão média Global após 10 execuções: %.2f%%\n', mediaPrecisaoGlobal * 100);
    fprintf('Precisão média Teste após 10 execuções: %.2f%%\n', mediaPrecisaoTeste * 100);
    fprintf('Tempo médio por execução: %.2f segundos\n', mediaTempo);
    fprintf('Tempo total da execução: %.2f segundos\n', SomaTempo);

    %save('rede_3.mat', 'net'); % salvar rede neuronal
    % Mostrar matriz de confusão final
    figure;
    plotconfusion(tFinal, yFinal);
    title('Matriz de Confusão - Última Execução');
end
