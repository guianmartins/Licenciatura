-- Cria ou substitui a visualização VIEW_A
CREATE OR REPLACE VIEW VIEW_A AS
-- Seleciona os campos a serem exibidos:
SELECT 
    m.ID_MAQUINA AS IDMAQUINA,  -- Identificador único da máquina
    -- Formata a data/hora do último reabastecimento no formato dia/mês/ano horas:minutos
    TO_CHAR(MAX(r.DATA_HORA_REABASTECIMENTO), 'DD/MM/YYYY HH24"H"MI') AS DATA_HORA_ABAST,
    m.LOCALIZACAO_MAQUINA AS LOCAL,  -- Localização física da máquina
    -- Soma total de produtos reabastecidos
    SUM(r.QUANTIDADE_REABASTECIMENTO) AS QUANT_ABASTECIDA,
    -- Contagem de tipos de produtos diferentes reabastecidos
    COUNT(DISTINCT r.ID_PRODUTO) AS NUM_PRODUTOS_DIFERENTES

-- Tabelas utilizadas
FROM 
    MAQUINAS m,          -- Tabela de máquinas
    COMPARTIMENTOS c,    -- Tabela de compartimentos das máquinas
    REABASTECIMENTOS r,  -- Tabela de registos de reabastecimento
    STOCK s,             -- Tabela de stock de produtos
    PRODUTOS p           -- Tabela de produtos disponíveis

-- Condições de junção e filtros:
WHERE
    -- Relaciona compartimentos com suas máquinas
    c.ID_MAQUINA = m.ID_MAQUINA
    -- Relaciona reabastecimentos com seus compartimentos
    AND r.ID_COMPARTIMENTO = c.ID_COMPARTIMENTO
    -- Relaciona reabastecimentos com os produtos
    AND r.ID_PRODUTO = p.ID_PRODUTO
    -- Relaciona stock com os produtos
    AND s.ID_PRODUTO = p.ID_PRODUTO 
    -- Filtra apenas produtos do tipo 'snacks' (case insensitive)
    AND LOWER(p.TIPO_PRODUTO) = 'snacks'
    -- Filtra máquinas localizadas em Coimbra
    AND m.LOCALIZACAO_MAQUINA LIKE '%Coimbra%'
    -- Exclui máquinas com estado 'inativo' (case insensitive)
    AND lower(m.ESTADO_MAQUINA) <> 'inativo'
    -- Filtra apenas reabastecimentos realizados ontem
    AND TRUNC(r.DATA_HORA_REABASTECIMENTO) = TRUNC(SYSDATE - 1)
    -- Filtra apenas produtos com stock esgotado (quantidade = 0)
    AND s.QUANTIDADE_EM_STOCK = 0

-- Agrupamento dos resultados:
GROUP BY
     m.ID_MAQUINA,          -- Agrupa por máquina
     m.LOCALIZACAO_MAQUINA  -- e por localização

-- Ordenação dos resultados:
ORDER BY 
    QUANT_ABASTECIDA ASC;  -- Ordena por quantidade reabastecida (menor para maior)
    
    
SELECT * FROM VIEW_A;

-------------------------------------------------------- VIEW B ----------------------------------------------------
CREATE OR REPLACE VIEW VIEW_B AS
SELECT 
    m.ID_MAQUINA AS IDMAQUINA,               -- Identificador único da máquina
    m.LOCALIZACAO_MAQUINA AS LOCAL,          -- Localização física da máquina
    p.REFERENCIA AS REF_PRODUTO,             -- Código de referência do produto
    p.NOME_PRODUTO AS PRODUTO,               -- Nome descritivo do produto
    SUM(c.QUANTIDADE_COMPARTIMENTO) AS QUANT_EXISTENTE,  -- Quantidade atual no compartimento (SUM pois pode ter produtos iguais em diferentes compartimentos)
    SUM(r.QUANTIDADE_REABASTECIMENTO) AS QUANT_ABASTECIDA, -- Quantidade reposta de cada produto
    SUM(c.CAPACIDADE_MAXIMA) AS CAPACIDADE   -- Capacidade máxima do(s) compartimento(s) (Soma das capacidades dos compartimento(s) que tenham o produto)
FROM 
    VIAGENS v , VISITAS vs , MAQUINAS m , REABASTECIMENTOS r , COMPARTIMENTOS c , PRODUTOS p
WHERE
   v.ID_VIAGEM = vs.ID_VIAGEM               -- Relaciona viagens com suas visitas
    AND vs.ID_MAQUINA = m.ID_MAQUINA         -- Relaciona visitas com máquinas
    AND vs.ID_VISITA = r.ID_VISITA           -- Relaciona visitas com reabastecimentos
    AND r.ID_COMPARTIMENTO = c.ID_COMPARTIMENTO -- Relaciona reabastecimentos com compartimentos
    AND c.ID_PRODUTO = p.ID_PRODUTO          -- Relaciona compartimentos com produtos
    AND v.ID_VIAGEM = 2025031105             -- Filtra apenas para a viagem específica
GROUP BY
    m.ID_MAQUINA,                            -- Agrupa por máquina
    m.LOCALIZACAO_MAQUINA,                   -- e localização (OBS: nome de coluna incorreto)
    p.REFERENCIA,                            -- e referência do produto
    p.NOME_PRODUTO                           -- e nome do produto
ORDER BY 
    MIN(vs.DATA_HORA_CHEGADA) ASC,           -- Ordena pela primeira hora de chegada
    QUANT_ABASTECIDA DESC;                    -- Depois por quantidade abastecida (maior primeiro)
    
SELECT * FROM VIEW_B;


----------------------------------------------------------- VIEW C ---------------------------------------    

CREATE OR REPLACE VIEW VIEW_C AS
-- Define uma CTE (Common Table Expression) para obter as vendas do mês anterior
WITH vendas_mes_anterior AS (
    SELECT 
        m.ID_MAQUINA AS MAQ,                 -- ID da máquina
        c.ID_COMPARTIMENTO AS COMPART,        -- ID do compartimento
        v.ID_PRODUTO AS VENDA_PROD,           -- ID do produto vendido
        p.NOME_PRODUTO AS NOME_PROD,          -- Nome do produto
        p.REFERENCIA AS PROD_REF,             -- Referência do produto
        COUNT(v.ID_VENDA) AS TOTAL_VENDIDO_MES, -- Total de vendas no mês
        c.CAPACIDADE_MAXIMA AS CAP_MAX        -- Capacidade máxima do compartimento
    FROM 
        VENDAS v , COMPARTIMENTOS c , PRODUTOS p , MAQUINAS m
    WHERE 
        m.ID_MAQUINA = c.ID_MAQUINA           -- Junção máquina-compartimento
        AND v.ID_PRODUTO = p.ID_PRODUTO       -- Junção venda-produto
        AND v.ID_COMPARTIMENTO = c.ID_COMPARTIMENTO -- Junção venda-compartimento
        -- Filtra vendas do mês anterior (do primeiro ao último dia)
        AND v.DATA_HORA_VENDA BETWEEN TRUNC(ADD_MONTHS(SYSDATE, -1), 'MM')  
                                  AND LAST_DAY(ADD_MONTHS(SYSDATE, -1))
    GROUP BY 
        m.ID_MAQUINA, c.ID_COMPARTIMENTO, v.ID_PRODUTO, 
        p.NOME_PRODUTO, p.REFERENCIA, c.CAPACIDADE_MAXIMA
),

