CREATE OR REPLACE PACKAGE BODY SANKHYA.PKG_FATURAMENTOAUTOMATICO AS
    
    /*P_CODEMP_DA_CAB         TGFCAB.CODEMP%TYPE;
    P_CODTIPVENDA_DA_CAB    TGFCAB.CODTIPVENDA%TYPE;
    P_CODTIPOPER_DA_CAB     TGFCAB.CODTIPOPER%TYPE;*/
    
    /**************************************************************************
    * Carrega as configura��es mais recentes para um CODEMP espec�fico
    ***************************************************************************/
    PROCEDURE CARREGA_CONFIG_FATAUT(P_CODEMP IN NUMBER) IS
    BEGIN
        SELECT NUFAT, CODEMP, ATIVO, SERIE, SITUACAOWMS, DTHRULTFATURAMENTO, 
               RELATORIOERRO, RELATORIOFATURAMENTO, GRUPOEMAIL
        
        INTO   G_NUFAT, G_CODEMP, G_ATIVO, G_SERIE, G_SITUACAOWMS, 
               G_DTHRULTFATURAMENTO, G_RELATORIOERRO, G_RELATORIOFATURAMENTO, G_GRUPOEMAIL
        
        FROM   SANKHYA.AD_FATAUTDCCO
        
        WHERE  CODEMP = P_CODEMP
        
        ORDER BY DTHRULTFATURAMENTO DESC
        FETCH FIRST 1 ROWS ONLY;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Nenhuma configura��o encontrada para CODEMP: ' || P_CODEMP);
        WHEN OTHERS THEN
            RAISE;
    END CARREGA_CONFIG_FATAUT;
    
    /* Pega os dados do NUNOTA na CAB */
    PROCEDURE GET_DADOS_NUNOTA(
        P_NUNOTA    IN TGFCAB.NUNOTA%TYPE
    ) IS
    
    BEGIN
    
        SELECT CODEMP, CODTIPOPER, CODTIPVENDA, CODPARC, VLRNOTA, CODUSU, CODUSUINC
        INTO P_CODEMP_DA_CAB, P_CODTIPOPER_DA_CAB, P_CODTIPVENDA_DA_CAB, 
             P_CODPARC_DA_CAB, P_VALORNOTA_DA_CAB, P_CODUSU_DA_CAB, P_CODUSUINC_DA_CAB
        FROM TGFCAB
        WHERE NUNOTA = P_NUNOTA;
    
    
    END GET_DADOS_NUNOTA;
    
    
    
    /* Retorna o c�digo da empresa na cab */
    FUNCTION GET_CODEMP_NUNOTA(
        P_NUNOTA    IN NUMBER
    ) RETURN NUMBER IS
    
    I_CODEMP TGFCAB.CODEMP%TYPE;

    
    BEGIN
    
         -- Verifica se h� exatamente um CODEMP correspondente ao NUNOTA
        SELECT CODEMP
        INTO I_CODEMP
        FROM TGFCAB
        WHERE NUNOTA = P_NUNOTA;
        
        RETURN I_CODEMP;
    
    END GET_CODEMP_NUNOTA;
    
    /*  Retonar o c�digo da TOP na CAB */
    FUNCTION GET_TOP_NUNOTA(
        P_NUNOTA    IN NUMBER
    ) RETURN NUMBER IS
    
    I_CODTIPOPER TGFCAB.CODTIPOPER %TYPE;

    
    BEGIN
    
         -- Verifica se h� exatamente um CODEMP correspondente ao NUNOTA
        SELECT CODTIPOPER
        INTO I_CODTIPOPER
        FROM TGFCAB
        WHERE NUNOTA = P_NUNOTA;
        
        RETURN I_CODTIPOPER;
    
    END GET_TOP_NUNOTA;
    
    /* RETORNA O TIPO DE NEGOCIACAO NA CAB */
    FUNCTION GET_TIPONEGOCIACAO_NUNOTA(
        P_NUNOTA IN NUMBER
    ) RETURN NUMBER IS
    
        I_TIPONEGOCIACAO_NA_CAB TGFCAB.CODTIPVENDA%TYPE;

    BEGIN
    
        SELECT CODTIPVENDA
        INTO I_TIPONEGOCIACAO_NA_CAB
        FROM TGFCAB
        WHERE NUNOTA = P_NUNOTA;
        
        RETURN I_TIPONEGOCIACAO_NA_CAB;
    
    END GET_TIPONEGOCIACAO_NUNOTA;

    /************************************************************************** 
    * Insere registro no log de faturamento - Estrutura padr�o
    ***************************************************************************/
    FUNCTION INSERE_LOGFATAUTO(
        p_nunota   IN NUMBER,
        p_numnota  IN NUMBER,
        p_log      IN CLOB,
        p_dhalter  IN DATE
    ) RETURN BOOLEAN IS
    BEGIN
    
        INSERT INTO SANKHYA.TGWLOGFATAUTO (NUNOTA, NUMNOTA, LOG, DHALTER)
        VALUES (p_nunota, p_numnota, p_log, p_dhalter);
        
        COMMIT;
        
        RETURN TRUE;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RETURN FALSE;
    END INSERE_LOGFATAUTO;
    
    /**************************************************************************
    * Atualiza os detalhes de faturamento na tabela AD_FATAUTDCCO
    ***************************************************************************/
    PROCEDURE ATUALIZA_DHFATAUTDCCO (
        P_NUFAT                IN NUMBER,
        P_CODEMP               IN NUMBER,
        P_SITUACAOWMS          IN NUMBER,
        P_DTHRULTFATURAMENTO   IN FLOAT
    ) IS
    BEGIN
    
        UPDATE SANKHYA.AD_FATAUTDCCO
        SET DTHRULTFATURAMENTO = P_DTHRULTFATURAMENTO
        WHERE NUFAT = P_NUFAT 
        AND CODEMP = P_CODEMP
        AND SITUACAOWMS = P_SITUACAOWMS;

        IF SQL%ROWCOUNT > 0 THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END ATUALIZA_DHFATAUTDCCO;

    /**************************************************************************
    * Consulta se o tipo de negocia��o est� configurado na tabela AD_TIPNEGOFATDCCO
    ***************************************************************************/
    PROCEDURE CONSULTA_TIPNEGOFATDCCO (
        P_CODTIPNEG      IN NUMBER,
        P_CODEMP         IN NUMBER,
        P_RESULTADO      OUT BOOLEAN
    ) IS
        V_COUNT NUMBER;
    BEGIN
        -- Verifica se o tipo de negocia��o da NU est� configurado para empresa    
        SELECT COUNT(*)
        INTO V_COUNT
        FROM AD_TIPNEGOFATDCCO
        WHERE NUFAT IN (
            SELECT DISTINCT NUFAT 
            FROM AD_FATAUTDCCO 
            WHERE CODEMP = P_CODEMP 
            AND ATIVO = 'SIM'
        )
        AND CODTIPNEG = P_CODTIPNEG;

        P_RESULTADO := V_COUNT > 0;

    EXCEPTION
        WHEN OTHERS THEN
            P_RESULTADO := FALSE;
            RAISE;
    END CONSULTA_TIPNEGOFATDCCO;
    
    
    /**************************************************************************
    * Consulta se o tipo de negocia��o est� configurado na tabela AD_TIPNEGOFATDCCO
    ***************************************************************************/
    PROCEDURE CONSULTA_TIPNEGOFATAVISTADCCO (
        P_CODTIPNEG      IN NUMBER,
        P_CODEMP         IN NUMBER,
        P_RESULTADO      OUT BOOLEAN
    ) IS
        V_COUNT NUMBER;
        
    BEGIN
        -- Verifica se o tipo de negocia��o da NU est� configurado para empresa    
        SELECT COUNT(*)
        INTO V_COUNT
        FROM AD_TIPNEGAVISTA
        WHERE NUFAT IN (
            SELECT DISTINCT NUFAT 
            FROM AD_FATAUTDCCO 
            WHERE CODEMP = P_CODEMP 
            AND ATIVO = 'SIM'
        )
        AND TIPONEGAVISTA = P_CODTIPNEG;

        P_RESULTADO := V_COUNT > 0;

    EXCEPTION
        WHEN OTHERS THEN
            P_RESULTADO := FALSE;
            RAISE;
    END CONSULTA_TIPNEGOFATAVISTADCCO;
    
    
    /**************************************************************************
    * Consulta se o TOP est� configurado na tabela AD_TOPPEDFATAUT
    ***************************************************************************/
    PROCEDURE CONSULTA_TOPPEDFATAUT (
        P_TOP       IN NUMBER,
        P_CODEMP         IN NUMBER,
        P_RESULTADO OUT BOOLEAN
    ) IS
        V_COUNT NUMBER;
    BEGIN
    
        SELECT COUNT(*)
        INTO V_COUNT
        FROM SANKHYA.AD_TOPPEDFATAUT
        WHERE NUFAT IN (
            SELECT DISTINCT NUFAT 
            FROM AD_FATAUTDCCO 
            WHERE CODEMP = P_CODEMP 
            AND ATIVO = 'SIM'
        ) 
        AND TOP = P_TOP;

        P_RESULTADO := V_COUNT > 0;

    EXCEPTION
        WHEN OTHERS THEN
            P_RESULTADO := FALSE;
            RAISE;
    END CONSULTA_TOPPEDFATAUT;
    
    
    /**************************************************************************
    *  Pega os dados da NU que ser� faturada.
    *
    ***************************************************************************/
    
    
   
    /* Procedure que realiza o faturamento do pedido pelo estoque  
       Usada na trigger que monitora a tgwsep 
    */
    PROCEDURE FATURAPELOESTOQUE(
    P_NUNOTA    IN NUMBER,
    P_RESULTADO OUT BOOLEAN
) IS
    EMPRESA_UTILIZA_WMS              VARCHAR2(1) := 'N';  -- Substituindo CHAR por VARCHAR2
    TOP_HABILITADA_FATURAMENTO        BOOLEAN;
    VENDA_A_PRAZO                     BOOLEAN;
    VENDA_A_VISTA                     BOOLEAN;
    CLIENTE_TEM_LIMITE                BOOLEAN;
    P_STATUS                          NUMBER;
    LIBERADO_VENDA_A_VISTA            BOOLEAN;
    P_RETURN                          VARCHAR2(255);

