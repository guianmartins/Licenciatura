-- Testes para Funções

-- 1. distancia_linear
SELECT distancia_linear(38.7223, -9.1393, 41.1579, -8.6291) AS distancia FROM dual;
-- Esperado: ~274.3 km (Lisboa-Porto)

-- 2. quantidade_em_falta
SELECT quantidade_em_falta(1, 1) AS falta FROM dual;
-- Esperado: 90 
SELECT quantidade_em_falta(999, 1) FROM dual; -- Erro: -20801
SELECT quantidade_em_falta(1, 999) FROM dual; -- Erro: -20802

-- 3. distancia_entre_maquinas
SELECT distancia_entre_maquinas(1, 2) AS distancia FROM dual;
-- Esperado: ~108 km 
SELECT distancia_entre_maquinas(1, 1) FROM dual; -- Erro: -20810
SELECT distancia_entre_maquinas(999, 2) FROM dual; -- Erro: -20801

-- 4. prox_maquina_sem_produto
SELECT prox_maquina_sem_produto('AGUA500', 1) AS maquina FROM dual;
-- Esperado: 2 (Coimbra, sem stock)
SELECT prox_maquina_sem_produto('AGUA500', 999) FROM dual; -- Erro: -20801
SELECT prox_maquina_sem_produto('INVAL', 1) FROM dual; -- Erro: -20802

-- 5. P_FUNC_2023144551
SELECT P_FUNC_2023144551(1) AS tempo_medio FROM dual;
-- Esperado: 0 minutos
SELECT P_FUNC_2023144551(999) FROM dual; -- Erro: -20814

-- 6. distancia_viagem
SELECT distancia_viagem(1) AS distancia FROM dual;
-- Esperado: Soma das distâncias (armazém ? máquina 1 ? máquina 2 ? armazém)
SELECT distancia_viagem(999) FROM dual; -- Erro: -20807

-- 7. quantidade_media_diaria
SELECT quantidade_media_diaria(1, 1) AS media FROM dual;
-- Esperado: 1 (2 vendas em 2 dias)
SELECT quantidade_media_diaria(999, 1) FROM dual; -- Erro: -20801

-- 8. P_FUNC_2023144606
SELECT P_FUNC_2023144606(TO_DATE('2025-05-29', 'YYYY-MM-DD'), TO_DATE('2025-05-31', 'YYYY-MM-DD')) AS media FROM dual;
-- Esperado: 1 (2 rupturas em 2 dias)

-- 9. quantidade_vendida
SELECT quantidade_vendida(1, 1, TO_DATE('2025-05-29', 'YYYY-MM-DD'), TO_DATE('2025-05-31', 'YYYY-MM-DD')) AS vendas FROM dual;
-- Esperado: 2
SELECT quantidade_vendida(1, 1, TO_DATE('2025-05-31', 'YYYY-MM-DD'), TO_DATE('2025-05-29', 'YYYY-MM-DD')) FROM dual; -- Erro: -20809

-- 10. data_ultimo_abastc
SELECT data_ultimo_abastc(1, 1) AS data FROM dual;
-- Esperado: SYSDATE - 2
SELECT data_ultimo_abastc(999, 1) FROM dual; -- Erro: -20801

-- 11. maquina_mais_proxima
SELECT maquina_mais_proxima(1, 38.7223, -9.1393) AS maquina FROM dual;
-- Esperado: 1 (Porto, com stock)
SELECT maquina_mais_proxima(999, 38.7223, -9.1393) FROM dual; -- Erro: -20802

-- 12. p_FUNC_2023144573
SELECT p_FUNC_2023144573(1, SYSDATE, SYSDATE + 10) AS lucro FROM dual; -- (as vezes buga entao fazer run individual)
SELECT p_FUNC_2023144573(999, SYSDATE, SYSDATE + 10) AS lucro FROM dual; -- Erro: -20801

-- Testes para Procedimentos

-- 1. cria_viagem_abast
UPDATE COMPARTIMENTOS SET QUANTIDADE_COMPARTIMENTO = 10 WHERE ID_COMPARTIMENTO = 1;
EXEC cria_viagem_abast(1, 300);
EXEC cria_viagem_abast(999, 300);
EXEC cria_viagem_abast(1, -1);


-- 2. Q_PROC_2023144551
EXEC Q_PROC_2023144551(1, 2, 1, 20);
-- Esperado: Transfere 50 unidades
EXEC Q_PROC_2023144551(1, 1, 1, 50); -- Erro: -20816
EXEC Q_PROC_2023144551(1, 2, 1, -1); -- Erro: -20817