-- CTE para identificar o produto mais vendido em cada máquina
produto_mais_vendido AS (
    SELECT vma.*
    FROM vendas_mes_anterior vma
    WHERE TOTAL_VENDIDO_MES = (
        -- Subconsulta para encontrar o máximo de vendas por máquina
        SELECT MAX(TOTAL_VENDIDO_MES)
        FROM vendas_mes_anterior
        WHERE MAQ = vma.MAQ
    )
),

-- CTE para calcular vendas desde o último reabastecimento
desde_ultimo_reabastecimento AS (
    SELECT 
        m.ID_MAQUINA AS MAQ,                 -- ID da máquina
        v.ID_PRODUTO AS PROD,                -- ID do produto
        COUNT(v.ID_VENDA) AS TOTAL_VENDIDO_ULT_REABEST -- Total vendido desde último reabastecimento
    FROM 
        VENDAS v, COMPARTIMENTOS c, MAQUINAS m
    WHERE 
        v.ID_COMPARTIMENTO = c.ID_COMPARTIMENTO -- Junção venda-compartimento
        AND c.ID_MAQUINA = m.ID_MAQUINA      -- Junção compartimento-máquina
        -- Filtra vendas após o último reabastecimento do produto no compartimento
        AND v.DATA_HORA_VENDA >= (
            SELECT MAX(r.DATA_HORA_REABASTECIMENTO)
            FROM REABASTECIMENTOS r
            WHERE r.ID_PRODUTO = v.ID_PRODUTO
              AND r.ID_COMPARTIMENTO = v.ID_COMPARTIMENTO
        )
    GROUP BY
        m.ID_MAQUINA, v.ID_PRODUTO
)

-- Consulta principal que combina os resultados
SELECT
    m.ID_MAQUINA,                            -- ID da máquina
    m.LOCALIZACAO_MAQUINA AS LOCAL,          -- Localização da máquina 
    pmv.PROD_REF AS REF_PRODUTO,             -- Referência do produto
    pmv.NOME_PROD AS PRODUTO,                -- Nome do produto
    pmv.TOTAL_VENDIDO_MES AS QUANT_VENDIDA_MES, -- Quantidade vendida no mês
    -- Quantidade vendida desde último reabastecimento (trata NULL como 0)
    NVL(dur.TOTAL_VENDIDO_ULT_REABEST, 0) AS QUANT_VEND_DESDE_ULTIMO
FROM 
    produto_mais_vendido pmv, MAQUINAS m , desde_ultimo_reabastecimento dur 
WHERE 
    pmv.MAQ = m.ID_MAQUINA                   -- Junção máquina-produto mais vendido
    AND dur.MAQ = pmv.MAQ                    -- Junção com vendas desde último reabastecimento
    AND dur.PROD = pmv.VENDA_PROD            -- Junção por produto 
    -- Filtra produtos com vendas < 50% da capacidade máxima
    AND pmv.TOTAL_VENDIDO_MES <= 0.5 * NVL(pmv.CAP_MAX, 1)
-- Ordena por quantidade vendida (maior primeiro)
ORDER BY 
    QUANT_VENDIDA_MES DESC;


SELECT * FROM VIEW_C;


----------------------------------------------------------- VIEW D ---------------------------------------    

CREATE OR REPLACE VIEW VIEW_D AS 
    -- CTE para calcular o total de produtos por máquina
    WITH TOTAL_PRODUTOS AS (
        SELECT
            m.ID_MAQUINA AS MAQ,               -- ID da máquina
            SUM(c.QUANTIDADE_COMPARTIMENTO) AS TOTAL  -- Soma da quantidade em todos compartimentos
        FROM COMPARTIMENTOS c, MAQUINAS m       -- Junção implícita entre compartimentos e máquinas
        WHERE
            m.ID_MAQUINA = c.ID_MAQUINA         -- Relacionamento máquina-compartimento
        GROUP BY
            m.ID_MAQUINA                        -- Agrupado por máquina
    ),
    
    -- CTE para obter a data do último reabastecimento por máquina
    DATA_ULTIMA_REABAST AS (
        SELECT 
            m.ID_MAQUINA AS MAQ,                -- ID da máquina
            MAX(r.DATA_HORA_REABASTECIMENTO) AS DATA_ULT  -- Última data de reabastecimento
        FROM REABASTECIMENTOS r, COMPARTIMENTOS c, MAQUINAS m  -- Junção implícita entre as 3 tabelas
        WHERE 
            c.ID_COMPARTIMENTO = r.ID_COMPARTIMENTO  -- Relacionamento reabastecimento-compartimento
            AND m.ID_MAQUINA = c.ID_MAQUINA     -- Relacionamento compartimento-máquina
        GROUP BY 
            m.ID_MAQUINA                        -- Agrupado por máquina
    )
    
    -- Consulta principal
    SELECT 
        m.ID_MAQUINA AS MAQUINAID,              -- ID da máquina
        m.LOCALIZACAO_MAQUINA AS LOCAL,         -- Localização da máquina
        dam.DIST_MAQ_ARM_KM AS DISTANCIA_LINEAR, -- Distância linear em km
        -- Formata a data no padrão DD/MM/YYYY com horas e minutos (ex: 20/11/2023 14H00)
        TO_CHAR(dur.DATA_ULT, 'DD/MM/YYYY HH24"H"MI') AS DATA_ULT_ABAST,
        tp.TOTAL AS QUANT_TOTAL_PRODUTOS        -- Quantidade total de produtos na máquina
    FROM 
        MAQUINAS m, 
        TOTAL_PRODUTOS tp,                      -- CTE com total de produtos
        COMPARTIMENTOS c, 
        PRODUTOS p, 
        DISTANCA_ARMAZEM_MAQUINA dam,           -- Tabela de distâncias
        ARMAZEM a, 
        DATA_ULTIMA_REABAST dur                  -- CTE com datas de reabastecimento
    WHERE
        tp.MAQ = m.ID_MAQUINA                   -- Junção com total de produtos
        AND dur.MAQ = m.ID_MAQUINA              -- Junção com datas de reabastecimento
        AND c.ID_MAQUINA = m.ID_MAQUINA         -- Junção com compartimentos
        AND p.ID_PRODUTO = c.ID_PRODUTO         -- Junção com produtos
        AND dam.ID_MAQUINA = m.ID_MAQUINA       -- Junção com distâncias
        AND a.ID_ARMAZEM = dam.ID_ARMAZEM       -- Junção com armazém
        AND LOWER(a.LOCALIZACAO) LIKE '%taveiro%'  -- Filtra apenas armazém em Taveiro
        AND LOWER(p.NOME_PRODUTO) LIKE '%kitkat%'  -- Filtra apenas produtos KitKat (case insensitive)
        AND dam.DIST_MAQ_ARM_KM <= 30           -- Filtra máquinas dentro de 30km
    ORDER BY 
        dam.DIST_MAQ_ARM_KM ASC;                -- Ordena por distância (mais próximas primeiro)
         
SELECT * FROM VIEW_D;

