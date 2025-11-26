-- ===============================================FUNCTIONS =======================================================


-- Função que calcula a distância linear (em km) entre dois pontos na Terra
-- Dados os pares de coordenadas geográficas (latitude e longitude) dos dois pontos
-- Utiliza a fórmula do haversine para calcular a distância sobre a superfície terrestre

CREATE OR REPLACE FUNCTION distancia_linear(LAT1  NUMBER, LON1  NUMBER, LAT2  NUMBER, LON2  NUMBER) 
RETURN NUMBER
IS
    R NUMBER := 6371; -- Raio da Terra em quilómetros
    PI CONSTANT NUMBER := 3.141592653589793; -- Valor de ? (pi)
    D_LAT NUMBER; -- Diferença de latitude em radianos
    D_LON NUMBER; -- Diferença de longitude em radianos
    A NUMBER; -- Parte da fórmula do haversine
    D NUMBER; -- Distância final em km
BEGIN
    -- Conversão das diferenças de latitude e longitude para radianos
    D_LAT := (LAT2 - LAT1) * PI / 180;
    D_LON := (LON2 - LON1) * PI / 180;

    -- Cálculo da fórmula do haversine
    A := SIN(D_LAT/2) * SIN(D_LAT/2) 
       + COS(LAT1*PI/180) * COS(LAT2*PI/180) 
       * SIN(D_LON/2) * SIN(D_LON/2);

    -- Cálculo da distância final
    D := R * (2 * ATAN2(SQRT(A), SQRT(1 - A)));

    -- Retorna a distância arredondada a 3 casas decimais
    RETURN ROUND(D,3);
END;
/   


-- Função que calcula a quantidade de produto em falta numa determinada máquina
-- Verifica se os códigos da máquina e do produto existem
-- Se existirem, calcula a diferença entre a capacidade máxima do compartimento e a quantidade atual

CREATE OR REPLACE FUNCTION quantidade_em_falta(idmaquina NUMBER, idproduto NUMBER) 
RETURN NUMBER
IS
    quantidade_maxima NUMBER; -- Capacidade máxima do compartimento
    quantidade_existente NUMBER; -- Quantidade atual do compartimento
    quantidade_falta  NUMBER := 0; -- Valor a retornar
    verifica_maq NUMBER; -- Verificação de existência da máquina
    verifica_prod NUMBER; -- Verificação de existência do produto
BEGIN 
    -- Verifica se a máquina existe
    SELECT count(*) INTO verifica_maq FROM maquinas WHERE id_maquina = idmaquina;
    IF verifica_maq = 0 THEN 
        RAISE_APPLICATION_ERROR(-20801, 'Código de máquina inexistente');
    END IF;

    -- Verifica se o produto existe
    SELECT count(*) INTO verifica_prod FROM produtos WHERE id_produto = idproduto;
    IF verifica_prod = 0 THEN 
        RAISE_APPLICATION_ERROR(-20802, 'Código de produto inexistente');
    END IF;

    -- Obtém a capacidade máxima e a quantidade existente do compartimento
    SELECT capacidade_maxima, quantidade_compartimento
    INTO quantidade_maxima , quantidade_existente
    FROM compartimentos
    WHERE id_compartimento = idmaquina AND id_produto = idproduto;

    -- Se a capacidade máxima for superior à quantidade existente, calcula a diferença
    IF quantidade_maxima > quantidade_existente THEN
        quantidade_falta := quantidade_maxima - quantidade_existente; 
    END IF;

    RETURN quantidade_falta;

EXCEPTION
    -- Se não forem encontrados dados, retorna 0 (quantidade_falta já está a 0)
    WHEN NO_DATA_FOUND THEN
        RETURN quantidade_falta;
    -- Em caso de outro erro, propaga a exceção
    WHEN OTHERS THEN
        RAISE;
END;
/



-- Função que calcula a distância entre duas máquinas com base nas suas coordenadas
-- Verifica se ambas as máquinas existem e se são diferentes
-- Caso sejam válidas, utiliza a função distancia_linear para calcular a distância entre elas

CREATE OR REPLACE FUNCTION distancia_entre_maquinas(idmaquina1 NUMBER, idmaquina2 NUMBER) 
RETURN NUMBER
IS 
    verifica_maq1 NUMBER; -- Verificação da existência da primeira máquina
    verifica_maq2 NUMBER; -- Verificação da existência da segunda máquina
    dist_linear NUMBER; -- Distância calculada

    lat_maq1 NUMBER; -- Latitude da primeira máquina
    long_maq1 NUMBER; -- Longitude da primeira máquina

    lat_maq2 NUMBER; -- Latitude da segunda máquina
    long_maq2 NUMBER; -- Longitude da segunda máquina
BEGIN
    -- Verifica se as máquinas são diferentes
    IF idmaquina1 = idmaquina2 THEN
        RAISE_APPLICATION_ERROR(-20810, 'Máquinas inválidas. Devem ser diferentes.');
    END IF;

    -- Verifica a existência das máquinas
    SELECT count(*) INTO verifica_maq1 FROM maquinas WHERE id_maquina = idmaquina1;
    IF verifica_maq1 = 0 THEN 
        RAISE_APPLICATION_ERROR(-20801, 'Código de máquina inexistente');
    END IF;

    SELECT count(*) INTO verifica_maq2 FROM maquinas WHERE id_maquina = idmaquina2;
    IF verifica_maq2 = 0 THEN 
        RAISE_APPLICATION_ERROR(-20801, 'Código de máquina inexistente');
    END IF;

    -- Obtém as coordenadas das duas máquinas
    SELECT longitude, latutude INTO lat_maq1 , long_maq1
    FROM maquinas
    WHERE id_maquina = idmaquina1;

    SELECT longitude, latutude INTO lat_maq2 , long_maq2
    FROM maquinas
    WHERE id_maquina = idmaquina2;

    -- Calcula a distância entre elas usando a função distancia_linear
    dist_linear := distancia_linear(lat_maq1 , long_maq1 , lat_maq2 , long_maq2);

    RETURN dist_linear;
EXCEPTION 
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RAISE;
END;
/


-- Função que identifica a máquina mais próxima (excluindo a atual) sem stock de um dado produto
-- Recebe a referência do produto e o ID da máquina atual
-- Percorre as máquinas com stock 0 para o produto e calcula a mais próxima

CREATE OR REPLACE FUNCTION prox_maquina_sem_produto(p_referencia VARCHAR2, idmaquina NUMBER) 
RETURN NUMBER
IS
    CURSOR maquinas IS
        SELECT c.id_maquina 
        FROM compartimentos c
        WHERE c.id_produto = (SELECT id_produto FROM produtos WHERE referencia = p_referencia)
              AND c.quantidade_compartimento = 0
              AND c.id_maquina != idmaquina;

    verifica_prod NUMBER; -- Verificação da existência do produto
    verifica_maq NUMBER; -- Verificação da existência da máquina

    dist_linear NUMBER; -- Distância calculada
    dist_linear_ant NUMBER := 999999999; -- Valor de referência inicial
    maq_menor_dist NUMBER; -- ID da máquina mais próxima encontrada
BEGIN 
    -- Verifica se a máquina existe
    SELECT count(*) INTO verifica_maq FROM maquinas WHERE id_maquina = idmaquina;
    IF verifica_maq = 0 THEN 
        RAISE_APPLICATION_ERROR(-20801, 'Código de máquina inexistente');
    END IF;

    -- Verifica se o produto existe pela referência
    SELECT count(*) INTO verifica_prod FROM produtos WHERE referencia = p_referencia;
    IF verifica_prod = 0 THEN 
        RAISE_APPLICATION_ERROR(-20802, 'Código de produto inexistente');
    END IF;

    -- Percorre todas as máquinas com stock 0 e calcula a mais próxima
    FOR m IN maquinas LOOP 
        dist_linear := distancia_entre_maquinas(idmaquina, m.id_maquina);
        IF dist_linear < dist_linear_ant THEN 
            dist_linear_ant := dist_linear;
            maq_menor_dist := m.id_maquina;
        END IF;
    END LOOP;

    RETURN maq_menor_dist;
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
/


-- Função que calcula a distância total percorrida numa viagem
-- Com base na rota associada à viagem e nas coordenadas das máquinas e armazém
-- Soma as distâncias entre os pontos da rota (armazém ? máquinas ? armazém)

CREATE OR REPLACE FUNCTION distancia_viagem(idviagem NUMBER) 
RETURN NUMBER
IS
    viagem NUMBER; -- Verificação da existência da viagem
    idrota viagens.id_rota%TYPE; -- ID da rota associada à viagem
    total NUMBER := 0; -- Distância total acumulada
    idarmazem NUMBER; -- ID do armazém de origem
    lon NUMBER; -- Longitude do ponto atual
    lat NUMBER; -- Latitude do ponto atual
    ultimo NUMBER; -- Última ordem da rota
    prox NUMBER; -- ID da máquina seguinte na rota

    -- Cursor que obtém a sequência das máquinas na rota da viagem
    CURSOR c1 IS
        SELECT rd.id_maquina id_maquina, rd.ordem ordem, m.longitude longitude, m.latutude latitude
        FROM rotasdefenidas rd
        JOIN viagens v ON v.id_rota = rd.id_rota
        JOIN maquinas m ON m.id_maquina = rd.id_maquina
        WHERE v.id_viagem = idviagem;
