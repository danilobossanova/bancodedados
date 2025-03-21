CREATE OR REPLACE PROCEDURE SANKHYA.PRC_CONTAR_LINHAS_TGWREV_DCCO(
    pNuNota IN NUMBER,
    pQuantidadeLinhas OUT NUMBER
) IS
    /********************************************************************************
    * @author: Danilo Fernando <danilo.fernando@grupocopar.com.br>
    * @date: 27/02/2025 16:59
    * @description: Retorna o n�mero de linhas encontradas na tabela TGWREV para um 
    *               determinado NUNOTA. Se n�o encontrar nenhuma linha, retorna 1.
    * 
    * @param pNuNota: N�mero da nota para realizar a consulta
    * @param pQuantidadeLinhas: Par�metro de sa�da com a quantidade de linhas encontradas
    ********************************************************************************/
    vQuantidade NUMBER := 0;
    vErro VARCHAR2(4000);
BEGIN
    -- Consulta para contar o n�mero de linhas
    SELECT COUNT(*)
    INTO vQuantidade
    FROM SANKHYA.TGWREV VOL
    WHERE VOL.NUNOTA = pNuNota;
    
    -- Verifica se encontrou alguma linha
    IF vQuantidade = 0 THEN
        pQuantidadeLinhas := 1; -- N�o encontrou linhas, retorna 1 conforme solicitado
    ELSE
        pQuantidadeLinhas := vQuantidade; -- Encontrou linhas, retorna a quantidade real
    END IF;
    
    -- Log para depura��o (opcional, pode ser removido em produ��o)
    -- DBMS_OUTPUT.PUT_LINE('NUNOTA: ' || pNuNota || ' - Quantidade: ' || pQuantidadeLinhas);
    
EXCEPTION
    WHEN OTHERS THEN
        vErro := SQLERRM;
        -- Registra o erro (opcional)
        -- INSERT INTO SANKHYA.LOG_ERROS_PROCEDURE (DATA, PROCEDURE_NOME, PARAMETRO, ERRO) 
        -- VALUES (SYSDATE, 'PRC_CONTAR_LINHAS_TGWREV', pNuNota, vErro);
        
        -- Em caso de erro, retorna 1 como valor padr�o
        pQuantidadeLinhas := 1;
        -- Propaga o erro para o chamador
        RAISE_APPLICATION_ERROR(-20001, 'Erro ao contar linhas da TGWREV: ' || vErro);
END PRC_CONTAR_LINHAS_TGWREV_DCCO;
/

-- Exemplo de uso:
/*
DECLARE
    vNumeroLinhas NUMBER;
BEGIN
    SANKHYA.PRC_CONTAR_LINHAS_TGWREV(5242648, vNumeroLinhas);
    DBMS_OUTPUT.PUT_LINE('N�mero de linhas: ' || vNumeroLinhas);
END;
*/