----------------------------------------------------------- VIEW E ---------------------------------------  
CREATE OR REPLACE VIEW VIEW_E AS
   -- CTE que calcula o total de reabastecimentos por máquina
   WITH REABASTECIMENTOS_MAQUINA AS (
        SELECT 
            m.ID_MAQUINA AS MAQ,                -- ID da máquina
            COUNT(*) AS TOTAL_REABASTECIMENTOS   -- Contagem total de reabastecimentos
        FROM REABASTECIMENTOS r, COMPARTIMENTOS c, MAQUINAS m  -- Junção implícita das tabelas
        WHERE
            c.ID_COMPARTIMENTO = r.ID_COMPARTIMENTO  -- Relacionamento reabastecimento-compartimento
            AND m.ID_MAQUINA = c.ID_MAQUINA     -- Relacionamento compartimento-máquina
        GROUP BY m.ID_MAQUINA                   -- Agrupado por máquina
    ),
    
    -- CTE que calcula vendas mensais por produto (2023-2024)
    PRODUTOS_POR_MES AS (
        SELECT 
            p.ID_PRODUTO AS PROD,               -- ID do produto
            EXTRACT(YEAR FROM v.DATA_HORA_VENDA) AS ANO,  -- Ano da venda
            EXTRACT(MONTH FROM v.DATA_HORA_VENDA) AS MES, -- Mês da venda
            COUNT(v.ID_VENDA) AS QUANTIDADE_POR_MES  -- Contagem de vendas no mês
        FROM PRODUTOS p, VENDAS v               -- Junção implícita produtos-vendas
        WHERE 
            v.ID_PRODUTO = p.ID_PRODUTO        -- Relacionamento venda-produto
            AND EXTRACT(YEAR FROM v.DATA_HORA_VENDA) IN (2023, 2024)  -- Filtro por anos
        GROUP BY
            p.ID_PRODUTO,                      -- Agrupado por produto
            EXTRACT(YEAR FROM v.DATA_HORA_VENDA),  -- e ano
            EXTRACT(MONTH FROM v.DATA_HORA_VENDA)  -- e mês
    ),
    
    -- CTE que calcula a média geral de reabastecimentos
    MEDIA_REABASTECIMENTOS AS (
        SELECT AVG(TOTAL_REABASTECIMENTOS) AS MEDIA  -- Média de reabastecimentos
        FROM REABASTECIMENTOS_MAQUINA
    )
    
    -- Consulta principal
    SELECT 
        m.ID_MAQUINA,                          -- ID da máquina
        p.NOME_PRODUTO,                         -- Nome do produto
        ROUND((SUM(pm.QUANTIDADE_POR_MES)/24)*100, 2) AS MEDIAMENSAL  -- Média mensal (considerando 24 meses)
    FROM 
        PRODUTOS p,                             -- Tabela de produtos
        PRODUTOS_POR_MES pm,                    -- CTE de vendas mensais
        COMPARTIMENTOS c,                       -- Tabela de compartimentos
        MAQUINAS m,                             -- Tabela de máquinas
        REABASTECIMENTOS_MAQUINA rm,            -- CTE de reabastecimentos
        MEDIA_REABASTECIMENTOS mr               -- CTE de média de reabastecimentos
    WHERE
        pm.PROD = p.ID_PRODUTO                  -- Junção com vendas mensais
        AND c.ID_PRODUTO = p.ID_PRODUTO         -- Junção com compartimentos
        AND m.ID_MAQUINA = c.ID_MAQUINA        -- Junção com máquinas
        AND rm.MAQ = m.ID_MAQUINA              -- Junção com reabastecimentos
        AND LOWER(m.ESTADO_MAQUINA) = 'operacional'  -- Filtro por máquinas operacionais
        AND rm.TOTAL_REABASTECIMENTOS > mr.MEDIA  -- Filtro por reabastecimentos acima da média
    GROUP BY 
        m.ID_MAQUINA, p.NOME_PRODUTO           -- Agrupado por máquina e produto
    ORDER BY 
        p.NOME_PRODUTO ASC,                    -- Ordena por nome do produto (A-Z)
        MEDIAMENSAL DESC;                      -- Depois por média mensal (maior primeiro)

SELECT * FROM VIEW_E;


----------------------------------------------------------- VIEW F ---------------------------------------  
CREATE OR REPLACE VIEW VIEW_F AS 
    -- Primeira CTE: Identifica as máquinas e total de vendas de água nas últimas 72 horas
    WITH VENDAS_AGUA AS (
        SELECT 
            m.ID_MAQUINA AS MAQ,
            COUNT(v.ID_VENDA) AS TOTAL_VENDAS
        FROM VENDAS v, COMPARTIMENTOS c, PRODUTOS p, MAQUINAS m
        WHERE
            -- Junção entre tabelas
            c.ID_COMPARTIMENTO = v.ID_COMPARTIMENTO
            AND m.ID_MAQUINA = c.ID_MAQUINA
            AND p.ID_PRODUTO = v.ID_PRODUTO
            -- Filtra apenas produtos do tipo 'agua'
            AND LOWER(p.TIPO_PRODUTO) = 'agua'
            -- Filtra vendas dos últimos 3 dias
            AND v.DATA_HORA_VENDA >= SYSDATE - 3
            -- Filtra apenas vendas do ano atual
            AND EXTRACT(YEAR FROM v.DATA_HORA_VENDA) = EXTRACT(YEAR FROM SYSDATE)
        -- Agrupa por máquina
        GROUP BY m.ID_MAQUINA
    ),
    
    -- Segunda CTE: Identifica a máquina com maior número de vendas de água
    MAQUINA_VENDEU_MAIS AS (
        SELECT 
            va.MAQ
        FROM VENDAS_AGUA va
        -- Filtra apenas a máquina com o máximo de vendas
        WHERE va.TOTAL_VENDAS = (SELECT MAX(va2.TOTAL_VENDAS) FROM VENDAS_AGUA va2)
    ),
    
    -- Terceira CTE: Calcula o total de produtos vendidos pela máquina selecionada em fevereiro
    TOTAL_PRODUTOS_VENDIDOS AS (
        SELECT 
            COUNT(*) AS TOTAL
        FROM VENDAS v, COMPARTIMENTOS c , MAQUINA_VENDEU_MAIS mvm
        WHERE 
            -- Junção entre tabelas
            c.ID_COMPARTIMENTO = v.ID_COMPARTIMENTO
            AND mvm.MAQ = c.ID_MAQUINA
            -- Filtra apenas vendas de fevereiro
            AND EXTRACT(MONTH FROM v.DATA_HORA_VENDA) = 2
            -- Filtra apenas vendas do ano atual
            AND EXTRACT(YEAR FROM v.DATA_HORA_VENDA) = EXTRACT(YEAR FROM SYSDATE)
    )
    
    -- Consulta principal que retorna os resultados
    SELECT 
         m.ID_MAQUINA AS IDMAQUINA,               -- ID da máquina
         p.REFERENCIA AS REFPRODUTO,              -- Referência do produto
         COUNT(v.ID_VENDA) AS QUANT_VENDIDA,      -- Quantidade vendida
         -- Percentagem do total de vendas da máquina
         (COUNT(v.ID_VENDA) / (SELECT TOTAL FROM TOTAL_PRODUTOS_VENDIDOS))*100 AS PERCENTAGEM,
         -- Quantidade reabastecida
         SUM(r.QUANTIDADE_REABASTECIMENTO) AS QUANT_REABASTECIDA
    FROM PRODUTOS p, VENDAS v, COMPARTIMENTOS c, MAQUINAS m, MAQUINA_VENDEU_MAIS mvm, REABASTECIMENTOS r
    WHERE
        -- Junção entre tabelas
        v.ID_PRODUTO = p.ID_PRODUTO
        AND c.ID_COMPARTIMENTO = v.ID_COMPARTIMENTO
        AND m.ID_MAQUINA = c.ID_MAQUINA
        -- Filtra apenas a máquina que mais vendeu
        AND mvm.MAQ = m.ID_MAQUINA
        -- Junção com reabastecimentos
        AND r.ID_COMPARTIMENTO = c.ID_COMPARTIMENTO 
        AND r.ID_PRODUTO = p.ID_PRODUTO
        -- Filtra apenas produtos do tipo 'agua'
        AND LOWER(p.TIPO_PRODUTO) = 'agua'
        -- Filtra apenas fevereiro para vendas
        AND EXTRACT(MONTH FROM v.DATA_HORA_VENDA) = 2
        -- Filtra apenas fevereiro para reabastecimentos
        AND EXTRACT(MONTH FROM r.DATA_HORA_REABASTECIMENTO) = 2
        -- Filtra apenas ano atual para vendas
        AND EXTRACT(YEAR FROM v.DATA_HORA_VENDA) = EXTRACT(YEAR FROM SYSDATE)
        -- Filtra apenas ano atual para reabastecimentos
        AND EXTRACT(YEAR FROM r.DATA_HORA_REABASTECIMENTO) = EXTRACT(YEAR FROM SYSDATE)
    -- Agrupa por máquina e referência do produto
    GROUP BY
        m.ID_MAQUINA, p.REFERENCIA;
    