BEGIN
    -- Verifica se a viagem existe
    SELECT count(*) INTO viagem FROM viagens WHERE id_viagem = idviagem;
    IF viagem = 0 THEN
        RAISE_APPLICATION_ERROR(-20807, 'Viagem de abastecimento inexistente');
    END IF;

    -- Obtém as coordenadas do armazém de origem
    SELECT r.id_armazem, a.longitude_a, a.latitude_a 
    INTO idarmazem, lon, lat
    FROM rotas r
    JOIN viagens v ON v.id_rota = r.id_rota
    JOIN armazem a ON a.id_armazem = r.id_armazem
    WHERE v.id_viagem = idviagem;

    -- Determina qual é a última máquina na rota (ordem mais alta)
    SELECT MAX(rd.ordem) INTO ultimo
    FROM rotasdefenidas rd
    JOIN viagens v ON v.id_rota = rd.id_rota
    WHERE v.id_viagem = idviagem;

    -- Percorre as máquinas da rota e acumula as distâncias
    FOR r IN c1 LOOP
        IF r.ordem = 1 THEN
            -- Primeira máquina: calcular distância desde o armazém
            total := distancia_linear(lat, lon, r.latitude, r.longitude);
        ELSIF r.ordem = ultimo THEN
            -- Última máquina: voltar ao armazém (fecha o ciclo)
            total := total + distancia_linear(r.latitude, r.longitude, lat, lon);
        ELSE
            -- Máquinas intermédias: calcular distância entre máquinas consecutivas
            SELECT rd.id_maquina INTO prox 
            FROM rotasdefenidas rd
            JOIN viagens v ON v.id_rota = rd.id_rota
            WHERE v.id_viagem = idviagem AND rd.ordem = r.ordem;

            total := total + distancia_entre_maquinas(r.id_maquina, prox);
        END IF;
    END LOOP;

    RETURN total;
END;
/



-- Função que calcula a quantidade média diária de vendas de um produto numa máquina
-- Considera os dias com vendas entre o segundo reabastecimento em diante

CREATE OR REPLACE FUNCTION quantidade_media_diaria(idmaquina NUMBER, idproduto NUMBER) 
RETURN NUMBER
IS
    num_maquinas NUMBER; -- Verificação da existência da máquina
    num_produtos NUMBER; -- Verificação da existência do produto
    i NUMBER := 1; -- Contador auxiliar
    hora reabastecimentos.data_hora_reabastecimento%TYPE; -- Data do segundo reabastecimento
    ndias NUMBER := 0; -- Número de dias com vendas
    total NUMBER := 0; -- Total de vendas

    -- Cursor que recolhe os reabastecimentos por ordem cronológica
    CURSOR c1 IS 
        SELECT r.data_hora_reabastecimento
        FROM reabastecimentos r 
        JOIN compartimentos c ON r.id_compartimento = c.id_compartimento
        JOIN maquinas m ON c.id_maquina = m.id_maquina
        WHERE m.id_maquina = idmaquina AND r.id_produto = idproduto
        ORDER BY r.data_hora_reabastecimento;

    -- Cursor que conta as vendas por dia após o segundo reabastecimento
    CURSOR c2(dataInicio reabastecimentos.data_hora_reabastecimento%TYPE) IS
        SELECT COUNT(*) AS numVendas
        FROM vendas v
        JOIN compartimentos c ON v.id_compartimento = c.id_compartimento
        JOIN maquinas m ON c.id_maquina = m.id_maquina
        WHERE m.id_maquina = idmaquina
          AND v.data_hora_venda > dataInicio
        GROUP BY TRUNC(v.data_hora_venda);
BEGIN
    -- Verifica se a máquina e o produto existem
    SELECT COUNT(*) INTO num_maquinas FROM maquinas WHERE id_maquina = idmaquina;
    IF num_maquinas = 0 THEN
        RAISE_APPLICATION_ERROR(-20801, 'Código de máquina inexistente');
    END IF;

    SELECT COUNT(*) INTO num_produtos FROM produtos WHERE id_produto = idproduto;
    IF num_produtos = 0 THEN
        RAISE_APPLICATION_ERROR(-20802, 'Código de produto inexistente');
    END IF;

    -- Obtém a data do segundo reabastecimento
    FOR r IN c1 LOOP
        IF i = 2 THEN
            hora := r.data_hora_reabastecimento;
            EXIT;
        END IF;
        i := i + 1;
    END LOOP;

    -- Percorre os dias com vendas após o segundo reabastecimento
    FOR r2 IN c2(hora) LOOP
        total := total + r2.numVendas;
        ndias := ndias + 1;
    END LOOP;

    -- Calcula a média
    IF ndias > 0 THEN
        total := total / ndias;
    ELSE
        total := 0;
    END IF;

    RETURN total;
END;
/



-- Função que calcula a quantidade total de produtos vendidos numa máquina num intervalo de tempo
-- Recebe o ID da máquina, o ID do produto e o intervalo de tempo (data de início e fim)
-- Verifica a existência da máquina e do produto, valida o intervalo temporal e retorna a quantidade vendida

CREATE OR REPLACE FUNCTION quantidade_vendida(idmaquina NUMBER, idproduto NUMBER, dataInicio DATE, dataFim DATE)
RETURN NUMBER
IS
    qnt_vendida NUMBER;
    verif_maq NUMBER;
    verif_prod NUMBER;
BEGIN
    -- Verifica se a máquina existe
    SELECT COUNT(*) INTO verif_maq FROM maquinas WHERE id_maquina = idmaquina;
    IF verif_maq <= 0 THEN
        RAISE_APPLICATION_ERROR(-20801, 'Código de máquina inexistente');
    END IF;
    
    -- Verifica se o produto existe
    SELECT COUNT(*) INTO verif_prod FROM produtos WHERE id_produto = idproduto;
    IF verif_prod <= 0 THEN
         RAISE_APPLICATION_ERROR(-20802, 'Código de produto inexistente');
    END IF; 
    
    -- Valida se o intervalo temporal é válido
    IF dataInicio > dataFim THEN
         RAISE_APPLICATION_ERROR(-20809, 'Inválido intervalo temporal');
    END IF;
    
    -- Calcula a quantidade de produtos vendidos no intervalo de tempo
    SELECT COUNT(c.ID_PRODUTO) INTO qnt_vendida
    FROM COMPARTIMENTOS c, VENDAS v
    WHERE v.id_compartimento = c.id_compartimento 
    AND c.id_maquina = idmaquina
    AND v.id_produto = idproduto
    AND v.data_hora_venda BETWEEN dataInicio AND dataFim;
    
    RETURN qnt_vendida;
END;
/



-- Função que retorna a data do último reabastecimento de um produto numa máquina
-- Recebe o ID da máquina e o ID do produto
-- Verifica a existência da máquina e do produto, e retorna a data mais recente de reabastecimento

CREATE OR REPLACE FUNCTION data_ultimo_abastc(idmaquina NUMBER, idproduto NUMBER) 
RETURN DATE
IS
    data DATE;
    verif_maq NUMBER;
    verif_prod NUMBER;
BEGIN
    -- Verifica se a máquina existe
    SELECT COUNT(*) INTO verif_maq FROM maquinas WHERE id_maquina = idmaquina;
    IF verif_maq <= 0 THEN
        RAISE_APPLICATION_ERROR(-20801, 'Código de máquina inexistente');
    END IF;
    
    -- Verifica se o produto existe
    SELECT COUNT(*) INTO verif_prod FROM produtos WHERE id_produto = idproduto;
    IF verif_prod <= 0 THEN
         RAISE_APPLICATION_ERROR(-20802, 'Código de produto inexistente');
    END IF; 
    
    -- Obtém a data do último reabastecimento para o produto na máquina
    SELECT MAX(r.data_hora_reabastecimento) INTO data
    FROM reabastecimentos r, compartimentos c
    WHERE r.id_compartimento = c.id_compartimento
    AND r.id_produto = idproduto
    AND c.id_maquina = idmaquina;

    RETURN data;
END;
/

 
-- Função que identifica a máquina mais próxima com stock de um produto, com base em coordenadas
-- Recebe o ID do produto e as coordenadas (latitude e longitude) de um ponto
-- Verifica a existência do produto e retorna o ID da máquina mais próxima com stock disponível

CREATE OR REPLACE FUNCTION maquina_mais_proxima(idproduto NUMBER, lat NUMBER, long NUMBER)
RETURN NUMBER
IS
    cod_maq NUMBER;
    distancia NUMBER;
    menor_distancia NUMBER := 99999;
    verif_prod NUMBER;
    CURSOR maquinas IS
        SELECT m.id_maquina, m.latutude, m.longitude 
        FROM maquinas m, compartimentos c
        WHERE c.id_maquina = m.id_maquina
        AND c.id_produto = idproduto
        AND c.quantidade_compartimento > 0;
BEGIN
    -- Verifica se o produto existe
    SELECT COUNT(*) INTO verif_prod FROM produtos WHERE id_produto = idproduto;
    IF verif_prod <= 0 THEN
         RAISE_APPLICATION_ERROR(-20802, 'Código de produto inexistente');
    END IF; 
    
    -- Percorre as máquinas com stock do produto e calcula a mais próxima
    FOR r IN maquinas LOOP
        distancia := distancia_linear(r.latutude, r.longitude, lat, long);
        IF distancia < menor_distancia THEN
            menor_distancia := distancia;
            cod_maq := r.id_maquina;
        END IF;
    END LOOP;  
    RETURN cod_maq;
END;
/





-- =====================================================PROCEDURES ===================================

