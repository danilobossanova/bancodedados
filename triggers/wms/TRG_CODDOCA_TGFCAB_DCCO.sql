CREATE OR REPLACE TRIGGER SANKHYA.TRG_CODDOCA_TGFCAB_DCCO
AFTER UPDATE OF CODDOCA ON SANKHYA.TGFCAB
FOR EACH ROW
WHEN (NEW.CODEMP = 11 AND (OLD.CODDOCA IS NULL AND NEW.CODDOCA IS NOT NULL OR OLD.CODDOCA IS NOT NULL AND NEW.CODDOCA IS NULL OR OLD.CODDOCA <> NEW.CODDOCA))
DECLARE
    v_erro VARCHAR2(4000);
BEGIN
    /***************************************************************
    * Autor: Danilo Fernando <danilo.fernando@grupocopar.com.br>
    * Data: 25/09/2024
    * Descri��o: Trigger para inser��o de pedido � vista no WMS
    *    para que a��o agendada lance uma solicita��o de libera��o
    *    automatica para o financeiro.   
    ***************************************************************/

    -- Chamada do procedimento
    BEGIN
        PKG_FATURAMENTOAUTOMATICO.INSERE_PEDIDO_AVISTA_WMS(p_nunota => :NEW.NUNOTA);
    EXCEPTION
        WHEN OTHERS THEN
            v_erro := SUBSTR(SQLERRM, 1, 4000);
            -- Captura o erro, mas n�o interrompe a execu��o
            -- Exemplo de l�gica adicional: DBMS_OUTPUT.PUT_LINE('Erro ao inserir pedido � vista: ' || v_erro);
    END;

EXCEPTION
    WHEN OTHERS THEN
        v_erro := SUBSTR(SQLERRM, 1, 4000);
        -- Captura erro geral da trigger e reverte a transa��o
        -- Exemplo de l�gica adicional: DBMS_OUTPUT.PUT_LINE('Erro geral na trigger: ' || v_erro);
        RAISE;
END;