SELECT * FROM VIEW_F;

----------------------------------------------------------- VIEW G ---------------------------------------  
CREATE OR REPLACE VIEW VIEW_G AS 
-- CTE 1: Filtra reabastecimentos do ano anterior em máquinas de Coimbra
WITH FILTRO_REABASTECIMENTOS AS (
    SELECT 
        p.TIPO_PRODUTO,               -- Tipo de produto reabastecido
        v.ID_VIAGEM,                  -- ID da viagem associada
        SUM(r.QUANTIDADE_REABASTECIMENTO) AS TOTAL_REABASTECIDO  -- Soma das quantidades reabastecidas
    FROM REABASTECIMENTOS r, COMPARTIMENTOS c, MAQUINAS m, PRODUTOS p, VISITAS vi, VIAGENS v
    WHERE 
        -- Junções entre tabelas:
        c.ID_COMPARTIMENTO = r.ID_COMPARTIMENTO      -- Relaciona reabastecimento com compartimento
        AND m.ID_MAQUINA = c.ID_MAQUINA             -- Relaciona compartimento com máquina
        AND p.ID_PRODUTO = r.ID_PRODUTO             -- Relaciona reabastecimento com produto
        AND vi.ID_VISITA = r.ID_VISITA              -- Relaciona reabastecimento com visita
        AND v.ID_VIAGEM = vi.ID_VIAGEM              -- Relaciona visita com viagem
        -- Filtros:
        AND EXTRACT(YEAR FROM r.DATA_HORA_REABASTECIMENTO) = EXTRACT(YEAR FROM SYSDATE) - 1  -- Ano anterior
        AND LOWER(m.LOCALIZACAO_MAQUINA) LIKE '%coimbra%'  -- Máquinas em Coimbra (case insensitive)
    -- Agrupa por tipo de produto e viagem
    GROUP BY p.TIPO_PRODUTO, v.ID_VIAGEM
),

-- CTE 2: Identifica viagens válidas (com mais de 3 máquinas distintas visitadas)
VIAGENS_VALIDAS AS (
    SELECT 
        v.ID_VIAGEM
    FROM VIAGENS v, VISITAS vi
    WHERE 
        vi.ID_VIAGEM = v.ID_VIAGEM  -- Relaciona visita com viagem
    GROUP BY v.ID_VIAGEM
    -- Filtra apenas viagens com mais de 3 máquinas diferentes visitadas
    HAVING COUNT(DISTINCT vi.ID_MAQUINA) >= 3
),

-- CTE 3: Seleciona os 2 tipos de produto mais reabastecidos por viagem
TOP_2_TIPOS AS (
    SELECT 
        fr.TIPO_PRODUTO,            -- Tipo de produto
        fr.ID_VIAGEM,               -- ID da viagem
        fr.TOTAL_REABASTECIDO,       -- Total reabastecido (já calculado na CTE anterior)
        -- Subconsulta para contar máquinas distintas visitadas nesta viagem
        (SELECT COUNT(DISTINCT vi2.ID_MAQUINA) 
         FROM VISITAS vi2 
         WHERE vi2.ID_VIAGEM = fr.ID_VIAGEM) AS NUM_MAQUINAS ,
        -- Numera os produtos por viagem, ordenados pelo total reabastecido (do maior para o menor)
        ROW_NUMBER() OVER (PARTITION BY fr.ID_VIAGEM ORDER BY fr.TOTAL_REABASTECIDO DESC) AS RANKING
    FROM FILTRO_REABASTECIMENTOS fr
    -- Filtra apenas viagens válidas (com mais de 3 máquinas visitadas)
    WHERE fr.ID_VIAGEM IN (SELECT ID_VIAGEM FROM VIAGENS_VALIDAS)
)

-- Consulta principal que retorna os resultados
SELECT 
    t.ID_VIAGEM AS VIAGEM,                  -- ID da viagem
    t.TIPO_PRODUTO AS TIPO_PRODUTO,          -- Tipo de produto
    t.TOTAL_REABASTECIDO AS QUANT_ABASTECIDA,-- Quantidade total reabastecida
    t.NUM_MAQUINAS AS NUM_MAQ_ABASTECIDAS    -- Número de máquinas abastecidas
FROM TOP_2_TIPOS t
-- Filtra apenas os 2 produtos mais reabastecidos por viagem
WHERE t.RANKING <= 2;

SELECT * FROM VIEW_G;
    
----------------------------------------------------------- VIEW H ---------------------------------------  
CREATE OR REPLACE VIEW VIEW_H AS 
-- CTE 1: Identifica viagens válidas que atendem aos critérios especificados
WITH VIAGENS_VALIDAS AS (
    SELECT
        vi.ID_VIAGEM,                      -- ID da viagem
        ve.ID_VEICULO,                     -- ID do veículo utilizado
        COUNT(DISTINCT m.ID_MAQUINA) AS N_MAQUINAS_REABASTECIDAS  -- Conta máquinas distintas reabastecidas
    FROM VIAGENS vi, VEICULOS ve, VISITAS vs, REABASTECIMENTOS r, COMPARTIMENTOS c, PRODUTOS p, MAQUINAS m
    WHERE
        -- Relaciona viagens com veículos
        ve.ID_VEICULO = vi.ID_VEICULO
        -- Relaciona viagens com visitas
        AND vs.ID_VIAGEM = vi.ID_VIAGEM
        -- Relaciona visitas com reabastecimentos
        AND r.ID_VISITA = vs.ID_VISITA
        -- Relaciona reabastecimentos com compartimentos
        AND r.ID_COMPARTIMENTO = c.ID_COMPARTIMENTO
        -- Relaciona reabastecimentos com produtos
        AND r.ID_PRODUTO = p.ID_PRODUTO
        -- Relaciona compartimentos com máquinas
        AND c.ID_MAQUINA = m.ID_MAQUINA
        -- Filtra apenas viagens com mais de 50km
        AND vi.DISTANCIA_PERCORRIDA > 50
        -- Filtra viagens do mês passado
        AND EXTRACT(MONTH FROM vi.DATA_FIM_VIAGEM) = EXTRACT(MONTH FROM SYSDATE) - 1
        -- Considera apenas o ano atual
        AND EXTRACT(YEAR FROM vi.DATA_FIM_VIAGEM) = EXTRACT(YEAR FROM SYSDATE)
        -- Filtra apenas produtos do tipo 'agua' (case insensitive)
        AND LOWER(p.TIPO_PRODUTO) = 'agua'
    -- Agrupa por viagem e veículo
    GROUP BY
        vi.ID_VIAGEM, ve.ID_VEICULO
    -- Filtra apenas viagens que reabasteceram 3+ máquinas distintas
    HAVING 
        COUNT(DISTINCT m.ID_MAQUINA) >= 3
),