-- Procedimento que cria uma viagem de abastecimento para máquinas com ruptura de stock
-- Recebe o ID do armazém e um raio (em km) para identificar máquinas próximas
-- Cria uma rota e uma viagem, adicionando até 10 máquinas com maior necessidade de reabastecimento

CREATE OR REPLACE PROCEDURE cria_viagem_abast (cod_armazem NUMBER, raio NUMBER) IS 
    verifica_armazem NUMBER;
    lat_armazem NUMBER; 
    long_armazem NUMBER;
    verifica_maquinas_existentes NUMBER;
    prox_id_rota NUMBER;
    prox_id_viagem NUMBER; 
    ordem NUMBER := 1;
    dist_total NUMBER := 0;
    
    CURSOR maquinas_ruptura (lat_a NUMBER, long_a NUMBER) IS
        SELECT 
            c.id_maquina,
            SUM(c.capacidade_maxima - c.quantidade_compartimento) AS quantidade_falta
        FROM compartimentos c, maquinas m
        WHERE c.id_maquina = m.id_maquina
        AND c.quantidade_compartimento < c.capacidade_maxima
        AND distancia_linear(lat_a, long_a, m.latutude, m.longitude) <= raio
        GROUP BY c.id_maquina
        ORDER BY quantidade_falta DESC;
        
BEGIN 
    -- Verifica se o armazém existe
    SELECT count(*) INTO verifica_armazem FROM armazem WHERE id_armazem = cod_armazem; 
    IF verifica_armazem = 0 THEN
        RAISE_APPLICATION_ERROR(-20806, 'Código de armazém inexistente');
    END IF;
    
    -- Obtém as coordenadas do armazém
    SELECT latitude_a INTO lat_armazem FROM armazem WHERE id_armazem = cod_armazem;
    SELECT longitude_a INTO long_armazem FROM armazem WHERE id_armazem = cod_armazem;
    
    -- Valida se o raio é positivo
    IF raio <= 0 THEN 
         RAISE_APPLICATION_ERROR(-20811, 'Distância Inválida');
    END IF;
    
    -- Verifica se existem máquinas com ruptura de stock no raio definido
    SELECT COUNT(DISTINCT c.id_maquina)
    INTO verifica_maquinas_existentes
    FROM compartimentos c, maquinas m
    WHERE c.id_maquina = m.id_maquina
    AND c.quantidade_compartimento < c.capacidade_maxima
    AND distancia_linear(lat_armazem, long_armazem, m.latutude, m.longitude) <= raio;

    IF verifica_maquinas_existentes = 0 THEN
        RAISE_APPLICATION_ERROR(-20815, 'Não existem máquinas num raio de ' || raio || ' km');
    END IF;
    
    -- Gera IDs para a nova rota e viagem
    SELECT NVL(MAX(id_rota), 0) + 1 INTO prox_id_rota FROM rotas;
    SELECT NVL(MAX(id_viagem), 0) + 1 INTO prox_id_viagem FROM viagens;
    
    -- Cria uma nova rota com um nome baseado no armazém e na data atual
    INSERT INTO rotas (id_rota, id_armazem, nome_rota, rotakm)
    VALUES (prox_id_rota, cod_armazem, 'Rota_Abast_' || cod_armazem || '_' || TO_CHAR(SYSDATE, 'YYYYMMDDHH24MI'), 0);
    
    -- Cria uma nova viagem associada à rota
    INSERT INTO viagens (id_viagem, id_rota, id_veiculo, id_funcionario, data_inicio_viagem, distancia_percorrida, data_fim_viagem)
    VALUES (prox_id_viagem, prox_id_rota, NULL, NULL, SYSDATE, 0, NULL);
    
    -- Adiciona até 10 máquinas com maior necessidade à rota
    FOR maq IN maquinas_ruptura (lat_armazem, long_armazem) LOOP
        EXIT WHEN ordem = 11;
        INSERT INTO rotasdefenidas (id_maquina, id_rota, ordem)
        VALUES (maq.id_maquina, prox_id_rota, ordem);
        ordem := ordem + 1;
    END LOOP;
    
    -- Calcula a distância total da viagem e atualiza a rota
    dist_total := distancia_viagem(prox_id_viagem);
    UPDATE rotas SET rotakm = dist_total WHERE id_rota = prox_id_rota;
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
/




-- Procedimento que abastece um produto em máquinas com stock insuficiente
-- Recebe o ID do armazém, o ID do produto e a quantidade a distribuir
-- Cria uma rota e uma viagem, distribuindo a quantidade pelas máquinas com maior necessidade

CREATE OR REPLACE PROCEDURE abastece_produto(cod_armazem NUMBER, cod_produto NUMBER, quantidade NUMBER)
IS
    num_produtos NUMBER;
    idarmazem NUMBER;
    restante NUMBER;
    proxrota NUMBER;
    proxviagem NUMBER;
    proxvisita NUMBER;
    proxreabastecimento NUMBER;
    qtemfalta NUMBER := quantidade;
    ordem NUMBER := 1;
    distancia NUMBER;
    quantidade_abastecer NUMBER;
    
    CURSOR c1 IS
        SELECT c.id_compartimento, c.id_maquina, SUM(c.capacidade_maxima - c.quantidade_compartimento) AS quantidade_falta
        FROM compartimentos c, maquinas m
        WHERE c.id_maquina = m.id_maquina
        AND c.quantidade_compartimento < c.capacidade_maxima
        AND id_produto = cod_produto
        GROUP BY c.id_compartimento, c.id_maquina
        ORDER BY quantidade_falta DESC;
        
BEGIN
    -- Verifica se o produto existe
    SELECT COUNT(*) INTO num_produtos FROM produtos WHERE id_produto = cod_produto;
    IF num_produtos = 0 THEN
        RAISE_APPLICATION_ERROR(-20802, 'Código de produto inexistente');
    END IF;
        
    -- Verifica se o armazém existe
    SELECT COUNT(*) INTO idarmazem FROM armazem WHERE id_armazem = cod_armazem;
    IF idarmazem = 0 THEN
        RAISE_APPLICATION_ERROR(-20806, 'Código de armazém inexistente');
    END IF;
    
    -- Valida se a quantidade é positiva
    IF quantidade <= 0 THEN
        RAISE_APPLICATION_ERROR(-20813, 'Quantidade inválida');
    END IF;
    
    -- Gera IDs para a nova rota
    SELECT NVL(MAX(id_rota), 0) + 1 INTO proxrota FROM rotas;
    INSERT INTO rotas (id_rota, id_armazem, nome_rota, rotakm) 
    VALUES (proxrota, cod_armazem, 'Rota_Abast_' || cod_armazem || '_' || TO_CHAR(SYSDATE, 'YYYYMMDDHH24MI'), 0);
    
    -- Cria uma nova viagem associada à rota
    SELECT NVL(MAX(id_viagem), 0) + 1 INTO proxviagem FROM viagens;
    INSERT INTO viagens (id_viagem, id_rota) VALUES (proxviagem, proxrota);
    
    -- Distribui a quantidade pelas máquinas com maior necessidade
    FOR r IN c1 LOOP
        EXIT WHEN qtemfalta <= 0;
        quantidade_abastecer := LEAST(r.quantidade_falta, qtemfalta);
        
        -- Atualiza a quantidade no compartimento
        UPDATE compartimentos
        SET quantidade_compartimento = quantidade_compartimento + quantidade_abastecer
        WHERE id_compartimento = r.id_compartimento;
        
        -- Adiciona a máquina à rota
        INSERT INTO rotasdefenidas VALUES (r.id_maquina, proxrota, ordem);
        ordem := ordem + 1;
        qtemfalta := qtemfalta - quantidade_abastecer;
    END LOOP;
    
    -- Calcula a distância total da viagem e atualiza a rota
    distancia := distancia_viagem(proxviagem);
    UPDATE rotas SET rotakm = distancia WHERE id_rota = proxrota;
END;
/


-- Procedimento que cria encomendas de produtos com base nas vendas de máquinas associadas a um armazém
-- Recebe o ID do armazém e uma data de início
-- Calcula a média de vendas semanais, verifica o stock existente e cria encomendas se necessário

CREATE OR REPLACE PROCEDURE encomenda_produtos (cod_armazem NUMBER, datainicio DATE)
IS
    CURSOR produtos_maquinas IS
        SELECT DISTINCT v.id_produto
        FROM vendas v, maquinas m, rotasdefenidas rd, compartimentos c, rotas r
        WHERE c.id_compartimento = v.id_compartimento
        AND c.id_maquina = m.id_maquina
        AND m.id_maquina = rd.id_maquina
        AND r.id_armazem = cod_armazem
        AND v.data_hora_venda >= datainicio;
    
    qnt_vendida NUMBER;
    qnt_existente NUMBER;
    qnt_stock NUMBER;
    media NUMBER;  
    qnt_encomenda NUMBER;
    verif_arm NUMBER;
    cod_encomendas NUMBER;
    n_dias NUMBER;
