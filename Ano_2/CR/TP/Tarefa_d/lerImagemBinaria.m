function vetor = lerImagemBinaria(caminho)
    img = imread(caminho);

    if ndims(img) == 3
        img = rgb2gray(img);
    end
    img = imresize(img, [20 20]);
    img = im2double(img);
    imgBin = img > 0.5;
    vetor = reshape(imgBin, [], 1);
end
