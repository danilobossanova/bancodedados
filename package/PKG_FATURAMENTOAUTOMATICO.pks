/*******************************************************************************
* @author: Danilo Fernando <danilo.bossanova@hotmail.com>
* @since: 20/08/2024 11:13
* @description: Package com funcionalidades ligadas ao faturamento automatico
********************************************************************************/
CREATE OR REPLACE PACKAGE SANKHYA.PKG_FATURAMENTOAUTOMATICO AS

    /* Variáveis globais para armazenar as configurações do Faturamento*/
    G_NUFAT                 NUMBER(10);
    G_CODEMP                NUMBER(10);
    G_ATIVO                 VARCHAR2(10 BYTE);
    G_SERIE                 NUMBER(10);
    G_SITUACAOWMS           NUMBER(10);
    G_DTHRULTFATURAMENTO    FLOAT(126);
    G_RELATORIOERRO         VARCHAR2(10 BYTE);
    G_RELATORIOFATURAMENTO  VARCHAR2(10 BYTE);
    G_GRUPOEMAIL            VARCHAR2(100 BYTE);
    
    /* Variaveis globais com dados da NUNOTA da CAB */
    P_CODEMP_DA_CAB         TGFCAB.CODEMP%TYPE;
    P_CODTIPVENDA_DA_CAB    TGFCAB.CODTIPVENDA%TYPE;
    P_CODTIPOPER_DA_CAB     TGFCAB.CODTIPOPER%TYPE;

    /* Carrega as configurações mais recentes para um CODEMP específico */
    PROCEDURE CARREGA_CONFIG_FATAUT(P_CODEMP IN NUMBER);

    /* BUSCA DADOS DA NUNOTA */
    PROCEDURE GET_DADOS_NUNOTA(P_NUNOTA    IN TGFCAB.NUNOTA%TYPE);

    /* RETORNA O CODIGO DA EMPRESA */
    FUNCTION GET_CODEMP_NUNOTA(
        P_NUNOTA    IN NUMBER
    ) RETURN NUMBER;
    
    /*  Retorna a Top usada na CAB */
    FUNCTION GET_TOP_NUNOTA(
        P_NUNOTA    IN NUMBER
    ) RETURN NUMBER;

    /* Retona o tipo de Negociacao na CAB */
    FUNCTION GET_TIPONEGOCIACAO_NUNOTA(
        P_NUNOTA IN NUMBER
    ) RETURN NUMBER;

    /* Insere o log de faturamento  */
    FUNCTION INSERE_LOGFATAUTO(
        p_nunota   IN NUMBER,
        p_numnota  IN NUMBER,
        p_log      IN CLOB,
        p_dhalter  IN DATE
    ) RETURN BOOLEAN;
    
    /* ATUALIZA A HORA DO ULTIMO FATURAMENTO AUTOMATICO */
    PROCEDURE ATUALIZA_DHFATAUTDCCO (
        P_NUFAT                IN NUMBER,
        P_CODEMP               IN NUMBER,
        P_SITUACAOWMS          IN NUMBER,
        P_DTHRULTFATURAMENTO   IN FLOAT
    );
    
    /* vERIFICA SE O TIPO DE NEGOCIACAO DEVE SER FATURADO */
    PROCEDURE CONSULTA_TIPNEGOFATDCCO (
        P_CODTIPNEG      IN NUMBER,
        P_CODEMP         IN NUMBER,
        P_RESULTADO      OUT BOOLEAN
    );
    
    /*  vERIFICA SE O TIPO DE NEGOCIACAO A VISTA DEVE SER FATURADO */
    PROCEDURE CONSULTA_TIPNEGOFATAVISTADCCO (
        P_CODTIPNEG      IN NUMBER,
        P_CODEMP         IN NUMBER,
        P_RESULTADO      OUT BOOLEAN
    );
    
    
    /*  VERIFICA SE A TOP DO PEDIDO DEVE SER FATURADA */
    PROCEDURE CONSULTA_TOPPEDFATAUT (
        P_TOP       IN NUMBER,
        P_CODEMP         IN NUMBER,
        P_RESULTADO OUT BOOLEAN
    );

    PROCEDURE FATURAPELOESTOQUE(
        P_NUNOTA    IN NUMBER,
        P_RESULTADO OUT BOOLEAN
    );