BEGIN
    -- Verifica se o armazém existe
    SELECT COUNT(*) INTO verif_arm FROM armazem WHERE id_armazem = cod_armazem;
    IF verif_arm <= 0 THEN
        RAISE_APPLICATION_ERROR(-20806, 'Código de armazém inexistente');
    END IF;
    
    -- Valida se a data de início é anterior à data atual
    IF datainicio > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20812, 'Data inválida. Deve ser anterior à data atual.');
    END IF;
    
    -- Calcula o número de dias desde a data de início
    n_dias := TRUNC(SYSDATE - datainicio) + 1;
    IF n_dias <= 0 THEN
        n_dias := 1;
    END IF;
    
    -- Para cada produto vendido em máquinas associadas ao armazém
    FOR x IN produtos_maquinas LOOP
        -- Calcula o total de vendas do produto
        SELECT NVL(SUM(v.valor_pago), 0) INTO qnt_vendida
        FROM vendas v, compartimentos c, maquinas m, rotasdefenidas rd, rotas r 
        WHERE v.id_compartimento = c.id_compartimento
        AND c.id_maquina = m.id_maquina
        AND rd.id_maquina = m.id_maquina
        AND rd.id_rota = r.id_rota
        AND r.id_armazem = cod_armazem
        AND c.id_produto = x.id_produto
        AND v.data_hora_venda >= datainicio;
        
        -- Obtém a quantidade total nos compartimentos
        SELECT NVL(SUM(c.quantidade_compartimento), 0) INTO qnt_existente
        FROM compartimentos c, maquinas m, rotasdefenidas rd, rotas r
        WHERE c.id_maquina = m.id_maquina
        AND rd.id_maquina = m.id_maquina
        AND r.id_armazem = cod_armazem
        AND c.id_produto = x.id_produto;
        
        -- Obtém a quantidade em stock no armazém
        SELECT NVL(quantidade_em_stock, 0) INTO qnt_stock
        FROM stock
        WHERE id_produto = x.id_produto
        AND id_armazem = cod_armazem;
        
        -- Calcula a média semanal de vendas
        media := (qnt_vendida * 7) / n_dias;
        
        -- Determina a quantidade a encomendar
        qnt_encomenda := media - (qnt_existente + qnt_stock);
        
        -- Gera um novo ID para a encomenda
        SELECT seq_encomendas.NEXTVAL INTO cod_encomendas FROM dual;
        
        -- Cria a encomenda se a quantidade for positiva
        IF qnt_encomenda > 0 THEN
            INSERT INTO encomendas VALUES (x.id_produto, cod_armazem, cod_encomendas, SYSDATE, qnt_encomenda);
        END IF;
    END LOOP;
END;
/

-- =======================================================TRIGGERS ===================================

-- Trigger que atualiza a quantidade de produtos numa viagem após um reabastecimento
-- Verifica se há quantidade suficiente na viagem para o reabastecimento
-- Atualiza a quantidade disponível na tabela produto_viagem

CREATE OR REPLACE TRIGGER update_viagem 
AFTER INSERT ON reabastecimentos
FOR EACH ROW
DECLARE
    viagem NUMBER; 
    quantidade_vig NUMBER;
BEGIN 
    -- Obtém o ID da viagem associada à visita
    SELECT id_viagem INTO viagem
    FROM visitas 
    WHERE id_visita = :NEW.id_visita;
        
    -- Obtém a quantidade disponível na viagem para o produto
    SELECT quantidade_pv INTO quantidade_vig
    FROM produto_viagem
    WHERE id_viagem = viagem AND id_produto = :NEW.id_produto;
    
    -- Verifica se há quantidade suficiente na viagem
    IF quantidade_vig < :NEW.quantidade_reabastecimento THEN
        RAISE_APPLICATION_ERROR(-20826, 'Quantidade insuficiente na viagem para este reabastecimento');
    END IF;
    
    -- Atualiza a quantidade disponível na viagem
    UPDATE produto_viagem 
    SET quantidade_pv = quantidade_pv - :NEW.quantidade_reabastecimento 
    WHERE id_viagem = viagem AND id_produto = :NEW.id_produto;  
EXCEPTION
    WHEN NO_DATA_FOUND THEN 
         RAISE_APPLICATION_ERROR(-20807, 'Viagem de abastecimento inexistente');
    WHEN OTHERS THEN
        RAISE;
END; 
/


-- Trigger que valida a quantidade de reabastecimento antes da inserção
-- Verifica se a quantidade a reabastecer é válida e não excede a capacidade máxima do compartimento

CREATE OR REPLACE TRIGGER abastece
BEFORE INSERT ON REABASTECIMENTOS
FOR EACH ROW
DECLARE
    capacidade_max NUMBER;
    qtatual NUMBER;
BEGIN
    -- Verifica se a quantidade de reabastecimento é válida
    IF :NEW.QUANTIDADE_REABASTECIMENTO <= 0 THEN
        RAISE_APPLICATION_ERROR(-20813, 'Quantidade inválida');
    END IF;

    -- Obtém a capacidade máxima e a quantidade atual do compartimento
    SELECT c.CAPACIDADE_MAXIMA, c.QUANTIDADE_COMPARTIMENTO
    INTO capacidade_max, qtatual
    FROM COMPARTIMENTOS c
    WHERE c.ID_COMPARTIMENTO = :NEW.ID_COMPARTIMENTO;

    -- Verifica se a quantidade a reabastecer não excede a capacidade máxima
    IF :NEW.QUANTIDADE_REABASTECIMENTO + qtatual > capacidade_max THEN
        RAISE_APPLICATION_ERROR(-20825, 'Quantidade excede capacidade maxima');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20819, 'Compartimento não encontrado');
    WHEN OTHERS THEN
        RAISE;
END;
/


-- Trigger que atualiza o stock e o estado da máquina após uma venda
-- Ativado após a inserção de uma venda, diminui a quantidade no compartimento
-- Se a quantidade chegar a zero, atualiza o estado da máquina para 'SEM STOCK'

CREATE OR REPLACE TRIGGER update_stock
AFTER INSERT ON vendas
FOR EACH ROW
DECLARE
    qnt_compartimento NUMBER;
BEGIN
    -- Diminui a quantidade no compartimento
    UPDATE compartimentos
    SET quantidade_compartimento = quantidade_compartimento - 1 
    WHERE id_compartimento = :NEW.id_compartimento;
    
    -- Verifica a quantidade restante no compartimento
    SELECT quantidade_compartimento INTO qnt_compartimento
    FROM compartimentos
    WHERE id_produto = :NEW.id_produto
    AND id_compartimento = :NEW.id_compartimento;
    
    -- Se a quantidade for zero, atualiza o estado da máquina
    IF qnt_compartimento = 0 THEN
        UPDATE maquinas
        SET estado_maquina = 'SEM STOCK'
        WHERE id_maquina = (SELECT id_maquina FROM compartimentos WHERE id_compartimento = :NEW.id_compartimento);
    END IF;
END;
/






-- ==============================================PROPOSTAS ===========================================

-- Função que calcula o tempo médio (em minutos) de visitas de um funcionário
-- Recebe o ID do funcionário e retorna a média de tempo entre chegada e saída das visitas
-- Verifica a existência do funcionário e retorna 0 se não houver dados

CREATE OR REPLACE FUNCTION P_FUNC_2023144551(idfuncionario NUMBER) RETURN NUMBER
IS
    tempo_medio NUMBER;
    verifica_func NUMBER;
BEGIN
    -- Verifica se o funcionário existe
    SELECT COUNT(*)
    INTO verifica_func
    FROM funcionarios
    WHERE id_funcionario = idfuncionario;

    IF verifica_func = 0 THEN
        RAISE_APPLICATION_ERROR(-20814, 'Código de funcionário inexistente');
    END IF;

    -- Calcula o tempo médio das visitas (em dias) e converte para minutos
    SELECT AVG((data_hora_saida - data_hora_chegada))
    INTO tempo_medio
    FROM visitas v, viagens vg
    WHERE v.ID_VIAGEM = vg.ID_VIAGEM 
    AND vg.ID_FUNCIONARIO = idfuncionario;
    
    tempo_medio := tempo_medio * 24 * 60;
    
    IF tempo_medio > 0 THEN
        RETURN tempo_medio;
    ELSE 
        RETURN 0;
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RAISE;
END;
/


-- Procedimento que transfere produtos entre armazéns
-- Recebe o ID do armazém de origem, destino, o ID do produto e a quantidade a transferir
-- Verifica a validade dos armazéns, do produto e a disponibilidade de stock, atualizando os stocks

CREATE OR REPLACE PROCEDURE Q_PROC_2023144551 (cod_armazem_origem NUMBER, cod_armazem_destino NUMBER, idProduto NUMBER, quantidade NUMBER)
IS
    verifica_armazem_origem NUMBER;
    verifica_armazem_destino NUMBER;
    verifica_produto NUMBER;
    stock_origem NUMBER;
    stock_destino NUMBER;