-- CTE 2: Classifica os veículos por número de viagens válidas
VEICULOS_RANKING AS (
    SELECT
        ve.ID_VEICULO AS VEICULO,          -- ID do veículo
        COUNT(DISTINCT vv.ID_VIAGEM) AS TOTAL_VIAGENS,  -- Conta viagens distintas
        SUM(vv.N_MAQUINAS_REABASTECIDAS) AS N_MAQUINAS_REABASTECIDAS,  -- Soma máquinas reabastecidas
        -- Atribui um ranking único baseado no número de viagens (decrescente)
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT vv.ID_VIAGEM) DESC) AS RANKING
    FROM VIAGENS_VALIDAS vv, VEICULOS ve
    -- Relaciona veículos com suas viagens válidas
    WHERE ve.ID_VEICULO = vv.ID_VEICULO
    -- Agrupa por veículo
    GROUP BY ve.ID_VEICULO
)

-- Consulta final que retorna os 5 veículos mais utilizados
SELECT
    ve.MATRICULA,                          -- Matrícula do veículo
    ve.MARCA,                              -- Marca do veículo
    ve.MODELO,                             -- Modelo do veículo
    vr.TOTAL_VIAGENS,                      -- Total de viagens válidas
    vr.N_MAQUINAS_REABASTECIDAS            -- Total de máquinas reabastecidas
FROM VEICULOS ve, VEICULOS_RANKING vr
WHERE 
    -- Relaciona veículos com seu ranking
    vr.VEICULO = ve.ID_VEICULO
    -- Filtra apenas os 5 primeiros no ranking
    AND vr.RANKING <= 5;
    
SELECT * FROM VIEW_H;

----------------------------------------------------------- VIEW I ----------------------------------------------------------
CREATE OR REPLACE VIEW VIEW_I AS
-- CTE 1: Contagem de viagens por armazém no ano atual
WITH ARMAZEM_VIAGENS AS (
    SELECT 
        r.ID_ARMAZEM,                   -- ID do armazém
        COUNT(vi.ID_VIAGEM) AS NUM_VIAGENS  -- Contagem total de viagens
    FROM VIAGENS vi, ROTAS r             -- Tabelas: Viagens e Rotas
    WHERE vi.ID_ROTA = r.ID_ROTA         -- Relacionamento: Viagem tem uma Rota que por sua vez comeca num Armazem
    AND EXTRACT(YEAR FROM vi.DATA_INICIO_VIAGEM) = EXTRACT(YEAR FROM SYSDATE)  -- Filtro: ano atual
    GROUP BY r.ID_ARMAZEM                -- Agrupado por armazém
),

-- CTE 2: Identifica o armazém com maior número de viagens
ARMAZEM_MAIS_VIAGENS AS (
    SELECT ID_ARMAZEM
    FROM ARMAZEM_VIAGENS
    WHERE NUM_VIAGENS = (SELECT MAX(NUM_VIAGENS) FROM ARMAZEM_VIAGENS)  -- Seleciona o(s) armazém(ns) com máximo de viagens
),

-- CTE 3: Calcula métricas de visitas para cada máquina
VISITAS_MAQUINAS AS (
    SELECT 
        m.ID_MAQUINA,                    -- ID da máquina
        a.LOCALIZACAO AS ARMAZEM,        -- Localização do armazém de origem
        m.LOCALIZACAO_MAQUINA AS MAQUINA, -- Localização da máquina
        COUNT(vs.ID_VISITA) AS N_VISITAS, -- Total de visitas à máquina
        SUM(r.QUANTIDADE_REABASTECIMENTO) AS QUANT_TOTAL, -- Quantidade total reabastecida
        COUNT(DISTINCT r.ID_PRODUTO) AS N_PROD_DIF -- Número de produtos distintos reabastecidos
    FROM 
        VISITAS vs, VIAGENS vi, ROTAS ro, 
        ARMAZEM a, MAQUINAS m, REABASTECIMENTOS r  -- Todas as tabelas necessárias
    WHERE 
        -- Relacionamentos entre tabelas:
        vi.ID_VIAGEM = vs.ID_VIAGEM       -- Visita pertence a uma Viagem
        AND vi.ID_ROTA = ro.ID_ROTA       -- Viagem pertence a uma Rota
        AND ro.ID_ARMAZEM = a.ID_ARMAZEM  -- Rota pertence a um Armazém
        AND m.ID_MAQUINA = vs.ID_MAQUINA  -- Visita ocorreu em uma Máquina
        AND r.ID_VISITA = vs.ID_VISITA    -- Reabastecimento ocorreu em uma Visita
        -- Filtros adicionais:
        AND EXTRACT(YEAR FROM vi.DATA_INICIO_VIAGEM) = EXTRACT(YEAR FROM SYSDATE)  -- Viagens do ano atual
        AND ro.ID_ARMAZEM = (SELECT ID_ARMAZEM FROM ARMAZEM_MAIS_VIAGENS)  -- Apenas viagens do armazém mais ativo
    GROUP BY 
        m.ID_MAQUINA, a.LOCALIZACAO, m.LOCALIZACAO_MAQUINA  -- Agrupado por máquina
),

-- CTE 4: Classifica as máquinas por número de visitas
TOP_MAQUINAS AS (
    SELECT 
        ARMAZEM,
        MAQUINA,
        N_VISITAS,
        QUANT_TOTAL,
        ROUND(QUANT_TOTAL/N_VISITAS, 2) AS QUANT_MEDIA_VISITA,  -- Média de reabastecimento por visita
        N_PROD_DIF,
        ROW_NUMBER() OVER (ORDER BY N_VISITAS DESC) AS RN  -- Classificação por número de visitas
    FROM VISITAS_MAQUINAS
)

-- Consulta final: Seleciona as 3 máquinas mais visitadas
SELECT 
    ARMAZEM,                -- Localização do armazém de origem
    MAQUINA,                -- Localização da máquina
    N_VISITAS,              -- Número total de visitas
    QUANT_TOTAL,            -- Quantidade total reabastecida
    QUANT_MEDIA_VISITA,     -- Média reabastecida por visita
    N_PROD_DIF              -- Número de produtos distintos reabastecidos
FROM TOP_MAQUINAS
WHERE RN <= 3;              -- Filtra apenas as top 3 máquinas

SELECT * FROM VIEW_I;


----------------------------------------------------------- VIEW Daniel Silva (Select Encadeado) ------------------------------- 
CREATE OR REPLACE VIEW VIEW_K_2023144551 AS
-- View que mostra o desempenho de produtos em cada máquina
-- Objetivo: Analisar a performance de vendas e reabastecimento de produtos por máquina no mês atual