END PKG_FATURAMENTOAUTOMATICO;
/




/******************************************************************************

                                PACKAGE BODY

*******************************************************************************/

CREATE OR REPLACE PACKAGE BODY SANKHYA.PKG_FATURAMENTOAUTOMATICO AS
    
    /*P_CODEMP_DA_CAB         TGFCAB.CODEMP%TYPE;
    P_CODTIPVENDA_DA_CAB    TGFCAB.CODTIPVENDA%TYPE;
    P_CODTIPOPER_DA_CAB     TGFCAB.CODTIPOPER%TYPE;*/
    
    /**************************************************************************
    * Carrega as configurações mais recentes para um CODEMP específico
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
            DBMS_OUTPUT.PUT_LINE('Nenhuma configuração encontrada para CODEMP: ' || P_CODEMP);
        WHEN OTHERS THEN
            RAISE;
    END CARREGA_CONFIG_FATAUT;
    
    /* Pega os dados do NUNOTA na CAB */
    PROCEDURE GET_DADOS_NUNOTA(
        P_NUNOTA    IN TGFCAB.NUNOTA%TYPE
    ) IS
    
    BEGIN
    
        SELECT CODEMP, CODTIPOPER, CODTIPVENDA
        INTO P_CODEMP_DA_CAB, P_CODTIPOPER_DA_CAB, P_CODTIPVENDA_DA_CAB
        FROM TGFCAB
        WHERE NUNOTA = P_NUNOTA;
    
    
    END GET_DADOS_NUNOTA;
    
    
    
    /* Retorna o código da empresa na cab */
    FUNCTION GET_CODEMP_NUNOTA(
        P_NUNOTA    IN NUMBER
    ) RETURN NUMBER IS
    
    I_CODEMP TGFCAB.CODEMP%TYPE;

    
    BEGIN
    
         -- Verifica se há exatamente um CODEMP correspondente ao NUNOTA
        SELECT CODEMP
        INTO I_CODEMP
        FROM TGFCAB
        WHERE NUNOTA = P_NUNOTA;
        
        RETURN I_CODEMP;
    
    END GET_CODEMP_NUNOTA;
    
    /*  Retonar o código da TOP na CAB */
    FUNCTION GET_TOP_NUNOTA(
        P_NUNOTA    IN NUMBER
    ) RETURN NUMBER IS
    
    I_CODTIPOPER TGFCAB.CODTIPOPER %TYPE;

    
    BEGIN
    
         -- Verifica se há exatamente um CODEMP correspondente ao NUNOTA
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
    * Insere registro no log de faturamento - Estrutura padrão
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
    * Consulta se o tipo de negociação está configurado na tabela AD_TIPNEGOFATDCCO
    ***************************************************************************/
    PROCEDURE CONSULTA_TIPNEGOFATDCCO (
        P_CODTIPNEG      IN NUMBER,
        P_CODEMP         IN NUMBER,
        P_RESULTADO      OUT BOOLEAN
    ) IS
        V_COUNT NUMBER;
    BEGIN
        -- Verifica se o tipo de negociação da NU está configurado para empresa    
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
    * Consulta se o tipo de negociação está configurado na tabela AD_TIPNEGOFATDCCO
    ***************************************************************************/
    PROCEDURE CONSULTA_TIPNEGOFATAVISTADCCO (
        P_CODTIPNEG      IN NUMBER,
        P_CODEMP         IN NUMBER,
        P_RESULTADO      OUT BOOLEAN
    ) IS
        V_COUNT NUMBER;
        
    BEGIN
        -- Verifica se o tipo de negociação da NU está configurado para empresa    
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
    * Consulta se o TOP está configurado na tabela AD_TOPPEDFATAUT
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
    *  Pega os dados da NU que será faturada.
    *
    ***************************************************************************/
    
    
   
    /* Procedure que realiza o faturamento do pedido pelo estoque  */
    PROCEDURE FATURAPELOESTOQUE(
        P_NUNOTA    IN NUMBER,
        P_RESULTADO OUT BOOLEAN
    ) IS
        
        EMPRESA_UTLIZA_WMS               CHAR := 'N';
        TOP_ESTA_HABILITADA_FATURAMENTO  BOOLEAN;
        TIPO_DE_VENDA_A_PRAZO            BOOLEAN;

    BEGIN

        -- Busca o código da Empresa, Tipo de Negociacao e TOP na CAB
        GET_DADOS_NUNOTA(P_NUNOTA);

        
        /*********************************************************************************
         Vamos seguir os seguintes passos:
         
         1 - Empresa utiliza WMS
         2 - Existe alguma configuração de faturamento automatico ativo pra essa empresa
         3 - A top utilizada no pedido, esta habilitada pra ser faturada automaticamente ?
         4 - O tipo de negociação no pedido, esta habilitado para ser faturado ?
         5 - O tipo de negociação é a vista? Existe liberação aprovada para esse cliente?
         6 - Chama o faturamento automatico 
        *********************************************************************************/
        
        


        -- Verifica se a empresa utiliza WMS [1]
        STP_EMP_UTILIZAWMS_DCCO(P_CODEMP_DA_CAB, EMPRESA_UTLIZA_WMS);

        IF EMPRESA_UTLIZA_WMS = 'N' THEN
        
            send_aviso2(68, 'Empresa não utliza wms ' || P_CODEMP_DA_CAB , '', 1);
            COMMIT;
        
            P_RESULTADO := FALSE;
            RETURN;
            
            
        ELSE
        
            -- Carrega configurações do faturamento automático
            CARREGA_CONFIG_FATAUT(P_CODEMP_DA_CAB);
        

    
            -- Empresa está habilitada para utilizar o faturamento automático? [2]
            IF P_CODEMP_DA_CAB <> G_CODEMP  AND G_ATIVO <> 'SIM'  THEN
                
                send_aviso2(68, 'Empresa não esta habilitada para utilizar faturamento automatico ' || P_CODEMP_DA_CAB , '', 1);
                COMMIT;
                
                P_RESULTADO := FALSE;
                RETURN;
            
            ELSE  -- Empresa esta com configuração de faturamento automatico ativo.
                
                
                -- Vamos verificar se a top utilizada esta habilitada pro faturamento automatico [3]
                CONSULTA_TOPPEDFATAUT(P_CODTIPOPER_DA_CAB ,P_CODEMP_DA_CAB,TOP_ESTA_HABILITADA_FATURAMENTO);
                
                IF TOP_ESTA_HABILITADA_FATURAMENTO <> TRUE THEN
                
                    send_aviso2(68, 'Top nao esta habilitada para faturamento ' || P_CODTIPOPER_DA_CAB , '', 1);
                    COMMIT;
                
                    P_RESULTADO := FALSE;
                    RETURN;
                
                ELSE
                
                    -- Verifica o tipo de negociação
                    CONSULTA_TIPNEGOFATDCCO(P_CODTIPVENDA_DA_CAB, P_CODEMP_DA_CAB,TIPO_DE_VENDA_A_PRAZO);
                    
                    IF TIPO_DE_VENDA_A_PRAZO <> TRUE THEN
                        
                        send_aviso2(68, 'O tipo de Negociacao nao e a prazo ' || P_CODTIPVENDA_DA_CAB , '', 1);
                        COMMIT;
                    
                    ELSE

                        send_aviso2(68, 'O Tipo de Negociacao e a prazo ' || P_CODTIPVENDA_DA_CAB , '', 1);
                        COMMIT;

                    END IF;
                    
                    
                    P_RESULTADO := FALSE;
                END IF;
                
            END IF;
            
                    send_aviso2(68, 'Seguiu o fluxo', '', 1);
                    COMMIT;
                    
                    P_RESULTADO := TRUE;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            P_RESULTADO := FALSE;
            RAISE;
    END FATURAPELOESTOQUE;

    
END PKG_FATURAMENTOAUTOMATICO;
/


