CREATE OR REPLACE PROCEDURE copiar_endereco (
    CODEND IN NUMBER,
    NUMERODECOPIAS IN NUMBER
) AS
    v_codendpai TGWEND.CODEND%TYPE;
    v_descrend TGWEND.DESCREND%TYPE;
    v_endereco TGWEND.ENDERECO%TYPE;
    v_next_codend NUMBER;
    
    
    /**************************************************************************
    * @author: Danilo Fernando <danilo.fernando@grupocopar.com.br>
    * @since: 10/05/202416:15
    * @sound: Victor Ray - Stay For A While
    * @description: Copia endere�os - Na quantidade informada
    *
    **************************************************************************/
    
    
    
BEGIN
    -- Selecionar os dados do endere�o informado
    SELECT CODENDPAI, DESCREND, ENDERECO
    INTO v_codendpai, v_descrend, v_endereco
    FROM TGWEND
    WHERE CODEND = CODEND
    AND ROWNUM = 1;

    -- Obter o pr�ximo ID de endere�o
    Stp_OBTEMID('TGWEND', v_next_codend);
    

    -- Fazer as c�pias conforme o n�mero de c�pias informado
    FOR i IN 1..NUMERODECOPIAS LOOP
    
        -- Adicionar 1 � descri��o e ao endere�o
        v_descrend := v_descrend || ' ' || (TO_NUMBER(REGEXP_REPLACE(v_descrend, '[^[:digit:]]', '')) + TO_NUMBER(i)); -- Modifica��o nesta linha
        v_endereco := REGEXP_REPLACE(v_endereco, '(\d+)$', TO_CHAR(TO_NUMBER(REGEXP_REPLACE(v_endereco, '(\d+)$', '\1')) + TO_NUMBER(i))); -- Modifica��o nesta linha

        -- Inserir o novo registro
        INSERT INTO TGWEND (
            CODEND, CODENDPAI, DESCREND, ENDERECO, GRAU, 
            ATIVO, ANALITICO, M3MAX, PESOMAX, ALTURA, 
            LARGURA, NIVEL, MULTIPROD, EXPEDICAO, PROIBIRGRUPO, 
            PROIBIRPRODUTO, PICKING, PROFUNDIDADE, PROIBIRLOCAL, ALTCOORD, 
            LARGCOORD, PROFUNDCOORD, FRAGMENTAEST, PROIBIRCONTROLE, FLOWRACK, 
            EXCLCONF, BLOQUEADO, TIPO, PAR, ORDEM, 
            APENASCONTPORPROD, ENDMOVVERTICAL, CODENDPREF, CODENDSEC, CODLOCAL, 
            USAPICKINGINTERMEDIARIO, PICKINGINTERMEDIARIO, CODEMP, CONEXAOENTRADA, CONEXAOSAIDA, 
            NROMAXPROD, REABPICK, CROSSDOCK, LOTEUNICO, UTILIZAUMA, 
            QTDMAXUMA, AD_CHKVLM
        ) 
        SELECT 
            v_next_codend, CODENDPAI, v_descrend, v_endereco, GRAU, 
            ATIVO, ANALITICO, M3MAX, PESOMAX, ALTURA, 
            LARGURA, NIVEL, MULTIPROD, EXPEDICAO, PROIBIRGRUPO, 
            PROIBIRPRODUTO, PICKING, PROFUNDIDADE, PROIBIRLOCAL, ALTCOORD, 
            LARGCOORD, PROFUNDCOORD, FRAGMENTAEST, PROIBIRCONTROLE, FLOWRACK, 
            EXCLCONF, BLOQUEADO, TIPO, PAR, ORDEM, 
            APENASCONTPORPROD, ENDMOVVERTICAL, CODENDPREF, CODENDSEC, CODLOCAL, 
            USAPICKINGINTERMEDIARIO, PICKINGINTERMEDIARIO, CODEMP, CONEXAOENTRADA, CONEXAOSAIDA, 
            NROMAXPROD, REABPICK, CROSSDOCK, LOTEUNICO, UTILIZAUMA, 
            QTDMAXUMA, AD_CHKVLM
        FROM TGWEND
        WHERE CODEND = CODEND;

        -- Incrementar o pr�ximo ID de endere�o
        v_next_codend := v_next_codend + 1;
    END LOOP;

    COMMIT;
    
END;
/