WITH VENDAS_MAQUINA AS (
    -- CTE que calcula as vendas por máquina e produto
    -- Agrupa por máquina e produto, indicando numero de vendas e soma dos valores obtidos
    SELECT 
        m.ID_MAQUINA,
        m.LOCALIZACAO_MAQUINA AS LOCALIZACAO_MAQUINA,  -- Localização física da máquina
        p.ID_PRODUTO,
        p.NOME_PRODUTO,                         -- Nome do produto para melhor legibilidade
        COUNT(v.ID_VENDA) AS QTD_VENDAS,         -- Total de vendas deste produto na máquina
        SUM(v.VALOR_PAGO) AS TOTAL_VENDIDO       -- Valor total vendido deste produto na máquina
    FROM 
        MAQUINAS m, COMPARTIMENTOS c, VENDAS v, PRODUTOS p
    WHERE 
        -- Junções entre tabelas:
        m.ID_MAQUINA = c.ID_MAQUINA             -- Relaciona máquina com seus compartimentos
        AND c.ID_COMPARTIMENTO = v.ID_COMPARTIMENTO  -- Relaciona compartimento com vendas
        AND v.ID_PRODUTO = p.ID_PRODUTO         -- Relaciona vendas com produtos
        -- Filtro temporal: apenas vendas do mês atual
        AND EXTRACT(MONTH FROM v.DATA_HORA_VENDA) = EXTRACT(MONTH FROM SYSDATE)
        AND EXTRACT(YEAR FROM v.DATA_HORA_VENDA) = EXTRACT(YEAR FROM SYSDATE)
    GROUP BY 
        m.ID_MAQUINA, m.LOCALIZACAO_MAQUINA, p.ID_PRODUTO, p.NOME_PRODUTO
),

REABASTECIMENTOS_MAQUINA AS (
    -- CTE que calcula os reabastecimentos por máquina e produto
    -- Agrupa por máquina e produto, somando quantidades reabastecidas
    SELECT 
        m.ID_MAQUINA,
        p.ID_PRODUTO,
        SUM(r.QUANTIDADE_REABASTECIMENTO) AS QTD_REABASTECIDA  -- Total reabastecido deste produto na máquina
    FROM 
        MAQUINAS m, COMPARTIMENTOS c, REABASTECIMENTOS r, PRODUTOS p
    WHERE 
        -- Junções entre tabelas:
        m.ID_MAQUINA = c.ID_MAQUINA             -- Relaciona máquina com seus compartimentos
        AND c.ID_COMPARTIMENTO = r.ID_COMPARTIMENTO  -- Relaciona compartimento com reabastecimentos
        AND r.ID_PRODUTO = p.ID_PRODUTO         -- Relaciona reabastecimentos com produtos
        -- Filtro temporal: apenas reabastecimentos do mês atual
        AND EXTRACT(MONTH FROM r.DATA_HORA_REABASTECIMENTO) = EXTRACT(MONTH FROM SYSDATE)
        AND EXTRACT(YEAR FROM r.DATA_HORA_REABASTECIMENTO) = EXTRACT(YEAR FROM SYSDATE)
    GROUP BY 
        m.ID_MAQUINA, p.ID_PRODUTO
)

-- Consulta principal que combina os dados de vendas e reabastecimento
SELECT 
    vm.ID_MAQUINA,
    vm.LOCALIZACAO_MAQUINA,
    vm.NOME_PRODUTO,
    vm.QTD_VENDAS,                              -- Número de vendas do produto na máquina
    vm.TOTAL_VENDIDO,                           -- Valor total vendido do produto na máquina
    rm.QTD_REABASTECIDA,                        -- Quantidade total reabastecida do produto na máquina
    -- Cálculo da taxa de conversão (vendas/reabastecimento em percentual)
    -- Evita divisão por zero com filtro WHERE rm.QTD_REABASTECIDA > 0
    ROUND(vm.QTD_VENDAS / rm.QTD_REABASTECIDA * 100, 2) AS TAXA_CONVERSAO  
FROM 
    VENDAS_MAQUINA vm,  REABASTECIMENTOS_MAQUINA rm
WHERE 
    -- Junção das duas CTEs:
    vm.ID_MAQUINA = rm.ID_MAQUINA               -- Pela mesma máquina
    AND vm.ID_PRODUTO = rm.ID_PRODUTO           -- E pelo mesmo produto
    -- Filtro para evitar divisão por zero:
    AND rm.QTD_REABASTECIDA > 0                 -- Apenas produtos que foram reabastecidos
-- Ordenação dos resultados:
ORDER BY 
    vm.LOCALIZACAO_MAQUINA,                     -- Primeiro por localização da máquina
    vm.TOTAL_VENDIDO DESC;                      -- Depois por valor total vendido (maior primeiro)

SELECT * FROM VIEW_K_2023144551;

----------------------------------------------------------- VIEW Daniel Silva (Group By) ---------------------------------------  
CREATE OR REPLACE VIEW VIEW_J_2023144551 AS
-- View que analisa a utilização de veículos por armazém no mês anterior
-- Objetivo: Avaliar a eficiência dos veículos por armazém

SELECT 
    a.ID_ARMAZEM,                           -- Identificador único do armazém
    a.LOCALIZACAO AS LOCAL_ARMAZEM,         -- Localização física do armazém
    v.MATRICULA,                            -- Matrícula do veículo
    v.MARCA,                                -- Marca do veículo
    v.MODELO,                               -- Modelo do veículo
    COUNT(DISTINCT vi.ID_VIAGEM) AS QTD_VIAGENS, -- Número total de viagens realizadas
    SUM(vi.DISTANCIA_PERCORRIDA) AS TOTAL_KM, -- Soma de todos os quilômetros percorridos
    ROUND(AVG(vi.DISTANCIA_PERCORRIDA), 2) AS MEDIA_KM_POR_VIAGEM, -- Média de km por viagem
    COUNT(DISTINCT vs.ID_MAQUINA) AS MAQUINAS_VISITADAS, -- Número de máquinas diferentes visitadas
    COUNT(DISTINCT p.ID_PRODUTO) AS N_PRODUTOS_DIF_REABASTECIDOS, -- Número de produtos diferentes usados nos reabastecimentos
    -- Cálculo de eficiência: km total / (capacidade máxima * número de viagens)
    -- Mostra quantos km foram percorridos por unidade de capacidade transportada
    ROUND(SUM(vi.DISTANCIA_PERCORRIDA) / MAX(v.CAPACIDADE_CARGA_VEICULO) * COUNT(DISTINCT vi.ID_VIAGEM), 2) AS EFICIENCIA_CARGA
FROM 
    ARMAZEM a, VEICULOS v, VIAGENS vi, VISITAS vs, REABASTECIMENTOS r, PRODUTOS p
WHERE 
    -- Relacionamentos entre tabelas:
    v.ID_ARMAZEM = a.ID_ARMAZEM           -- Liga veículo ao seu armazém de origem
    AND vi.ID_VEICULO = v.ID_VEICULO      -- Liga viagem ao veículo utilizado
    AND vs.ID_VIAGEM = vi.ID_VIAGEM       -- Liga visita à viagem correspondente
    AND r.ID_VISITA = vs.ID_VISITA        -- Liga reabastecimento à visita
    AND p.ID_PRODUTO = r.ID_PRODUTO       -- Liga produto ao reabastecimento
    -- Filtros temporais (mês anterior ao atual):
    AND EXTRACT(MONTH FROM vi.DATA_INICIO_VIAGEM) = EXTRACT(MONTH FROM ADD_MONTHS(SYSDATE, -1))
    AND EXTRACT(YEAR FROM vi.DATA_INICIO_VIAGEM) = EXTRACT(YEAR FROM SYSDATE)
    
-- Agrupamento por características do armazém e veículo
GROUP BY 
    a.ID_ARMAZEM, a.LOCALIZACAO, v.MATRICULA, v.MARCA, v.MODELO
