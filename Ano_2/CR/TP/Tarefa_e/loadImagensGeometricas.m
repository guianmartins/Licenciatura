function [in, t] = loadImagensGeometricas(subpasta)
    if nargin < 1
        subpasta = 'test';  
    end

   
    pasta = subpasta;

    tiposFormas = {'circle', 'kite', 'parallelogram', 'square', 'trapezoid', 'triangle'};
    numClasses = numel(tiposFormas);
    tamanhoImagem = [20, 20];
    in = [];
    t = [];

    for classe = 1:numClasses
        pastaClasse = fullfile(pasta, tiposFormas{classe});
        ficheiros = dir(fullfile(pastaClasse, '*.png'));

        for i = 1:length(ficheiros)
            caminhoImagem = fullfile(pastaClasse, ficheiros(i).name);
            img = imread(caminhoImagem);

            if ndims(img) == 3
                img = rgb2gray(img);
            end

            img = imresize(img, tamanhoImagem);
            img = im2double(img);
            imgBin = img > 0.5;
            vetor = reshape(imgBin, [], 1);

            in = [in, vetor];
            alvo = zeros(numClasses, 1);
            alvo(classe) = 1;
            t = [t, alvo];
        end
    end
end