BEGIN
    -- Verifica se os armazéns são diferentes
    IF cod_armazem_origem = cod_armazem_destino THEN
        RAISE_APPLICATION_ERROR(-20816, 'Transferência inválida: armazéns origem e destino devem ser diferentes');
    END IF;

    -- Verifica se a quantidade é válida
    IF quantidade <= 0 THEN
        RAISE_APPLICATION_ERROR(-20817, 'Quantidade a transferir deve ser maior que zero');
    END IF;

    -- Verifica se o armazém de origem existe
    SELECT COUNT(*) INTO verifica_armazem_origem FROM armazem WHERE id_armazem = cod_armazem_origem;
    IF verifica_armazem_origem = 0 THEN
        RAISE_APPLICATION_ERROR(-20806, 'Código de armazém inexistente');
    END IF;

    -- Verifica se o armazém de destino existe
    SELECT COUNT(*) INTO verifica_armazem_destino FROM armazem WHERE ID_ARMAZEM = cod_armazem_destino;
    IF verifica_armazem_destino = 0 THEN
        RAISE_APPLICATION_ERROR(-20806, 'Código de armazém inexistente');
    END IF;

    -- Verifica se o produto existe
    SELECT COUNT(*) INTO verifica_produto FROM produtos WHERE id_produto = idProduto;
    IF verifica_produto = 0 THEN
        RAISE_APPLICATION_ERROR(-20802, 'Código de produto inexistente');
    END IF;
    
    -- Obtém o stock do armazém de origem
    BEGIN
        SELECT NVL(quantidade_em_stock, 0) INTO stock_origem FROM stock WHERE id_armazem = cod_armazem_origem AND id_produto = idProduto;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            stock_origem := 0; 
    END;
    
    -- Verifica se há stock suficiente no armazém de origem
    IF stock_origem < quantidade THEN
        RAISE_APPLICATION_ERROR(-20818, 'Quantidade insuficiente no armazém');
    END IF;

    -- Obtém o stock do armazém de destino
    BEGIN
        SELECT NVL(quantidade_em_stock, 0) INTO stock_destino FROM stock WHERE id_armazem = cod_armazem_destino AND id_produto = idProduto;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            stock_destino := 0; 
    END;
   
    -- Atualiza o stock do armazém de origem
    UPDATE stock
    SET quantidade_em_stock = quantidade_em_stock - quantidade
    WHERE id_armazem = cod_armazem_origem
    AND id_produto = idProduto;

    -- Atualiza ou insere o stock no armazém de destino
    IF stock_destino > 0 THEN
        UPDATE stock
        SET quantidade_em_stock = quantidade_em_stock + quantidade
        WHERE id_armazem = cod_armazem_destino
        AND id_produto = idProduto;
    ELSE
        INSERT INTO stock (id_produto, id_armazem, quantidade_em_stock)
        VALUES (idProduto, cod_armazem_destino, quantidade);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
/


-- Trigger que valida a autonomia do veículo antes de associá-lo a uma viagem
-- Verifica se a distância da rota é inferior à autonomia do veículo
-- Ativado antes da inserção ou atualização do veículo numa viagem

CREATE OR REPLACE TRIGGER R_TRIG_2023144551
BEFORE INSERT OR UPDATE OF id_veiculo ON VIAGENS
FOR EACH ROW
DECLARE
    dist_total NUMBER;
    autonomia NUMBER;
BEGIN 
    -- Se o veículo for nulo, não valida
    IF :NEW.id_veiculo IS NULL THEN
        RETURN;
    END IF;
    
    -- Obtém a autonomia do veículo
    SELECT autonomia_km
    INTO autonomia
    FROM veiculos
    WHERE id_veiculo = :NEW.id_veiculo;

    -- Obtém a distância total da rota
    SELECT NVL(rotakm, 0) INTO dist_total FROM rotas WHERE id_rota = :NEW.id_rota;
    
    -- Verifica se a distância está definida
    IF dist_total = 0 THEN
        RAISE_APPLICATION_ERROR(-20827, 'Distancia nao esta definida na rota');
    END IF;
    
    -- Verifica se a autonomia é suficiente
    IF dist_total > autonomia THEN
        RAISE_APPLICATION_ERROR(-20821, 'Autonomia do veículo insuficiente para a distância da rota');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20822, 'Rota ou veículo não encontrado');
    WHEN OTHERS THEN
        RAISE;
END;
/



-- Função que calcula a média diária de rupturas de stock num intervalo de tempo
-- Recebe as datas de início e fim e retorna a média de rupturas por dia
-- Considera apenas os dias com rupturas registadas no intervalo

CREATE OR REPLACE FUNCTION P_FUNC_2023144606(dataInicio DATE, dataFim DATE) RETURN NUMBER
IS
    nDias NUMBER := 0;
    media NUMBER := 0;
    CURSOR c1 IS
        SELECT TRUNC(data_hora_ruptura) AS data_ruptura, 
               COUNT(id_ruptura) AS numero
        FROM rupturas
        WHERE data_hora_ruptura > dataInicio 
          AND data_hora_ruptura < dataFim
        GROUP BY TRUNC(data_hora_ruptura);
BEGIN
    -- Percorre os dias com rupturas e acumula o número de rupturas
    FOR r IN c1 LOOP
        media := media + r.numero;
        nDias := nDias + 1;
    END LOOP;
    
    -- Calcula a média de rupturas por dia
    IF nDias > 0 THEN
        media := media / nDias;
    END IF;
    
    RETURN media;
END;
/



-- Procedimento que simula a venda de um produto num compartimento
-- Recebe o ID do compartimento e o código do produto
-- Insere uma venda se o código do produto corresponder ao do compartimento e atualiza a quantidade

CREATE OR REPLACE PROCEDURE Q_PROC_2023144606 (COD_COMPARTIMENTO NUMBER, CODIGO_PRODUTO VARCHAR2 , TIPO_PAGAMENTO VARCHAR2)
IS
    proxvenda NUMBER;
    preco NUMBER;
    cod VARCHAR2(255);
    idprod NUMBER;
BEGIN
    -- Obtém o próximo ID de venda
    SELECT MAX(id_venda) + 1 INTO proxvenda FROM vendas;
    
    -- Obtém o preço, código e ID do produto do compartimento
    SELECT PRECO_COMPARTIMENTO, CODIGO, ID_PRODUTO INTO preco, cod, idprod 
    FROM COMPARTIMENTOS 
    WHERE ID_COMPARTIMENTO = COD_COMPARTIMENTO;
    
    -- Verifica se o código do produto corresponde
    IF cod = CODIGO_PRODUTO THEN
        -- Insere a venda
        INSERT INTO VENDAS (ID_VENDA, ID_COMPARTIMENTO, ID_PRODUTO, DATA_HORA_VENDA, METODO_PAGAMENTO, VALOR_PAGO)
        VALUES (proxvenda, COD_COMPARTIMENTO, idprod, SYSDATE,TIPO_PAGAMENTO, preco);
    END IF;
END;
/


-- Trigger que atualiza o stock após a inserção de uma encomenda
-- Adiciona a quantidade encomendada ao stock do armazém
-- Se o produto não existir no stock, cria um novo registo

CREATE OR REPLACE TRIGGER R_TRIG_2023144606
AFTER INSERT ON ENCOMENDAS
FOR EACH ROW
DECLARE
    quantidade NUMBER;
BEGIN
    -- Obtém a quantidade em stock para o produto e armazém
    SELECT QUANTIDADE_EM_STOCK
    INTO quantidade
    FROM STOCK
    WHERE ID_PRODUTO = :NEW.ID_PRODUTO
    AND ID_ARMAZEM = :NEW.ID_ARMAZEM;
  
    -- Verifica se a quantidade é válida
    IF quantidade < 0 THEN
        RAISE_APPLICATION_ERROR(-20813, 'Quantidade inválida');
    END IF;

    -- Atualiza o stock com a quantidade encomendada
    UPDATE STOCK
    SET QUANTIDADE_EM_STOCK = QUANTIDADE_EM_STOCK + :NEW.QUANTIDADE_ENCOMENDAS
    WHERE ID_PRODUTO = :NEW.ID_PRODUTO
    AND ID_ARMAZEM = :NEW.ID_ARMAZEM;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Insere um novo registo no stock se não existir
        INSERT INTO STOCK (ID_PRODUTO, ID_ARMAZEM, QUANTIDADE_EM_STOCK)
        VALUES (:NEW.ID_PRODUTO, :NEW.ID_ARMAZEM, :NEW.QUANTIDADE_ENCOMENDAS);
    WHEN OTHERS THEN
        RAISE;
END;
/

-- Função que calcula o lucro de uma máquina num intervalo de tempo
-- Recebe o ID da máquina e o intervalo de tempo (data de início e fim)
-- Verifica a existência da máquina, valida o intervalo temporal e retorna o lucro (receitas menos custos)

CREATE OR REPLACE FUNCTION p_FUNC_2023144573(idmaquina NUMBER, dataInicio DATE, dataFim DATE)
RETURN NUMBER
IS
    receita NUMBER;
    custo NUMBER;
    lucro NUMBER;
    verif_maq NUMBER;
BEGIN
    -- Verifica se a máquina existe
    SELECT COUNT(*) INTO verif_maq FROM maquinas WHERE id_maquina = idmaquina;
    IF verif_maq <= 0 THEN
        RAISE_APPLICATION_ERROR(-20801, 'Código de máquina inexistente');
    END IF;
    
    -- Valida se o intervalo temporal é válido
    IF dataInicio > dataFim THEN
         RAISE_APPLICATION_ERROR(-20809, 'Inválido intervalo temporal');
    END IF;
    
    -- Calcula as receitas (soma dos valores pagos nas vendas)
    SELECT NVL(SUM(v.valor_pago),0) INTO receita
    FROM vendas v, compartimentos c
    WHERE c.id_compartimento = v.id_compartimento
    AND c.id_maquina = idmaquina
    AND v.data_hora_venda BETWEEN dataInicio AND dataFim;
    
    -- Calcula os custos (preço do produto vezes a quantidade consumida)
    SELECT NVL(SUM(p.preco_produto * (c.capacidade_maxima - quantidade_compartimento)),0)
    INTO custo
    FROM produtos p, compartimentos c, vendas v
    WHERE c.id_produto = p.id_produto
    AND v.id_compartimento = c.id_compartimento
    AND c.id_maquina = idmaquina
    AND v.data_hora_venda BETWEEN dataInicio AND dataFim;
    
    -- Calcula o lucro
    lucro := receita - custo;
    
    RETURN lucro;
END;
/