-- Filtra apenas veículos que realizaram viagens no período
HAVING COUNT(DISTINCT vi.ID_VIAGEM) > 0
-- Ordena resultados por:
ORDER BY 
    a.LOCALIZACAO,                        -- 1º: Localização do armazém (ordem alfabética)
    QTD_VIAGENS DESC;                      -- 2º: Quantidade de viagens (maior para menor)
    
SELECT * FROM VIEW_J_2023144551;

----------------------------------------------------------- VIEW Guilherme Martins (Select Encadeado) --------------------------
CREATE OR REPLACE VIEW VIEW_K_2023144573 AS
-- CTE para calcular o lucro por viagem
WITH LucroPorViagem AS (
    SELECT 
        v.ID_VIAGEM,                  -- Identificador único da viagem
        r.ID_ROTA,                    -- Identificador da rota associada
        r.NOME_ROTA,                  -- Nome da rota para exibição
        TO_CHAR(v.DATA_INICIO_VIAGEM, 'YYYY') AS ANO,  -- Extrai o ano da data de início da viagem
        -- Subquery para somar o valor total das vendas relacionadas à viagem
        (SELECT SUM(ve.VALOR_PAGO)
         FROM VENDAS ve, COMPARTIMENTOS c, VISITAS vi  -- Junção implícita entre vendas, compartimentos e visitas
         WHERE vi.ID_VIAGEM = v.ID_VIAGEM              -- Relaciona visitas à viagem atual
         AND ve.ID_COMPARTIMENTO = c.ID_COMPARTIMENTO  -- Liga vendas aos compartimentos
         AND c.ID_MAQUINA = vi.ID_MAQUINA) AS VALOR_VENDAS,  -- Liga compartimentos às máquinas visitadas
        (v.DISTANCIA_PERCORRIDA * 0.5) AS CUSTO_VIAGEM  -- Calcula custo estimado (0.5€ por km)
    FROM 
        VIAGENS v, ROTAS r          -- Junção implícita entre viagens e rotas
    WHERE
        v.ID_ROTA = r.ID_ROTA       -- Condição para combinar viagens com suas rotas correspondentes
),
-- CTE para agregar o lucro por rota e ano
LucroPorRota AS (
    SELECT 
        ANO,                        -- Ano da viagem
        ID_ROTA,                    -- Identificador da rota
        NOME_ROTA,                  -- Nome da rota
        SUM(NVL(VALOR_VENDAS, 0) - CUSTO_VIAGEM) AS LUCRO_LIQUIDO,  -- Calcula o lucro líquido
        ROW_NUMBER() OVER (PARTITION BY ANO ORDER BY SUM(NVL(VALOR_VENDAS, 0) - CUSTO_VIAGEM) DESC) AS RANK_ROTA  -- Número único por ano, ordenado por lucro
    FROM 
        LucroPorViagem              -- Usa os dados da CTE anterior
    GROUP BY 
        ANO, ID_ROTA, NOME_ROTA     -- Agrupa por ano e rota
),
-- CTE para calcular o produto mais transportado por rota e ano
ProdutoMaisTransportado AS (
    SELECT 
        v.ID_ROTA,                  -- Identificador da rota
        TO_CHAR(v.DATA_INICIO_VIAGEM, 'YYYY') AS ANO,  -- Ano da viagem
        p.NOME_PRODUTO,             -- Nome do produto
        SUM(pv.QUANTIDADE_PV) AS TOTAL_QUANTIDADE,  -- Soma total da quantidade transportada
        ROW_NUMBER() OVER (PARTITION BY v.ID_ROTA, TO_CHAR(v.DATA_INICIO_VIAGEM, 'YYYY') 
                          ORDER BY SUM(pv.QUANTIDADE_PV) DESC) AS RN  -- Número único por rota e ano, ordenado por quantidade
    FROM 
        PRODUTO_VIAGEM pv, PRODUTOS p, VIAGENS v  -- Junção implícita entre produtos_viagem, produtos e viagens
    WHERE 
        pv.ID_PRODUTO = p.ID_PRODUTO               -- Liga produtos transportados aos seus nomes
        AND pv.ID_VIAGEM = v.ID_VIAGEM             -- Liga produtos às viagens
    GROUP BY 
        v.ID_ROTA, TO_CHAR(v.DATA_INICIO_VIAGEM, 'YYYY'), p.NOME_PRODUTO  -- Agrupa por rota, ano e produto
)
-- Seleção final dos dados da view
SELECT 
    lr.ANO,                         -- Ano da rota mais lucrativa
    lr.NOME_ROTA,                   -- Nome da rota mais lucrativa
    lr.LUCRO_LIQUIDO,               -- Lucro líquido calculado
    -- Subquery para obter o produto mais transportado, usando a CTE ProdutoMaisTransportado
    (
        SELECT pmt.NOME_PRODUTO || ' (' || pmt.TOTAL_QUANTIDADE || ')'  -- Concatena nome do produto e quantidade
        FROM ProdutoMaisTransportado pmt
        WHERE pmt.ID_ROTA = lr.ID_ROTA  -- Filtra pela rota atual
        AND pmt.ANO = lr.ANO            -- Filtra pelo ano atual
        AND pmt.RN = 1                  -- Seleciona o produto com maior quantidade (ROW_NUMBER = 1)
    ) AS PRODUTO_MAIS_TRANSPORTADO      -- Nomeia a coluna com o produto mais transportado
FROM 
    LucroPorRota lr                     -- Usa os dados agregados da CTE LucroPorRota
WHERE 
    lr.RANK_ROTA = 1                    -- Filtra apenas a rota mais lucrativa de cada ano
ORDER BY 
    lr.ANO;                             -- Ordena os resultados por ano
    
SELECT * FROM VIEW_K_2023144573;
----------------------------------------------------------- VIEW Guilherme Martins (Group By) ----------------------------------
-- Cria ou substitui a view VIEW_J_2023144573
CREATE OR REPLACE VIEW VIEW_J_2023144573 AS
-- Seleção dos dados da view com junções implícitas
SELECT 
    p.TIPO_PRODUTO,                    -- Tipo de produto vendido (e.g., snacks, bebida, agua)
    m.ID_MAQUINA,                      -- Identificador único da máquina
    m.LOCALIZACAO_MAQUINA,             -- Localização da máquina (e.g., Coimbra Estação)
    TO_CHAR(v.DATA_HORA_VENDA, 'YYYY-MM') AS MES_ANO,  -- Mês e ano da venda no formato YYYY-MM
    COUNT(v.ID_VENDA) AS TOTAL_VENDAS, -- Total de vendas realizadas no mês por tipo de produto e máquina
    SUM(v.VALOR_PAGO) AS TOTAL_FATURADO,  -- Soma do valor pago em todas as vendas
    ROUND(AVG(v.VALOR_PAGO), 2) AS VALOR_MEDIO_VENDA,  -- Média arredondada do valor pago por venda
    MAX(v.VALOR_PAGO) AS MAIOR_VENDA,  -- Maior valor pago em uma única venda
    MIN(v.VALOR_PAGO) AS MENOR_VENDA,  -- Menor valor pago em uma única venda
    -- Subquery para contar o número de compartimentos ativos por máquina
    (SELECT COUNT(*) 
     FROM COMPARTIMENTOS c2, MAQUINAS m2  -- Junção implícita entre compartimentos e máquinas
     WHERE m2.ID_MAQUINA = m.ID_MAQUINA   -- Filtra pela máquina atual
     AND c2.ID_MAQUINA = m2.ID_MAQUINA) AS COMPARTIMENTOS_ATIVOS  -- Conta os compartimentos associados
