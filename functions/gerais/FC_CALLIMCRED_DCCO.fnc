CREATE OR REPLACE FUNCTION FC_CALLIMCRED_DCCO
    (p_codparc IN TGFPAR.CODPARC%TYPE)
RETURN NUMBER
IS

    v_limite_credito NUMBER := 0; -- Vari�vel para armazenar o resultado
    
    
    /*
   Autor: Danilo
   Data: 29/01/2024
   Resumo: Esta fun��o calcula o limite de cr�dito considerando a soma dos valores n�o baixados.
           Leva em considera��o os par�metros especificados na cl�usula JOIN e WHERE,
           com o par�metro p_codparc.
*/

    
BEGIN
    -- Calcula o limite de cr�dito considerando a soma dos valores n�o baixados
    SELECT COALESCE(PAR.LIMCRED - NVL(SUM(FIN.VLRDESDOB), 0), 0)
    INTO v_limite_credito
    FROM TGFPAR PAR
    LEFT JOIN TGFFIN FIN ON FIN.CODPARC = PAR.CODPARC 
        AND FIN.DHBAIXA IS NULL 
        AND FIN.RECDESP = 1 
        AND FIN.PROVISAO = 'N'
        AND FIN.CODPARC = p_codparc
    WHERE PAR.CODPARC = p_codparc
    GROUP BY PAR.LIMCRED;

    RETURN v_limite_credito; -- Retorna o resultado calculado

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0; -- Retorna 0 se n�o houver dados encontrados
END FC_CALLIMCRED_DCCO;
/