-- Procedimento que atualiza o preço de todos os compartimentos de um tipo de produto
-- Recebe o tipo de produto e uma percentagem de alteração
-- Aplica a percentagem ao preço atual dos compartimentos do tipo de produto especificado

CREATE OR REPLACE PROCEDURE Q_PROC_2023144573(tipo_prod VARCHAR, percentagem NUMBER)
IS
    CURSOR compartimentos IS
        SELECT c.id_compartimento, c.preco_compartimento
        FROM compartimentos c, produtos p
        WHERE c.id_produto = p.id_produto
        AND p.tipo_produto = tipo_prod;
    verif_prod NUMBER;
    preco_atualizado NUMBER;
BEGIN
    -- Verifica se o tipo de produto existe
    SELECT COUNT(*) INTO verif_prod 
    FROM produtos 
    WHERE LOWER(tipo_produto) = LOWER(tipo_prod);
    
    IF verif_prod <= 0 THEN
        RAISE_APPLICATION_ERROR(-20814, 'TIPO DE PRODUTO INVÁLIDO');
    END IF;
        
    -- Valida se a percentagem está dentro do intervalo permitido
    IF percentagem < -100 OR percentagem > 1000 THEN
        RAISE_APPLICATION_ERROR(-20815, 'PERCENTAGEM INVÁLIDA');
    END IF;
    
    -- Atualiza o preço de cada compartimento do tipo de produto
    FOR r IN compartimentos LOOP
        preco_atualizado := r.preco_compartimento * (1 + percentagem / 100);
        UPDATE compartimentos
        SET preco_compartimento = preco_atualizado
        WHERE id_compartimento = r.id_compartimento;
    END LOOP;
END;
/




-- Trigger que atualiza a quantidade de produtos e o estado da máquina após um reabastecimento
-- Diminui a quantidade na viagem, aumenta a quantidade no compartimento
-- Atualiza o estado da máquina para 'operacional' se sair do estado 'SEM STOCK'

CREATE OR REPLACE TRIGGER R_TRIG_2023144573
AFTER INSERT ON reabastecimentos
FOR EACH ROW
DECLARE
    id_vig NUMBER;
    qnt_compartimento NUMBER;
    estado_maq VARCHAR2(20);
BEGIN
    -- Obtém o ID da viagem associada à visita
    SELECT v.id_viagem INTO id_vig
    FROM visitas v
    WHERE v.id_visita = :NEW.id_visita;

    -- Atualiza a quantidade de produtos na viagem
    UPDATE produto_viagem
    SET quantidade_pv = quantidade_pv - :NEW.quantidade_reabastecimento
    WHERE id_viagem = id_vig
    AND id_produto = :NEW.id_produto;
    
    -- Atualiza a quantidade no compartimento
    UPDATE compartimentos
    SET quantidade_compartimento = quantidade_compartimento + :NEW.quantidade_reabastecimento
    WHERE id_compartimento = :NEW.id_compartimento;
    
    -- Obtém a quantidade no compartimento após o reabastecimento
    SELECT quantidade_compartimento
    INTO qnt_compartimento
    FROM compartimentos
    WHERE id_maquina = (SELECT id_maquina FROM compartimentos WHERE id_compartimento = :NEW.id_compartimento)
    AND id_produto = :NEW.id_produto;
    
    -- Obtém o estado atual da máquina
    SELECT estado_maquina INTO estado_maq
    FROM maquinas
    WHERE id_maquina = (SELECT id_maquina FROM compartimentos WHERE id_compartimento = :NEW.id_compartimento);
    
    -- Atualiza o estado da máquina se necessário
    IF estado_maq = 'SEM STOCK' AND qnt_compartimento > 0 THEN
        UPDATE maquinas
        SET estado_maquina = 'ATIVA'
        WHERE id_maquina = (SELECT id_maquina FROM compartimentos WHERE id_compartimento = :NEW.id_compartimento);
    END IF;
END;
/


-- ============================================ MECANISMOS RESTRIÇÂO=============================================

-- Trigger que valida as coordenadas de longitude e latitude inseridas ou alteradas no armazém
-- Garante que os valores estão dentro dos limites geográficos válidos
CREATE OR REPLACE TRIGGER verifica_armazem
BEFORE INSERT OR UPDATE ON ARMAZEM
FOR EACH ROW
BEGIN
    -- Longitude deve estar entre -180 e 180 graus
    IF :NEW.LONGITUDE_A < -180 OR :NEW.LONGITUDE_A > 180 THEN
        RAISE_APPLICATION_ERROR(-20828, 'Cordenadas Invalidas');
    END IF;

    -- Latitude deve estar entre -90 e 90 graus
    IF :NEW.LATITUDE_A < -90 OR :NEW.LATITUDE_A > 90 THEN
        RAISE_APPLICATION_ERROR(-20828, 'Cordenadas Invalidas');
    END IF;
END;
/

-- Trigger que valida vários aspetos na inserção ou atualização de compartimentos
-- Inclui verificação da unicidade do código por máquina, da capacidade máxima e da consistência de quantidade/preço
CREATE OR REPLACE TRIGGER verifica_compartimentos
BEFORE INSERT OR UPDATE ON COMPARTIMENTOS
FOR EACH ROW
DECLARE
    nCodigos NUMBER;
BEGIN

    SELECT COUNT(*) INTO nCodigos
    FROM COMPARTIMENTOS
    WHERE ID_MAQUINA = :NEW.ID_MAQUINA
      AND CODIGO = :NEW.CODIGO;
    -- Capacidade máxima tem de ser superior a 0
    IF :NEW.CAPACIDADE_MAXIMA <= 0 THEN
        RAISE_APPLICATION_ERROR(-20830, 'Capacidade máxima inválida');
    END IF;

    -- A quantidade atual não pode exceder a capacidade máxima
    IF :NEW.QUANTIDADE_COMPARTIMENTO > :NEW.CAPACIDADE_MAXIMA THEN
        RAISE_APPLICATION_ERROR(-20813, 'Quantidade inválida');
    END IF;

    -- O preço do compartimento tem de ser positivo
    IF :NEW.PRECO_COMPARTIMENTO <= 0 THEN
        RAISE_APPLICATION_ERROR(-20831, 'Preço do compartimento invalido');
    END IF;
END;
/

-- Trigger que valida os dados ao inserir ou atualizar encomendas
-- Assegura que a data da encomenda é futura e a quantidade é positiva
CREATE OR REPLACE TRIGGER verifica_encomendas
BEFORE INSERT OR UPDATE ON ENCOMENDAS
FOR EACH ROW
BEGIN
    -- A data da encomenda tem de ser posterior à data atual
    IF :NEW.DATA_ENCOMENDA <= SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20832, 'A data da encomenda deve ser futura');
    END IF;

    -- Quantidade de encomendas deve ser superior a zero
    IF :NEW.QUANTIDADE_ENCOMENDAS <= 0 THEN
        RAISE_APPLICATION_ERROR(-20833, 'Quantidade de encomendas inválida');
    END IF;
END;
/

-- Trigger que valida o tipo de evento inserido na tabela EVENTOS
-- Só são aceites os tipos predefinidos: 'venda', 'abastecimento', 'manutenção' ou 'outro'
CREATE OR REPLACE TRIGGER verifica_eventos
BEFORE INSERT OR UPDATE ON EVENTOS
FOR EACH ROW
BEGIN
    IF :NEW.TIPO_EVENTO NOT IN ('venda', 'abastecimento', 'manutenção', 'outro') THEN
        RAISE_APPLICATION_ERROR(-20834, 'Tipo de evento inválido');
    END IF;
END;
/

-- Trigger que valida o NIF e a sua unicidade na tabela de funcionários
-- O NIF deve ter 9 dígitos e não pode estar repetido
CREATE OR REPLACE TRIGGER verifica_funcionarios
BEFORE INSERT OR UPDATE ON FUNCIONARIOS
FOR EACH ROW
DECLARE
    nNIF NUMBER;
BEGIN
    -- Validação do formato do NIF (9 dígitos)
    IF LENGTH(TO_CHAR(:NEW.NIF)) != 9 THEN
        RAISE_APPLICATION_ERROR(-20835, 'O NIF deve ter exatamente 9 dígitos numéricos');
    END IF;

    -- Verifica se o NIF já existe (para evitar duplicações)
    SELECT COUNT(*)
    INTO nNIF
    FROM FUNCIONARIOS
    WHERE NIF = :NEW.NIF;

    IF nNIF > 1 THEN
        RAISE_APPLICATION_ERROR(-20836, 'O NIF deve ser único. Este NIF já existe');
    END IF;
END;
/

-- Trigger que valida o estado registado no histórico de estados da máquina
-- Só são aceites os seguintes estados: 'INATIVA', 'ATIVA', 'OUTRO', 'SEM STOCK'
CREATE OR REPLACE TRIGGER verifica_historico_estados
BEFORE INSERT OR UPDATE ON HISTORICO_ESTADOS
FOR EACH ROW
BEGIN
    IF :NEW.ESTADO NOT IN ('INATIVA', 'ATIVA', 'OUTRO', 'SEM STOCK') THEN
        RAISE_APPLICATION_ERROR(-20837, 'Estado de máquina inválido');
    END IF;
END;
/

-- Trigger que valida os dados inseridos ou atualizados na tabela MANUTENCAO
-- Verifica se o tipo de manutenção é válido e se a data da manutenção está dentro do intervalo da visita
CREATE OR REPLACE TRIGGER verifica_manutencao
BEFORE INSERT OR UPDATE ON MANUTENCAO
FOR EACH ROW
DECLARE
  data_chegada DATE;
  data_saida DATE;
  valid_types VARCHAR2(100);