FROM 
    VENDAS v, PRODUTOS p, COMPARTIMENTOS c, MAQUINAS m  -- Junção implícita entre vendas, produtos, compartimentos e máquinas
WHERE 
    v.ID_PRODUTO = p.ID_PRODUTO         -- Relaciona vendas aos produtos
    AND v.ID_COMPARTIMENTO = c.ID_COMPARTIMENTO  -- Relaciona vendas aos compartimentos
    AND c.ID_MAQUINA = m.ID_MAQUINA     -- Relaciona compartimentos às máquinas
GROUP BY 
    p.TIPO_PRODUTO,                     -- Agrupa por tipo de produto
    m.ID_MAQUINA,                       -- Agrupa por máquina
    m.LOCALIZACAO_MAQUINA,              -- Agrupa por localização da máquina
    TO_CHAR(v.DATA_HORA_VENDA, 'YYYY-MM')  -- Agrupa por mês e ano
HAVING 
    COUNT(v.ID_VENDA) >= 3            -- Filtra apenas grupos com 5 ou mais vendas
ORDER BY 
    TO_CHAR(v.DATA_HORA_VENDA, 'YYYY-MM'),  -- Ordena por mês e ano
    p.TIPO_PRODUTO,                     -- Ordena por tipo de produto
    TOTAL_FATURADO DESC;                -- Ordena por faturamento total em ordem decrescente
    
SELECT * FROM VIEW_J_2023144573;
----------------------------------------------------------- VIEW Rafael Felix (Select Encadeado) -------------------------------
CREATE OR REPLACE VIEW VIEW_K_2023144606 AS
-- View para controlo preventivo de stock em máquinas
-- Objetivo: Identificar máquinas com risco de ruptura ou com níveis de stock críticos

WITH produtos_em_ruptura AS (
    -- CTE que conta rupturas por máquina nos últimos 7 dias
    -- Ruptura = quando um produto esgota em um compartimento
    SELECT 
        c.ID_MAQUINA,
        COUNT(rp.ID_RUPTURA) AS rupturas_ultima_semana  -- Contagem de ocorrências
    FROM
        RUPTURAS rp, 
        COMPARTIMENTOS c
    WHERE
        rp.ID_COMPARTIMENTO = c.ID_COMPARTIMENTO  -- Relaciona ruptura ao compartimento
        AND rp.DATA_HORA_RUPTURA >= SYSDATE - 7   -- Filtra apenas última semana
    GROUP BY
        c.ID_MAQUINA  -- Agrupa resultados por máquina
),

stock_atual AS (
    -- CTE que calcula níveis de stock atuais
    -- Mostra a ocupação percentual de cada compartimento
    SELECT 
        c.ID_MAQUINA,
        c.ID_PRODUTO,
        c.QUANTIDADE_COMPARTIMENTO,  -- Quantidade atual no compartimento
        c.CAPACIDADE_MAXIMA,         -- Capacidade total do compartimento
        ROUND((c.QUANTIDADE_COMPARTIMENTO / c.CAPACIDADE_MAXIMA) * 100) AS percentual_ocupacao  -- % de ocupação
    FROM 
        COMPARTIMENTOS c
)

-- Consulta principal que combina os dados
SELECT 
    m.ID_MAQUINA,                   -- Identificador único da máquina
    m.LOCALIZACAO_MAQUINA AS LOCALIZACAO_MAQUINA,  -- Onde a máquina está instalada
    m.ESTADO_MAQUINA,               -- Status operacional (ativo, inativo, etc.)
    NVL(p.rupturas_ultima_semana, 0) AS rupturas_recentes,  -- Nº de rupturas (substitui NULL por 0)
    COUNT(s.ID_PRODUTO) AS compartimentos_baixos,  -- Qtd de compartimentos com <30% stock
    MIN(s.percentual_ocupacao) AS menor_nivel_stock  -- Menor % de ocupação encontrado
FROM 
    MAQUINAS m
LEFT JOIN produtos_em_ruptura p ON m.ID_MAQUINA = p.ID_MAQUINA  -- Junta com rupturas
JOIN stock_atual s ON m.ID_MAQUINA = s.ID_MAQUINA  -- Junta com níveis de stock
WHERE 
    s.percentual_ocupacao < 30  -- Filtra apenas compartimentos com stock baixo ( < 30%)
GROUP BY 
    m.ID_MAQUINA, 
    m.LOCALIZACAO_MAQUINA, 
    m.ESTADO_MAQUINA, 
    p.rupturas_ultima_semana
HAVING 
    COUNT(s.ID_PRODUTO) > 0      -- Máquinas com compartimentos baixos
    OR NVL(p.rupturas_ultima_semana, 0) > 0  -- OU com rupturas recentes
ORDER BY 
    rupturas_recentes DESC,      -- Ordena por maior número de rupturas primeiro
    compartimentos_baixos DESC;  -- Depois por maior número de compartimentos críticos
    
SELECT * FROM VIEW_K_2023144606;
----------------------------------------------------------- VIEW Rafael Felix (Group By) ---------------------------------------  
CREATE OR REPLACE VIEW VIEW_J_2023144606 AS
-- View de Análise de Desempenho de Funcionários (Motoristas)
-- Objetivo: Controlar a produtividade dos motoristas de cada armazem

SELECT 
    f.ID_FUNCIONARIO,               -- Código único do funcionário
    f.NOME_FUNCIONARIO,             -- Nome completo do motorista
    f.NIF,                          -- Número de identificação fiscal
    a.LOCALIZACAO AS ARMAZEM_BASE,  -- Localização do armazém de origem

    COUNT(vi.ID_VIAGEM) AS NUMERO_VIAGENS,          -- Total de viagens realizadas
    SUM(vi.DISTANCIA_PERCORRIDA) AS TOTAL_KM_PERCORRIDOS,  -- Soma de quilômetros percorridos
    
    COUNT(DISTINCT vis.ID_MAQUINA) AS NUM_MAQUINAS_VISITADAS,  -- Máquinas diferentes atendidas
    COUNT(DISTINCT pv.ID_PRODUTO) AS TIPOS_PRODUTOS_DIFERENTES -- Variedade de produtos transportados

FROM 
    FUNCIONARIOS f , ARMAZEM a , VIAGENS vi , VISITAS vis , PRODUTO_VIAGEM pv
WHERE
    f.ID_ARMAZEM = a.ID_ARMAZEM  -- Relaciona o funcionário com seu armazém base
    AND f.ID_FUNCIONARIO = vi.ID_FUNCIONARIO   -- Relaciona o funcionário com suas viagens
    AND vi.ID_VIAGEM = vis.ID_VIAGEM -- Relaciona viagens com visitas realizadas
    AND vi.ID_VIAGEM = pv.ID_VIAGEM -- Relaciona viagens com produtos transportados
-- Agrupamento por funcionário (todos os dados são consolidados por motorista)
GROUP BY 
    f.ID_FUNCIONARIO, f.NOME_FUNCIONARIO, f.NIF, a.LOCALIZACAO
-- Ordena os resultados pelo número de viagens (mais produtivos primeiro)
ORDER BY 
    NUMERO_VIAGENS DESC; -- Ordena pelo numero de viagens de cada motorista (mais para menos)
    
    
SELECT * FROM VIEW_J_2023144606;