BEGIN
    -- Busca o c�digo da Empresa, Tipo de Negocia��o e TOP na CAB
    GET_DADOS_NUNOTA(P_NUNOTA);

    /*********************************************************************************
     Vamos seguir os seguintes passos:
     
     1 - Verifica se a empresa utiliza WMS
     2 - Verifica se existe alguma configura��o de faturamento autom�tico ativo para esta empresa
     3 - Verifica se a TOP utilizada no pedido est� habilitada para ser faturada automaticamente
     4 - Verifica se o tipo de negocia��o no pedido est� habilitado para ser faturado
     4.1 - Verifica se o cliente tem limite dispon�vel para faturamento a prazo
     5 - Verifica se o tipo de negocia��o � � vista e se h� libera��o aprovada para o cliente
     6 - Chama o faturamento autom�tico 
     7 - Atualiza a data do �ltimo faturamento autom�tico
    *********************************************************************************/

    -- Verifica se a empresa utiliza WMS [1]
    STP_EMP_UTILIZAWMS_DCCO(P_CODEMP_DA_CAB, EMPRESA_UTILIZA_WMS);

    IF EMPRESA_UTILIZA_WMS = 'N' THEN
        SEND_NOTIFICATION(68, NULL, 'Empresa n�o utiliza WMS', 'Empresa: ' || P_CODEMP_DA_CAB, 1);
        P_RESULTADO := FALSE;
        RETURN;
    END IF;

    -- Carrega as configura��es do faturamento autom�tico
    CARREGA_CONFIG_FATAUT(P_CODEMP_DA_CAB);

    -- Verifica se a empresa est� habilitada para faturamento autom�tico [2]
    IF P_CODEMP_DA_CAB <> G_CODEMP OR G_ATIVO <> 'SIM' THEN
        SEND_NOTIFICATION(68, NULL, 'Empresa n�o habilitada para faturamento autom�tico', 'Empresa: ' || P_CODEMP_DA_CAB, 1);
        P_RESULTADO := FALSE;
        RETURN;
    END IF;

    -- Verifica se a TOP utilizada est� habilitada para faturamento autom�tico [3]
    CONSULTA_TOPPEDFATAUT(P_CODTIPOPER_DA_CAB, P_CODEMP_DA_CAB, TOP_HABILITADA_FATURAMENTO);
    
    IF NOT TOP_HABILITADA_FATURAMENTO THEN
        SEND_NOTIFICATION(68, NULL, 'TOP n�o habilitada para faturamento', 'TOP: ' || P_CODTIPOPER_DA_CAB, 1);
        P_RESULTADO := FALSE;
        RETURN;
    END IF;

    -- Verifica o tipo de negocia��o [4]
    CONSULTA_TIPNEGOFATDCCO(P_CODTIPVENDA_DA_CAB, P_CODEMP_DA_CAB, VENDA_A_PRAZO);

    IF VENDA_A_PRAZO = TRUE THEN
        -- Verifica se o cliente tem limite de cr�dito [4.1]
        CLIENTE_TEM_LIMITE_CREDITO(P_CODPARC_DA_CAB, P_VALORNOTA_DA_CAB, CLIENTE_TEM_LIMITE);

        IF CLIENTE_TEM_LIMITE = FALSE THEN
            SEND_NOTIFICATION(P_CODUSU_DA_CAB, NULL, 'Faturamento a Prazo - Limite Insuficiente', 
            'O cliente do pedido <b>' || P_NUNOTA || '</b> n�o tem limite para ser faturado automaticamente.', -1);
            P_RESULTADO := FALSE;
            RETURN;
        END IF;

    ELSE
    
        -- Verifica se a venda � � vista [5]
        CONSULTA_TIPNEGOFATAVISTADCCO(P_CODTIPVENDA_DA_CAB, P_CODEMP_DA_CAB, VENDA_A_VISTA);

        IF VENDA_A_VISTA = TRUE THEN
        
            -- Verifica se h� libera��o para venda � vista
            TEM_LIBERACAO(P_NUNOTA, LIBERADO_VENDA_A_VISTA);
            
            IF LIBERADO_VENDA_A_VISTA = FALSE THEN
            
                -- Notifica financeiro e vendedor que existe liberacoes pendentes[5.1]
                SEND_NOTIFICATION(NULL, 9, 'Libera��o Pendente - Venda � Vista', 
                'Pedido com pagamento � vista|pix|cartao|debito|deposito aguardando libera��o. NU: ' || P_NUNOTA, -1);
                
                SEND_NOTIFICATION(NULL, 10, 'Libera��o Pendente - Venda � Vista', 
                'Pedido com pagamento � vista|pix|cartao|debito|deposito aguardando libera��o. NU: ' || P_NUNOTA, 3);
                
                SEND_NOTIFICATION(NULL, 12, 'Libera��o Pendente - Venda � Vista', 
                'Pedido com pagamento � vista|pix|cartao|debito|deposito aguardando libera��o. NU: ' || P_NUNOTA, 1);
                
                SEND_NOTIFICATION(NULL, 26, 'Libera��o Pendente - Venda � Vista', 
                'Pedido com pagamento � vista|pix|cartao|debito|deposito aguardando libera��o. NU: ' || P_NUNOTA, 1);
                
                SEND_NOTIFICATION(P_CODUSU_DA_CAB, NULL, 'Libera��o Pendente - Venda � Vista', 
                'Pedido com pagamento � vista|pix|cartao|debito|deposito aguardando libera��o. NU: ' || P_NUNOTA, -1); -- Vendedor
                
                
                P_RESULTADO := FALSE;
                RETURN;
                
            END IF;

        ELSE
        
            -- Tipo de negocia��o n�o configurado para faturamento autom�tico
            SEND_NOTIFICATION(P_CODUSU_DA_CAB, NULL, 'Faturamento Autom�tico N�o Permitido',
            'Tipo de negocia��o selecionado para o pedido ' || P_NUNOTA || ' n�o permite faturamento autom�tico.', -1);
            
            
            
            P_RESULTADO := FALSE;
            RETURN;
            
        END IF;
    END IF;

    -- Chama o faturamento autom�tico [6]
    P_STATUS := SANKHYA.PKG_API_DCCO.FC_FATURAR_ESTOQUE(P_NUNOTA, 1830, P_RETURN);

    IF P_STATUS <> 1 THEN
        SEND_NOTIFICATION(68, NULL, 'Erro ao Faturar', 'Erro: ' || P_RETURN || ' - Pedido: ' || P_NUNOTA, 1);
        P_RESULTADO := FALSE;
        RETURN;
    END IF;

    -- Atualiza o resultado e o status do faturamento [7]
    P_RESULTADO := TRUE;

