CREATE OR REPLACE PROCEDURE SANKHYA.STP_DESIGNA_INVENTARIANTES 
(
    p_NUIVT IN NUMBER,
    p_MENSAGEM OUT VARCHAR2
) IS
    v_codusu        VARCHAR2(20);
    v_nutarefa      NUMBER;
    v_mensagem_ins  VARCHAR2(1000);
    v_count_designacoes NUMBER;
    v_erro BOOLEAN := FALSE;
    v_count NUMBER;
    v_situacao VARCHAR2(50);
BEGIN

    -- Verifica se o invent�rio existe e est� aberto
    BEGIN
        SELECT COUNT(*),  
            MAX(CASE WHEN DTFINAL IS NULL THEN 'Aberto' ELSE 'Fechado' END) AS situacao
        INTO v_count, v_situacao
        FROM TGWIVT ivt
        WHERE NUIVT = p_NUIVT;
        
        IF v_count = 0 THEN
            p_MENSAGEM := 'Erro: Invent�rio ' || p_NUIVT || ' n�o encontrado.';
            RETURN;
        END IF;
        
        IF v_situacao != 'Aberto' THEN
            p_MENSAGEM := 'Erro: Invent�rio ' || p_NUIVT || ' n�o est� aberto. Situa��o atual: ' || v_situacao;
            RETURN;
        END IF;
    END;

    p_MENSAGEM := 'Processo iniciado';
    
    -- Cursor para pegar todas as tarefas que n�o tem inventariante designado
    FOR tarefa IN (
        SELECT DISTINCT t.NUTAREFA, t.NUIVT
        FROM TGWTAR t
        WHERE 1 = 1 
        AND t.NUIVT = p_NUIVT
        AND NOT EXISTS (
            SELECT 1 
            FROM TGWUXT u 
            WHERE u.NUTAREFA = t.NUTAREFA
        )
    ) LOOP
        BEGIN  -- In�cio do bloco de tratamento para cada tarefa
            -- Para cada tarefa, vamos encontrar o pr�ximo inventariante eleg�vel
            SELECT inv.CODUSU 
            INTO v_codusu
            FROM (
                SELECT i.CODUSU,
                       NVL((
                           SELECT COUNT(1)
                           FROM TGWUXT x
                           WHERE x.CODUSUEXEC = i.CODUSU
                             AND x.NUTAREFA IN (
                                 SELECT t2.NUTAREFA 
                                 FROM TGWTAR t2 
                                 WHERE t2.NUIVT = tarefa.NUIVT
                             )
                       ), 0) as num_designacoes,
                       ROW_NUMBER() OVER (
                           ORDER BY 
                               NVL((
                                   SELECT COUNT(1)
                                   FROM TGWUXT x
                                   WHERE x.CODUSUEXEC = i.CODUSU
                                     AND x.NUTAREFA IN (
                                         SELECT t2.NUTAREFA 
                                         FROM TGWTAR t2 
                                         WHERE t2.NUIVT = tarefa.NUIVT
                                     )
                               ), 0),
                               i.CODUSU
                       ) as ordem_rotativa
                FROM AD_ADINVENTARIANTESDCCO i
                WHERE i.ATIVO = 'S'
                AND NOT EXISTS (
                    SELECT 1
                    FROM TGWITT itt_anterior
                    JOIN TGWTAR tar_anterior ON tar_anterior.NUTAREFA = itt_anterior.NUTAREFA
                    WHERE tar_anterior.NUIVT = tarefa.NUIVT
                    AND itt_anterior.SITUACAO = 'F'
                    AND itt_anterior.CODUSUEXEC = i.CODUSU
                    AND EXISTS (
                        SELECT 1
                        FROM TGWITT itt_atual
                        WHERE itt_atual.NUTAREFA = tarefa.NUTAREFA
                        AND itt_atual.CODPROD = itt_anterior.CODPROD
                        AND itt_atual.CODENDORIGEM = itt_anterior.CODENDORIGEM
                    )
                )
            ) inv
            WHERE ordem_rotativa = 1;

            -- Designa o inventariante para a tarefa
            INS_TGWUXT_IVT_DCCO(
                v_codusu,           -- P_CODUSUEXE
                tarefa.NUTAREFA,    -- p_NUTAREFA
                'A',                -- Status Ativo
                v_codusu,           -- p_CODUSU
                SYSDATE,            -- Data atual
                'I',                -- Inser��o
                tarefa.NUTAREFA,    -- p_NUTAREFA
                v_mensagem_ins      -- p_MENSAGEM
            );

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_erro := TRUE;
                p_MENSAGEM := p_MENSAGEM || CHR(10) || 
                             'N�o foi poss�vel encontrar inventariante eleg�vel para a tarefa: ' || 
                             tarefa.NUTAREFA;
                
            WHEN OTHERS THEN
                v_erro := TRUE;
                p_MENSAGEM := p_MENSAGEM || CHR(10) || 
                             'Erro ao processar tarefa ' || tarefa.NUTAREFA || ': ' || 
                             SQLERRM;
        END;  -- Fim do bloco de tratamento para cada tarefa
    END LOOP;
    
    -- Se chegou at� aqui, verifica se houve algum erro no processo
    IF NOT v_erro THEN
        p_MENSAGEM := 'Todas as tarefas foram designadas com sucesso.';
    END IF;

EXCEPTION
    -- Tratamento de erros da procedure como um todo
    WHEN OTHERS THEN
        p_MENSAGEM := 'Erro cr�tico no processo: ' || SQLERRM;
END STP_DESIGNA_INVENTARIANTES;
/

