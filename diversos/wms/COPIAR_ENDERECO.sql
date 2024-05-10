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
    * @description: Copia endereços - Na quantidade informada
    *
    **************************************************************************/
    
    
    
BEGIN
    -- Selecionar os dados do endereço informado
    SELECT CODENDPAI, DESCREND, ENDERECO
    INTO v_codendpai, v_descrend, v_endereco
    FROM TGWEND
    WHERE CODEND = CODEND
    AND ROWNUM = 1; -- Adicionando esta cláusula para garantir apenas uma linha é retornada

    -- Obter o próximo ID de endereço não utilizado
    -- Obter o próximo ID de endereço
    Stp_OBTEMID('TGWEND', v_next_codend);
    
    
    --RAISE_APPLICATION_ERROR(-20010,v_next_codend);
    

    -- Fazer as cópias conforme o número de cópias informado
    FOR i IN 1..NUMERODECOPIAS LOOP
        -- Adicionar 1 à descrição e ao endereço
        v_descrend := v_descrend || ' ' || NVL(TO_CHAR(TO_NUMBER(REGEXP_SUBSTR(v_descrend, '\d+$')) + i), TO_CHAR(i));
        v_endereco := REGEXP_REPLACE(v_endereco, '(\d+)$', TO_CHAR(NVL(TO_NUMBER(REGEXP_SUBSTR(v_endereco, '\d+$')), 0) + i));

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
        WHERE CODEND = CODEND
        AND ROWNUM = 1; -- Adicionando esta cláusula para garantir apenas uma linha é retornada

        -- Incrementar o próximo ID de endereço
        v_next_codend := v_next_codend + 1;
    END LOOP;

    COMMIT;
    
END;
/
