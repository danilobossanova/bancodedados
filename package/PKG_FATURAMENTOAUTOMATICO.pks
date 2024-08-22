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

    /* Carrega as configurações mais recentes para um CODEMP específico */
    PROCEDURE CARREGA_CONFIG_FATAUT(P_CODEMP IN NUMBER);

    /* RETORNA O CODIGO DA EMPRESA */
    FUNCTION GET_CODEMP_NUNOTA(
        P_NUNOTA    IN NUMBER
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

    /* Variáveis globais para armazenar as configurações */
    G_NUFAT                 NUMBER(10);
    G_CODEMP                NUMBER(10);
    G_ATIVO                 VARCHAR2(10 BYTE);
    G_SERIE                 NUMBER(10);
    G_SITUACAOWMS           NUMBER(10);
    G_DTHRULTFATURAMENTO    FLOAT(126);
    G_RELATORIOERRO         VARCHAR2(10 BYTE);
    G_RELATORIOFATURAMENTO  VARCHAR2(10 BYTE);
    G_GRUPOEMAIL            VARCHAR2(100 BYTE);
    
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
    
    
    /* Procedure que realiza o faturamento do pedido pela OS  */
    PROCEDURE FATURAPELOESTOQUE(
        P_NUNOTA    IN NUMBER,
        P_RESULTADO OUT BOOLEAN
    ) IS
    
    BEGIN
    
        SELECT 1 FROM DUAL;
    
    END FATURAPELOESTOQUE;
    
    

END PKG_FATURAMENTOAUTOMATICO;
/

/