-- 3. abastece_produto
EXEC abastece_produto(1, 1, 50);
-- Esperado: Reabastece compartimento 1
EXEC abastece_produto(999, 1, 50); -- Erro: -20806
EXEC abastece_produto(1, 1, -1); -- Erro: -20813

-- 4. encomenda_produtos
EXEC encomenda_produtos(1, TO_DATE('2025-05-25', 'YYYY-MM-DD'));
-- Esperado: Encomenda quantidade necessária
EXEC encomenda_produtos(999, TO_DATE('2025-05-25', 'YYYY-MM-DD')); -- Erro: -20806
EXEC encomenda_produtos(1, TO_DATE('2025-06-01', 'YYYY-MM-DD')); -- Erro: -20812

-- 5. Q_PROC_2023144606
EXEC Q_PROC_2023144606(1, 'AGUA500', 'CREDITO');
-- Esperado: Regista venda, reduz QUANTIDADE_COMPARTIMENTO

-- 6. Q_PROC_2023144573
EXEC Q_PROC_2023144573('BEBIDA', 10);
-- Esperado: Aumenta preço em 10% (1.5 ? 1.65)
EXEC Q_PROC_2023144573('INVAL', 10); -- Erro: -20814
EXEC Q_PROC_2023144573('BEBIDA', 1001); -- Erro: -20815

-- Testes para Triggers

-- 1. update_viagem
INSERT INTO REABASTECIMENTOS (ID_REABASTECIMENTO, ID_VISITA, ID_COMPARTIMENTO, ID_PRODUTO, QUANTIDADE_REABASTECIMENTO, DATA_HORA_REABASTECIMENTO)
VALUES (3, 1, 2, 1, 20, SYSDATE);
-- Esperado: Reduz QUANTIDADE_PV de 100 para 70
INSERT INTO REABASTECIMENTOS (ID_REABASTECIMENTO, ID_VISITA, ID_COMPARTIMENTO, ID_PRODUTO, QUANTIDADE_REABASTECIMENTO, DATA_HORA_REABASTECIMENTO)
VALUES (4, 999, 1, 1, 30, SYSDATE); -- Erro: -20807 (fazer drop R_TRIG_2023144573)

-- 2. R_TRIG_2023144551
UPDATE VIAGENS SET ID_VEICULO = 1 WHERE ID_VIAGEM = 1;

-- Esperado: Verifica autonomia
INSERT INTO VIAGENS (ID_VIAGEM, ID_ROTA, ID_VEICULO) VALUES (2, 1, 999); -- Erro: -20822

-- 3. abastece
INSERT INTO REABASTECIMENTOS (ID_REABASTECIMENTO, ID_VISITA, ID_COMPARTIMENTO, ID_PRODUTO, QUANTIDADE_REABASTECIMENTO, DATA_HORA_REABASTECIMENTO)
VALUES (5, 1, 1, 1, 30, SYSDATE); -- Erro: -20813 (excede capacidade)

-- 4. R_TRIG_2023144606
INSERT INTO ENCOMENDAS (ID_PRODUTO, ID_ARMAZEM, ID_ENCOMENDA, DATA_ENCOMENDA, QUANTIDADE_ENCOMENDAS)
VALUES (1, 1, SEQ_ENCOMENDAS.NEXTVAL, SYSDATE + 1, 50);
-- Esperado: Adiciona 50 ao QUANTIDADE_EM_STOCK

-- 5. update_stock
INSERT INTO VENDAS (ID_VENDA, ID_COMPARTIMENTO, ID_PRODUTO, DATA_HORA_VENDA, METODO_PAGAMENTO, VALOR_PAGO)
VALUES (8, 1, 1, SYSDATE, 'CREDITO', 1.65);
-- Esperado: Reduz QUANTIDADE_COMPARTIMENTO, define ESTADO_MAQUINA como 'SEM STOCK' se 0

-- 6. R_TRIG_2023144573
INSERT INTO REABASTECIMENTOS (ID_REABASTECIMENTO, ID_VISITA, ID_COMPARTIMENTO, ID_PRODUTO, QUANTIDADE_REABASTECIMENTO, DATA_HORA_REABASTECIMENTO)
VALUES (7, 1, 1, 1, 20, SYSDATE);
-- Esperado: Atualiza QUANTIDADE_PV, QUANTIDADE_COMPARTIMENTO, ESTADO_MAQUINA para 'OPERACIONAL'