DROP TRIGGER SANKHYA.TRG_BI_EXP_DCCO;

CREATE OR REPLACE TRIGGER SANKHYA.TRG_BI_EXP_DCCO
BEFORE INSERT OR UPDATE ON SANKHYA.TGWEXP
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
    /********************************************************************************
    * @author: Danilo Fernando <danilo.bossanova@hotmail.com>
    * @date: 27/02/2025
    * @last_update: 27/02/2025
    * @description: Trata o campo CONTROLE para evitar valores nulos,
    *               substituindo-os por um espaço em branco.
    * @table: TGWEXP
    * @columns_affected: CONTROLE
    ********************************************************************************/
    vErro VARCHAR2(255);
BEGIN
    -- Verifica se o campo CONTROLE é NULL e substitui por um espaço em branco
    IF :NEW.CONTROLE IS NULL THEN
        :NEW.CONTROLE := ' ';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Captura e registra qualquer erro que possa ocorrer durante a execução da trigger
        vErro := SQLERRM;
        -- Registra o erro em uma tabela de log (opcional)
        -- INSERT INTO SANKHYA.LOG_ERROS_TRIGGER (DATA, TRIGGER_NOME, ERRO) 
        -- VALUES (SYSDATE, 'TRG_BI_EXP_DCCO', vErro);
        -- Propaga o erro para que ele seja reportado corretamente
        RAISE;
END;
/