BEGIN
  -- Verifica se o tipo de manutenção é um dos permitidos
  IF :NEW.tipo_manutencao IS NULL OR :NEW.tipo_manutencao NOT IN ('PREVENTIVA', 'CORRETIVA', 'INSPEÇÃO') THEN
    RAISE_APPLICATION_ERROR(-20900, 'Tipo de manutenção inválido. Deve ser PREVENTIVA, CORRETIVA ou INSPEÇÃO.');
  END IF;

  -- Verifica se a visita existe e obtém as datas de chegada e saída
  SELECT data_hora_chegada, data_hora_saida INTO data_chegada, data_saida FROM visitas WHERE id_visita = :NEW.id_visita;

  -- Valida se a data da manutenção está dentro do intervalo da visita
  IF :NEW.data_hora_manutencao < data_chegada OR (:NEW.data_hora_manutencao > data_saida AND data_saida IS NOT NULL) THEN
    RAISE_APPLICATION_ERROR(-20902, 'DATA_HORA_MANUTENCAO deve estar entre DATA_HORA_CHEGADA e DATA_HORA_SAIDA da visita.');
  END IF;
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20901, 'ID_VISITA inválido. Visita não encontrada.');
END;
/

-- Trigger que valida os dados inseridos ou alterados na tabela MAQUINAS
-- Verifica o estado da máquina, as coordenadas e se a localização está preenchida
CREATE OR REPLACE TRIGGER verifica_maquinas
BEFORE INSERT OR UPDATE ON MAQUINAS
FOR EACH ROW
BEGIN
  -- Valida se o estado da máquina é um dos valores esperados
  IF :NEW.estado_maquina IS NULL OR :NEW.estado_maquina NOT IN ('ATIVA', 'INATIVA' , 'OUTROS', 'SEM STOCK') THEN
    RAISE_APPLICATION_ERROR(-20837, 'Estado de máquina inválido');
  END IF;

  -- Verifica se as coordenadas são válidas
  IF :NEW.longitude < -180 OR :NEW.longitude > 180 OR :NEW.latutude < -90 OR :NEW.latutude > 90 THEN
    RAISE_APPLICATION_ERROR(-20828, 'Cordenadas Invalidas');
  END IF;

  -- Valida se a localização da máquina está preenchida
  IF :NEW.localizacao_maquina IS NULL OR TRIM(:NEW.localizacao_maquina) = '' THEN
    RAISE_APPLICATION_ERROR(-20903, 'LOCALIZACAO_MAQUINA não pode ser nula ou vazia.');
  END IF;
END;
/

-- Trigger que valida inserções ou atualizações na tabela PRODUTO_VIAGEM
-- Garante que o stock é suficiente, a quantidade é positiva e as chaves estrangeiras existem
CREATE OR REPLACE TRIGGER verifica_produto_viagem
BEFORE INSERT OR UPDATE ON PRODUTO_VIAGEM
FOR EACH ROW
DECLARE
  capacidade NUMBER;
  verif_vig NUMBER;
  verif_prod NUMBER;
  stock NUMBER;
BEGIN
  -- Verifica se o stock do produto no armazém da viagem é suficiente
  SELECT SUM(QUANTIDADE_EM_STOCK) INTO stock
  FROM stock
  WHERE id_produto = :NEW.id_produto
    AND id_armazem = (SELECT id_armazem FROM viagens WHERE id_viagem = :NEW.id_viagem);

  IF stock < :NEW.QUANTIDADE_PV THEN
    RAISE_APPLICATION_ERROR(-20919, 'Quantidade em viagem excede o stock disponível');
  END IF;

  -- Quantidade não pode ser negativa
  IF :NEW.quantidade_pv < 0 THEN
    RAISE_APPLICATION_ERROR(-20904, 'QUANTIDADE_PV não pode ser negativa.');
  END IF;

  -- Verifica existência do produto
  SELECT count(*) INTO verif_prod FROM produtos WHERE id_produto = :NEW.id_produto;
  IF verif_prod = 0 THEN
    RAISE_APPLICATION_ERROR(-20802, 'Código de produto inexistente.');
  END IF;

  -- Verifica existência da viagem
  SELECT count(*) INTO verif_vig FROM viagens WHERE id_viagem = :NEW.id_viagem;
  IF verif_vig = 0 THEN 
    RAISE_APPLICATION_ERROR(-20807, 'Viagem de abastecimento inexistente');
  END IF;
END;
/

-- Trigger que valida dados inseridos ou atualizados na tabela PRODUTOS
-- Verifica o preço, campos obrigatórios e unicidade da referência
CREATE OR REPLACE TRIGGER verifica_produtos
BEFORE INSERT OR UPDATE ON PRODUTOS
FOR EACH ROW
DECLARE
  conta_ref NUMBER;
BEGIN
  -- Verifica se o preço é positivo
  IF :NEW.preco_produto < 0 THEN
    RAISE_APPLICATION_ERROR(-20908, 'PRECO_PRODUTO não pode ser negativo.');
  END IF;

  -- Verifica se o nome do produto está preenchido
  IF :NEW.nome_produto IS NULL OR TRIM(:NEW.nome_produto) = '' THEN
    RAISE_APPLICATION_ERROR(-20909, 'NOME_PRODUTO não pode ser nulo ou vazio.');
  END IF;

  -- Verifica se o tipo do produto está preenchido
  IF :NEW.tipo_produto IS NULL OR TRIM(:NEW.tipo_produto) = '' THEN
    RAISE_APPLICATION_ERROR(-20910, 'TIPO_PRODUTO não pode ser nulo ou vazio.');
  END IF;

  -- Garante que a referência do produto é única
  SELECT COUNT(*) INTO conta_ref
  FROM produtos
  WHERE REFERENCIA = :NEW.REFERENCIA
    AND ID_PRODUTO != :NEW.ID_PRODUTO;
  IF conta_ref > 0 THEN
    RAISE_APPLICATION_ERROR(-20911, 'REFERENCIA deve ser única. Esta referência já existe.');
  END IF;
END;
/

-- Trigger que valida inserções ou atualizações na tabela ROTAS
-- Verifica o valor da distância, nome da rota e existência do armazém associado
CREATE OR REPLACE TRIGGER verifica_rotas
BEFORE INSERT OR UPDATE ON ROTAS
FOR EACH ROW
DECLARE 
  verif_armazem NUMBER;
BEGIN
  -- A distância da rota não pode ser negativa
  IF :NEW.rotakm < 0 THEN
    RAISE_APPLICATION_ERROR(-20912, 'ROTAKM não pode ser negativo.');
  END IF;

  -- O nome da rota tem de estar preenchido
  IF :NEW.nome_rota IS NULL OR TRIM(:NEW.nome_rota) = '' THEN
    RAISE_APPLICATION_ERROR(-20913, 'NOME_ROTA não pode ser nulo ou vazio.');
  END IF;

  -- Verifica se o armazém existe
  SELECT count(*) INTO verif_armazem FROM armazem WHERE id_armazem = :NEW.id_armazem;
  IF verif_armazem = 0 THEN
    RAISE_APPLICATION_ERROR(-20806, 'Código de armazém inexistente.');
  END IF;
END;
/

-- Trigger que valida a integridade de dados na tabela ROTASDEFENIDAS
-- Verifica ordem válida, existência de rota e máquina, e unicidade da ordem
CREATE OR REPLACE TRIGGER verifica_rotas_defenidas
BEFORE INSERT OR UPDATE ON ROTASDEFENIDAS
FOR EACH ROW
DECLARE
  conta_ordem NUMBER;
  verif_maq NUMBER; 
  verif_rota NUMBER;
BEGIN
  -- A ordem deve ser um número positivo
  IF :NEW.ordem <= 0 THEN
    RAISE_APPLICATION_ERROR(-20915, 'ORDEM deve ser um valor positivo.');
  END IF;

  -- Verifica se a máquina existe
  SELECT count(*) INTO verif_maq FROM maquinas WHERE id_maquina = :NEW.id_maquina;
  IF verif_maq = 0 THEN
    RAISE_APPLICATION_ERROR(-20801, 'Código de máquina inexistente.');
  END IF;

  -- Verifica se a rota existe
  SELECT count(*) INTO verif_rota FROM rotas WHERE id_rota = :NEW.id_rota;
  IF verif_rota = 0 THEN
    RAISE_APPLICATION_ERROR(-20916, 'ID_ROTA inválido. ROTA não encontrada.');
  END IF;

  -- Garante que não há mais do que uma máquina com a mesma ordem na mesma rota
  SELECT COUNT(*) INTO conta_ordem
  FROM rotasdefenidas
  WHERE id_rota = :NEW.id_rota
    AND ordem = :NEW.ordem
    AND id_maquina != :NEW.id_maquina;

  IF conta_ordem > 0 THEN
    RAISE_APPLICATION_ERROR(-20918, 'ORDEM deve ser única para a rota especificada.');
  END IF;
END;
/


-- Trigger que valida inserções ou atualizações na tabela RUPTURAS
-- Garante que não há duplicação de ID e que a data da ruptura é válida
CREATE OR REPLACE TRIGGER verifica_rupturas
BEFORE INSERT OR UPDATE ON rupturas
FOR EACH ROW
DECLARE 
    n_codigo NUMBER;
