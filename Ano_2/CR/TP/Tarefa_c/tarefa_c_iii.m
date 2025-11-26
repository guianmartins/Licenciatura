function tarefa_c_iii()
    clear all; close all;

    SomaPrecisaoGlobal = 0;
    SomaPrecisaoTeste = 0;
    SomaTempo = 0;

    % Carregar dados apenas da pasta "test"
    [p, t] = loadTodasImagens();  % Esta função deve carregar imagens da pasta "test"

    nomeFicheiro = '../Tarefa_b/rede_1.mat'; % rede_1.mat , rede_2.mat , rede_3.mat
    if isfile(nomeFicheiro)
        load(nomeFicheiro, 'net');  % carregar a estrutura da rede
    else
        warning('Ficheiro %s não encontrado. A saltar ...', nomeFicheiro);
        return;
    end

    for i = 1:10
        tic;

        % Treinar rede com divisão automática entre treino/teste
        [net, tr] = train(net, p, t);

        % Simular rede com todos os dados (para precisão global)
        y = net(p);
        [~, pred] = max(y);
        [~, real] = max(t);
        precisaoGlobal = sum(pred == real) / numel(real);
        SomaPrecisaoGlobal = SomaPrecisaoGlobal + precisaoGlobal;

        % Simular rede apenas com dados de teste
        pTeste = p(:, tr.testInd);
        tTeste = t(:, tr.testInd);
        yTeste = net(pTeste);
        [~, predTeste] = max(yTeste);
        [~, realTeste] = max(tTeste);
        precisaoTeste = sum(predTeste == realTeste) / numel(realTeste);
        SomaPrecisaoTeste = SomaPrecisaoTeste + precisaoTeste;

        % Tempo
        tempoExecucao = toc;
        SomaTempo = SomaTempo + tempoExecucao;

        % Mostrar resultados
        fprintf('Iteração %d - Precisão Global: %.2f%% - Precisão Teste: %.2f%% - Tempo: %.2fs\n', ...
                i, precisaoGlobal * 100, precisaoTeste * 100, tempoExecucao);

    end

    % Resultados finais
    mediaPrecisaoGlobal = SomaPrecisaoGlobal / 10;
    mediaPrecisaoTeste = SomaPrecisaoTeste / 10;
    mediaTempo = SomaTempo / 10;

    fprintf('\nPrecisão média Global (treino): %.2f%%\n', mediaPrecisaoGlobal * 100);
    fprintf('Precisão média Teste: %.2f%%\n', mediaPrecisaoTeste * 100);
    fprintf('Tempo médio por execução: %.2f segundos\n', mediaTempo);
    fprintf('Tempo total da execução: %.2f segundos\n', SomaTempo);


    
    % pastas = {'start', 'test', 'train'};
    % 
    % for p = 1:length(pastas)
    %     nomePasta = pastas{p};
    %     SomaPrecisao = 0;
    %     SomaTempo = 0;
    % 
    %     fprintf('\n--- Avaliação com imagens da pasta "%s" (10 execuções) ---\n', nomePasta);
    % 
    %     for i = 1:10
    %         % Carregar dados da pasta atual
    %         [pPasta, tPasta] = loadImagensGeometricas(nomePasta);
    % 
    %         % Simular rede com esses dados
    %         tic;
    %         yPasta = net(pPasta);
    %         tempoExecucao = toc;
    %         SomaTempo = SomaTempo + tempoExecucao;
    % 
    %         % Calcular precisão
    %         [~, predPasta] = max(yPasta);
    %         [~, realPasta] = max(tPasta);
    %         precisaoPasta = sum(predPasta == realPasta) / numel(realPasta);
    %         SomaPrecisao = SomaPrecisao + precisaoPasta;
    % 
    %         fprintf('Iteração %d - Precisão: %.2f%% - Tempo: %.2fs\n', ...
    %                 i, precisaoPasta * 100, tempoExecucao);
    %     end
    % 
    %     % Mostrar matriz de confusão da última iteração
    %     figure;
    %     plotconfusion(tPasta, yPasta);
    %     title(['Matriz de Confusão - Pasta "', nomePasta, '"']);
    % 
    %     % Resultados finais para a pasta
    %     mediaPrecisao = SomaPrecisao / 10;
    %     mediaTempo = SomaTempo / 10;
    % 
    %     fprintf('\nResultados finais para pasta "%s":\n', nomePasta);
    %     fprintf('→ Precisão média: %.2f%%\n', mediaPrecisao * 100);
    %     fprintf('→ Tempo total: %.2f segundos\n', SomaTempo);
    %     fprintf('→ Tempo médio por execução: %.2f segundos\n', mediaTempo);
    % end

    save('rede_1_c.mat', 'net'); % salvar rede neuronal
    
end
