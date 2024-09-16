CREATE OR REPLACE TRIGGER SANKHYA.TRG_AFR_UPD_TGWSEP
AFTER UPDATE OF SITUACAO ON SANKHYA.TGWSEP
FOR EACH ROW
DECLARE
    -- Constantes
    c_situacao_conferencia_validada CONSTANT CHAR(1) := '5';
    c_situacao_concluida            CONSTANT CHAR(1) := '6';
    c_usuario_notificacao_adicional CONSTANT INT := 68;

    -- Vari�veis locais
    v_mensagem_notificacao VARCHAR2(3000);
    v_resultado_faturamento BOOLEAN;
    v_msg_resposta_faturamento_automatico VARCHAR2(1000);
    
    -- Estrutura para armazenar informa��es da TGFCAB e separa��es
    TYPE r_dados_pedido IS RECORD (
        nunota              TGFCAB.NUNOTA%TYPE,
        codusu_vendedor     TGFCAB.CODUSU%TYPE,
        codusu_conferente   TGWCON.CODUSU%TYPE,
        total_separacoes    NUMBER(10),
        total_separacoes_concluidas_ou_validadas NUMBER(10),
        total_abertas       NUMBER(10),
        todas_concluidas    NUMBER(1)

    );
    v_dados_pedido r_dados_pedido;
    
    PRAGMA AUTONOMOUS_TRANSACTION;

    
    /******************************************************************************
   * CRIADO POR: YURI MESAK PEREIRA 17/05/2023
   * SOLICITANTE: LEONI
   * MOTIVO: TRIGGER QUE ENVIA MENSAGEM AO VENDEDOR PARA A CONFIRMA��O DA NOTA.
   
   -- REFEITA POR YURI MESAK 19/12/2023, DEVIDO � MUDAN�A NO PROCESSO DE SEPARA��O, QUE AGORA GERA DUAS FICHAS (WMS E VLM)
   
    *    REFATORADO POR DANILO FERNANDO EM 21/08/2024 --- USADO NO FATURAMENTO AUTOMATICO
	*   Situacao = 5 --> Conferencia validada
	*	Situacao = 6 --> Conclu�da
	
        Tomou banho de FIAP em 21/08/2024
				
   *********************************************************************************************************************/
    