EXCEPTION
    WHEN OTHERS THEN
        -- Captura o erro e realiza o log apropriado
        SEND_NOTIFICATION(68, NULL, 'Erro inesperado', 'Erro ao processar faturamento do pedido ' || P_NUNOTA || '. Detalhes: ' || SQLERRM, 1);
        P_RESULTADO := FALSE;
END FATURAPELOESTOQUE;


    PROCEDURE CLIENTE_TEM_LIMITE_CREDITO(
        P_CODPAR        IN NUMBER,
        P_VLRCOMPRA     IN NUMBER,
        P_STATUS        OUT BOOLEAN
    ) IS
        V_LIMCRED           NUMBER;
        V_TOTAL_EM_ABERTO   NUMBER;
        V_LIMITE_DISPONIVEL NUMBER;
        
    BEGIN
    
        -- Busca o limite de cr�dito e o total em aberto do cliente
        SELECT 
            PARC.LIMCRED,
            NVL(SUM(FIN.VLRDESDOB), 0) AS TOTAL_EM_ABERTO
        INTO
            V_LIMCRED,
            V_TOTAL_EM_ABERTO
        FROM 
            TGFPAR PARC
        LEFT JOIN 
            TGFFIN FIN ON PARC.CODPARC = FIN.CODPARC 
                       AND FIN.DHBAIXA IS NULL 
                       AND FIN.RECDESP = 1 
                       AND FIN.PROVISAO = 'N'
        WHERE 
            PARC.CODPARC = P_CODPAR
        GROUP BY 
            PARC.LIMCRED;
        
        -- Calcula o limite dispon�vel
        V_LIMITE_DISPONIVEL := V_LIMCRED - V_TOTAL_EM_ABERTO;

        -- Verifica se o limite dispon�vel � suficiente para a nova compra
        IF V_LIMITE_DISPONIVEL >= P_VLRCOMPRA THEN
            P_STATUS := TRUE;
        ELSE
            P_STATUS := FALSE;
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            P_STATUS := FALSE;
        WHEN OTHERS THEN
            P_STATUS := FALSE;
    END;
    
    /* Libera��o de Limites - Venda a Vista */
    PROCEDURE LANCAR_LIBERACAO(
        P_NUCHAVE       IN NUMBER,
        P_VLRATUAL      IN FLOAT,
        P_CODUSUSOLICIT IN NUMBER
    ) IS
    
        V_COUNT NUMBER;
    
    BEGIN
        
        /*
            Verifica sen�o existe solicita��o de libera��o. Sen�o exitir, lan�a a libera��o.
            Evento -- 1001 [Venda a Vista WMS]
        */
        
        
    SELECT COUNT(*)
        INTO V_COUNT
        FROM SANKHYA.TSILIB
        WHERE NUCHAVE = P_NUCHAVE
          AND TABELA  = 'TGFCAB'
          AND EVENTO  = 1001;

        -- Se n�o existir, realiza o INSERT
        IF V_COUNT = 0 THEN
        
            INSERT INTO SANKHYA.TSILIB (
                NUCHAVE, 
                TABELA, 
                EVENTO, 
                CODUSUSOLICIT, 
                DHSOLICIT, 
                VLRLIMITE, 
                VLRATUAL, 
                VLRLIBERADO, 
                CODUSULIB, 
                DHLIB, 
                OBSERVACAO, 
                PERCLIMITE, 
                VLRTOTAL, 
                OBSLIB, 
                PERCANTERIOR, 
                VLRANTERIOR, 
                NULBO, 
                SEQUENCIA, 
                CODMETA, 
                REPROVADO, 
                SUPLEMENTO, 
                ANTECIPACAO, 
                TRANSF, 
                VLRDESDOB, 
                CODCENCUS, 
                CODTIPOPER, 
                ORDEM, 
                SEQCASCATA, 
                NUCLL, 
                NURNG, 
                OBSCOMPL, 
                DTVALDESC, 
                CODNAT, 
                CODPROJ, 
                CODSITE, 
                CODPARC, 
                CORDESTAQUE
                
            ) VALUES (
                P_NUCHAVE,            -- NUCHAVE
                'TGFCAB',             -- TABELA
                1001,                 -- EVENTO
                P_CODUSUSOLICIT,      -- CODUSUSOLICIT
                SYSDATE,              -- DHSOLICIT
                0,                    -- VLRLIMITE (valor a ser definido)
                P_VLRATUAL,           -- VLRATUAL
                0,                    -- VLRLIBERADO (valor padr�o)
                209,                    -- CODUSULIB (valor padr�o)
                NULL,                 -- DHLIB (valor a ser definido)
                'Aguarde o financeiro confirmar o recebimento do pagamento. Solicita��o Automatica.', -- OBSERVACAO
                0,                    -- PERCLIMITE (valor padr�o)
                NULL,                 -- VLRTOTAL (valor a ser definido)
                NULL,                 -- OBSLIB (valor a ser definido)
                NULL,                 -- PERCANTERIOR (valor a ser definido)
                NULL,                 -- VLRANTERIOR (valor a ser definido)
                NULL,                 -- NULBO (valor a ser definido)
                0,                    -- SEQUENCIA (valor padr�o)
                NULL,                 -- CODMETA (valor a ser definido)
                'N',                  -- REPROVADO (valor padr�o)
                'N',                  -- SUPLEMENTO (valor padr�o)
                'N',                  -- ANTECIPACAO (valor padr�o)
                'N',                  -- TRANSF (valor padr�o)
                NULL,                 -- VLRDESDOB (valor a ser definido)
                NULL,                 -- CODCENCUS (valor a ser definido)
                NULL,                 -- CODTIPOPER (valor a ser definido)
                NULL,                 -- ORDEM (valor a ser definido)
                0,                    -- SEQCASCATA (valor padr�o)
                0,                    -- NUCLL (valor padr�o)
                6,                    -- NURNG (valor a ser definido)
                NULL,                 -- OBSCOMPL (valor a ser definido)
                NULL,                 -- DTVALDESC (valor a ser definido)
                NULL,                 -- CODNAT (valor a ser definido)
                NULL,                 -- CODPROJ (valor a ser definido)
                NULL,                 -- CODSITE (valor a ser definido)
                NULL,                 -- CODPARC (valor a ser definido)
                NULL                  -- CORDESTAQUE (valor a ser definido)
            );
            
            COMMIT;
            
        END IF;
        
    END LANCAR_LIBERACAO;
    
    /* VERIFICA SE EXISTE LIBERA��O PARA O EVENTO 1001 NESSA NU */
     PROCEDURE TEM_LIBERACAO(
        P_NUCHAVE IN NUMBER,
        P_STATUS OUT BOOLEAN
    ) IS
        V_COUNT NUMBER;
    BEGIN
        -- Verifica se existe uma libera��o para a NUCHAVE e Evento 1001
        -- com as condi��es adicionais nos campos DHLIB, VLRATUAL, VLRLIBERADO e REPROVADO
        SELECT COUNT(*)
        INTO V_COUNT
        FROM SANKHYA.TSILIB
        WHERE NUCHAVE = P_NUCHAVE
            AND TABELA = 'TGFCAB'
            AND EVENTO = 1001
            AND DHLIB IS NOT NULL -- DHLIB n�o pode ser nulo
            AND VLRATUAL = VLRLIBERADO -- VLRATUAL e VLRLIBERADO devem ser iguais
            AND REPROVADO = 'N'; -- REPROVADO deve ser 'N'

        -- Define o status de sa�da com base na consulta
        IF V_COUNT > 0 THEN
            P_STATUS := TRUE; -- Libera��o encontrada com as condi��es atendidas
        ELSE
            P_STATUS := FALSE; -- Nenhuma libera��o encontrada ou condi��es n�o atendidas
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            P_STATUS := FALSE; -- Trata o caso de nenhuma linha ser encontrada
        WHEN OTHERS THEN
            -- Trata outros erros inesperados
            P_STATUS := FALSE; 
            DBMS_OUTPUT.PUT_LINE('Erro na procedure TEM_LIBERACAO: ' || SQLERRM);
    END TEM_LIBERACAO;   
    
    
END PKG_FATURAMENTOAUTOMATICO;
/
