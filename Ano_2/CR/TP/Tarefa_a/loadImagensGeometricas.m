function [in, t] = loadImagensGeometricas()
    % Caminho da pasta com imagens (ajusta conforme necessário)
    pasta = 'C:\Users\Daniel\Desktop\2ºAno\2_semestre\CR\TP\ImagesFolder\start';

    % Nomes das subpastas correspondentes às classes
    tiposFormas = {'circle', 'kite', 'parallelogram', 'square', 'trapezoid', 'triangle'};
    numClasses = numel(tiposFormas);

    % Parâmetros
    tamanhoImagem = [20, 20];  % Tamanho padrão para redimensionamento
    in = [];                   % Entradas (colunas = imagens)
    t = [];                    % Alvos (one-hot)

    for classe = 1:numClasses
        pastaClasse = fullfile(pasta, tiposFormas{classe});
        ficheiros = dir(fullfile(pastaClasse, '*.png'));

        

        for i = 1:length(ficheiros)
            caminhoImagem = fullfile(pastaClasse, ficheiros(i).name);
            img = imread(caminhoImagem);

             % Converter para grayscale, se necessário
            if ndims(img) == 3
                img = rgb2gray(img);
            end

            img = imresize(img, tamanhoImagem);
            img = im2double(img);           % Normalizar para [0,1]
            imgBinaria = img > 0.5;         % Binarizar
            vetor = reshape(imgBinaria, [], 1);  % Flatten

            in = [in, vetor];               % Adicionar à matriz de entrada

            alvo = zeros(numClasses, 1);
            alvo(classe) = 1;
            t = [t, alvo];                  % Adicionar à matriz de alvos
        end
    end
end