BEGIN
    -- Verifica se a ruptura já está registada
    SELECT COUNT(*) INTO n_codigo
    FROM rupturas 
    WHERE id_ruptura = :NEW.id_ruptura;

    IF n_codigo > 1 THEN
        RAISE_APPLICATION_ERROR(-20840, 'Ruptura já registada');
    END IF;

    -- A data da ruptura não pode ser nula nem futura
    IF :NEW.data_hora_ruptura IS NULL OR :NEW.data_hora_ruptura > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20841, 'Data de ruptura inválida');
    END IF;
END;
/

-- Trigger que valida inserções ou atualizações na tabela STOCK
-- Verifica a existência do armazém e do produto, e que a quantidade em stock não seja negativa
CREATE OR REPLACE TRIGGER verifica_stock
BEFORE INSERT OR UPDATE ON stock
FOR EACH ROW
DECLARE 
    verif_arm NUMBER;
    verif_prod NUMBER;
BEGIN
    -- Verifica se o armazém existe
    SELECT COUNT(*) INTO verif_arm
    FROM armazem WHERE
    id_armazem = :NEW.id_armazem;

    IF verif_arm = 0 THEN
        RAISE_APPLICATION_ERROR(-20806, 'Código de armazém inexistente.');
    END IF;

    -- Verifica se o produto existe
    SELECT COUNT(*) INTO verif_prod
    FROM produtos WHERE
    id_produto = :NEW.id_produto;

    IF verif_prod = 0 THEN
        RAISE_APPLICATION_ERROR(-20802, 'Código de produto inexistente.');
    END IF;

    -- A quantidade em stock não pode ser negativa
    IF :NEW.quantidade_em_stock < 0 THEN
        RAISE_APPLICATION_ERROR(-20842, 'QUANTIDADE_EM_STOCK não pode ser negativo');
    END IF;
END;
/

-- Trigger que valida inserções ou atualizações na tabela VEICULOS
-- Garante integridade dos dados do armazém, dados obrigatórios do veículo e consistência de stock
CREATE OR REPLACE TRIGGER verifica_veiculos
BEFORE INSERT OR UPDATE ON veiculos
FOR EACH ROW
DECLARE 
    verif_arm NUMBER;
    verif_veiculo NUMBER;
    qnt_stock NUMBER;
BEGIN
    -- Verifica se o armazém existe
    SELECT COUNT(*) INTO verif_arm
    FROM armazem WHERE
    id_armazem = :NEW.id_armazem;

    IF verif_arm = 0 THEN
        RAISE_APPLICATION_ERROR(-20806, 'Código de armazém inexistente.');
    END IF;

    -- Verifica se o veículo existe
    SELECT COUNT(*) INTO verif_veiculo
    FROM veiculos WHERE
    id_veiculo = :NEW.id_veiculo;

    IF verif_veiculo > 0 THEN
        RAISE_APPLICATION_ERROR(-20843, 'Código de veiculo ja existe');
    END IF;

    -- Verificações de campos obrigatórios
    IF :NEW.matricula IS NULL OR LENGTH(:NEW.matricula) != 6 THEN
        RAISE_APPLICATION_ERROR(-20844, 'MATRICULA não pode ser nulo ou vazio.');
    END IF;


    IF :NEW.autonomia_km <0 THEN
        RAISE_APPLICATION_ERROR(-20846, 'AUTONOMIA_KM não pode ser negativo.');
    END IF;


    -- Verifica se a capacidade do veículo não excede o stock disponível
    SELECT quantidade_em_stock INTO qnt_stock
    FROM stock WHERE
    id_armazem = :NEW.id_armazem;

    IF :NEW.capacidade_carga_veiculo > qnt_stock THEN
        RAISE_APPLICATION_ERROR(-20848, 'CAPACIDADE_CARGA_VEICULO excede a capacidade do armazem');
    END IF;
END;
/

-- Trigger que valida inserções ou atualizações na tabela VENDAS
-- Verifica existência de chaves estrangeiras, valores obrigatórios e coerência dos dados
CREATE OR REPLACE TRIGGER verifica_vendas
BEFORE INSERT OR UPDATE ON vendas
FOR EACH ROW
DECLARE 
    verif_venda NUMBER;
    verif_compartimento NUMBER;
    verif_prod NUMBER;
    qnt_stock NUMBER;
    data_incio DATE;
    data_fim DATE;
    preco_c NUMBER;
BEGIN
    -- Verifica se a venda já existe
    SELECT COUNT(*) INTO verif_venda
    FROM vendas WHERE
    id_venda = :NEW.id_venda;

    IF verif_venda > 1 THEN
        RAISE_APPLICATION_ERROR(-20849, 'Codigo venda já existe');
    END IF;

    -- Verifica compartimento e obtém o preço
    SELECT COUNT(*) INTO verif_compartimento
    FROM compartimentos 
    WHERE id_compartimento = :NEW.id_compartimento;
    
    -- Obtem o preço do compartimento separadamente
    SELECT preco_compartimento INTO preco_c
    FROM compartimentos 
    WHERE id_compartimento = :NEW.id_compartimento;
    
    IF verif_compartimento = 0 THEN
        RAISE_APPLICATION_ERROR(-20850, 'Código de compartimento inexistente.');
    END IF;

    -- Verifica produto
    SELECT COUNT(*) INTO verif_prod
    FROM produtos 
    WHERE id_produto = :NEW.id_produto;

    IF verif_prod = 0 THEN
        RAISE_APPLICATION_ERROR(-20802, 'Código de produto inexistente.');
    END IF;

    -- Validação da data da venda
    IF :NEW.data_hora_venda IS NULL THEN
        RAISE_APPLICATION_ERROR(-20851, 'DATA_HORA_VENDA invalida.');
    END IF;

    -- Verifica o método de pagamento
    IF :NEW.metodo_pagamento IS NULL OR :NEW.metodo_pagamento NOT IN ('CREDITO', 'MBWAY') THEN
        RAISE_APPLICATION_ERROR(-20852, 'METODO_PAGAMENTO invalido. tem que ser credito ou mbway');
    END IF;

    -- Verifica valor pago
    IF :NEW.valor_pago < 0 OR :NEW.valor_pago < preco_c THEN
        RAISE_APPLICATION_ERROR(-20853, 'VALOR_PAGO não pode ser negativo e maior que preco do compartimento.');
    END IF;
END;
/

-- Trigger que valida inserções ou atualizações na tabela VIAGENS
-- Verifica chaves estrangeiras, distância percorrida e coerência de datas
CREATE OR REPLACE TRIGGER verifica_viagens
BEFORE INSERT OR UPDATE ON viagens
FOR EACH ROW
DECLARE 
    verif_viagem NUMBER;
    verif_rota NUMBER;
    verif_veiculo NUMBER;
    verif_func NUMBER;
    rota_km NUMBER;
BEGIN
    -- Verifica se a rota existe
    SELECT COUNT(*) INTO verif_rota
    FROM rotas WHERE
    id_rota = :NEW.id_rota;

    IF verif_rota = 0 THEN
        RAISE_APPLICATION_ERROR(-20916, ' ID_ROTA inválido. ROTA não encontrada.');
    END IF;


    -- Valida a distância percorrida com base na rota
    SELECT rotakm INTO rota_km FROM rotas
    WHERE id_rota = :NEW.id_rota;

    IF :NEW.distancia_percorrida > rota_km OR :NEW.distancia_percorrida < 0  THEN
        RAISE_APPLICATION_ERROR(-20856, 'DISTANCIA_PERCORRIDA invalida. Tem que ser inferior ou igual km da rota (valor positivo).');
    END IF;

    -- Verifica consistência das datas de início e fim
    IF :NEW.data_inicio_viagem > :NEW.data_fim_viagem THEN
        RAISE_APPLICATION_ERROR(-20857, 'Datas da viagem invalida. A data de inicio não pode ser superior a data de fim.'); 
    END IF;
END;
/

-- Trigger que valida inserções ou atualizações na tabela VISITAS
-- Garante que a viagem e a máquina existem e que as datas de chegada e saída são coerentes
CREATE OR REPLACE TRIGGER verifica_visitas
BEFORE INSERT OR UPDATE ON visitas
FOR EACH ROW
DECLARE 
    verif_visita NUMBER;
    verif_viagem NUMBER;
    verif_maq NUMBER;
BEGIN
    -- Verifica se a visita já existe
    SELECT COUNT(*) INTO verif_visita
    FROM visitas WHERE
    id_visita = :NEW.id_visita;

    IF verif_visita > 1 THEN
        RAISE_APPLICATION_ERROR(-20858, 'Código de visita invalido. Visita ja existe');
    END IF;

    -- Verifica se a viagem associada existe
    SELECT COUNT(*) INTO verif_viagem
    FROM viagens WHERE
    id_viagem = :NEW.id_viagem;

    IF verif_viagem = 0 THEN
        RAISE_APPLICATION_ERROR(-20854, 'Código de viagem invalido. Viagem inexistente');
    END IF;

    -- Verifica se a máquina existe
    SELECT COUNT(*) INTO verif_maq
    FROM maquinas WHERE
    id_maquina = :NEW.id_maquina;

    IF verif_maq = 0 THEN
        RAISE_APPLICATION_ERROR(-20801, 'Código de máquina inexistente.');
    END IF;

    -- Verifica que a data de chegada é anterior à de saída
    IF :NEW.data_hora_chegada > :NEW.data_hora_saida THEN
        RAISE_APPLICATION_ERROR(-20859, 'Datas de visitas invalidas. A data de chegada não pode ser superior à data de saida');    
    END IF;
END;
/