BEGIN
    -- Executa a l�gica apenas se o novo valor de SITUACAO for 5 e o antigo valor n�o for 5 ou 6
    IF :NEW.situacao = c_situacao_conferencia_validada AND :OLD.situacao NOT IN (c_situacao_conferencia_validada, c_situacao_concluida) THEN

        -- Consulta �nica para obter informa��es do pedido e separa��es
        WITH todas_separacoes AS (
            SELECT 
                sep.NUSEPARACAO, 
                COALESCE(sep.NUNOTA, sxn.NUNOTA) AS NUNOTA,  -- Usa o NUNOTA de TGWSEP ou, se for nulo, obt�m de TGWSXN
                CASE 
                    WHEN sep.NUSEPARACAO = :NEW.NUSEPARACAO THEN :NEW.SITUACAO   --- garante que, para a separa��o atual sendo atualizada, usamos o novo valor da situa��o (:NEW.SITUACAO) em vez do valor armazenado no banco de dados.
                    ELSE sep.SITUACAO
                END AS SITUACAO, 
                sep.NUCONFERENCIA
            FROM TGWSEP sep
            LEFT JOIN TGWSXN sxn ON sep.NUSEPARACAO = sxn.NUSEPARACAO
            WHERE COALESCE(sep.NUNOTA, sxn.NUNOTA) = (
                SELECT COALESCE(NUNOTA, (SELECT NUNOTA FROM TGWSXN WHERE NUSEPARACAO = :NEW.NUSEPARACAO))
                FROM TGWSEP
                WHERE NUSEPARACAO = :NEW.NUSEPARACAO
            )
        )
        SELECT 
            ts.NUNOTA,
            cab.CODUSU AS CODUSU_VENDEDOR,
            MAX(con.CODUSU) AS CODUSU_CONFERENTE,
            COUNT(DISTINCT ts.NUSEPARACAO) AS TOTAL_SEPARACOES,
            SUM(CASE 
                WHEN ts.SITUACAO IN (c_situacao_conferencia_validada, c_situacao_concluida) 
                THEN 1 
                ELSE 0 
            END) AS TOTAL_SEPARACOES_CONCLUIDAS_OU_VALIDADAS,
            CASE 
                WHEN SUM(CASE WHEN ts.SITUACAO NOT IN (c_situacao_conferencia_validada, c_situacao_concluida) THEN 1 ELSE 0 END) = 0 
                THEN 1
                ELSE 0
            END AS TODAS_CONCLUIDAS,
             SUM(CASE 
                WHEN ts.SITUACAO  NOT IN (c_situacao_conferencia_validada, c_situacao_concluida) 
                THEN 1 
                ELSE 0 
            END) AS TOTAL_SEPARACOES_ABERTAS
            
        INTO v_dados_pedido.nunota, v_dados_pedido.codusu_vendedor, v_dados_pedido.codusu_conferente,
             v_dados_pedido.total_separacoes, v_dados_pedido.total_separacoes_concluidas_ou_validadas,
             v_dados_pedido.todas_concluidas,v_dados_pedido.total_abertas  
        
        FROM todas_separacoes ts
        JOIN TGFCAB cab ON ts.NUNOTA = cab.NUNOTA
        LEFT JOIN TGWCON con ON ts.NUCONFERENCIA = con.NUCONFERENCIA
        GROUP BY ts.NUNOTA, cab.CODUSU;

       
        
        
        --SEND_NOTIFICATION(c_usuario_notificacao_adicional, NULL, 'Total de Separacoes' , 'TSC: '  ||  v_dados_pedido.TOTAL_SEPARACOES_CONCLUIDAS_OU_VALIDADAS || ' | TS: '  || v_dados_pedido.total_separacoes || ' | TA: ' || v_dados_pedido.total_abertas , 1);
        --commit;
        
        -- Verifica se todas as separa��oes do pedido j� est�o concluidas ou com conferencia validada
        IF v_dados_pedido.TOTAL_SEPARACOES_CONCLUIDAS_OU_VALIDADAS = v_dados_pedido.total_separacoes THEN
        
        
            PKG_FATURAMENTOAUTOMATICO.FATURAPELOESTOQUE(v_dados_pedido.nunota, v_resultado_faturamento, v_msg_resposta_faturamento_automatico); -- Se todas estiverm concluidas, fatura

            v_mensagem_notificacao := 
            
                CASE 
                    WHEN v_resultado_faturamento THEN -- Se retornou true no faturament outomatico
                    
                       v_msg_resposta_faturamento_automatico
                       -- 'O PEDIDO N� UNICO: ' || v_dados_pedido.nunota || ' FOI SEPARADO, CONFERIDO E FATURADO COM SUCESSO!'
                    ELSE -- ocorreu algum erro no faturamento automatico
                       'A CONFER�NCIA DO N� �NICO: ' || v_dados_pedido.nunota || ' FOI CONCLU�DA, N�O FOI POSSIVEL FATURAR AUTOMATICAMENTE. SIGA COM O FATURAMENTO MANUAL. <br>' || v_msg_resposta_faturamento_automatico 
                END;
                
                
                
        ELSE -- Finalizar uma separa��o, por�m, ainda existem separa��es pendentes
            -- Notifica que uma separa��o foi conclu�da, mas outras ainda est�o pendentes
            
            
            PKG_FATURAMENTOAUTOMATICO.FATURAPELOESTOQUE(v_dados_pedido.nunota, v_resultado_faturamento, v_msg_resposta_faturamento_automatico); -- Se todas estiverm concluidas, fatura
      
            
            v_mensagem_notificacao := 
            
                CASE 
                    WHEN v_resultado_faturamento THEN -- Se retornou true no faturament outomatico
                        
                        v_msg_resposta_faturamento_automatico
                        --'O PEDIDO N� UNICO: ' || v_dados_pedido.nunota || ' FOI SEPARADO, CONFERIDO E FATURADO COM SUCESSO!'
                    ELSE -- ocorreu algum erro no faturamento automatico
                        'A CONFER�NCIA DO N� �NICO: ' || v_dados_pedido.nunota || ' FOI CONCLU�DA. POR�M, EXISTEM SEPARA��ES PENDENTES. PENDENTES AINDA: ' || v_dados_pedido.total_abertas || '<br><br> Esteja Atento tamb�m: <br>' || v_msg_resposta_faturamento_automatico
                END;

            


        END IF;
        
        -- Envia notifica��es se houver mensagem
        IF v_mensagem_notificacao IS NOT NULL THEN
        
            IF v_dados_pedido.codusu_vendedor > -1 THEN
                -- Notifica o vendedor
                SEND_NOTIFICATION(v_dados_pedido.codusu_vendedor, NULL, 'Faturamento Autom�tico: ' ||  v_dados_pedido.nunota, v_mensagem_notificacao, -1);
                commit;
            END IF;

            IF v_dados_pedido.codusu_conferente > -1 THEN
                -- Notifica o conferente
                SEND_NOTIFICATION(v_dados_pedido.codusu_conferente, NULL, 'Faturamento Autom�tico '  ||  v_dados_pedido.nunota, v_mensagem_notificacao, -1);
                commit;
            END IF;


            -- Notifica o  Danilo Fernando
            SEND_NOTIFICATION(c_usuario_notificacao_adicional, NULL, 'Faturamento Autom�tico '  ||  v_dados_pedido.nunota, v_mensagem_notificacao, 1);
            commit;

        END IF;
        
       
        

    END IF;

EXCEPTION
    WHEN OTHERS THEN
        -- Log de erro para identifica��o de problemas
        -- INSERT INTO log_erros (data, erro, contexto) VALUES (SYSDATE, SQLERRM, 'TRG_AFR_UPD_TGWSEP');
        -- Considerar a adi��o de um tratamento de erro mais robusto
        RAISE; -- Re-lan�a a exce��o ap�s o log
END;
/