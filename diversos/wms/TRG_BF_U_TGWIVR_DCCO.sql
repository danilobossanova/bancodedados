DROP TRIGGER SANKHYA.TRG_BF_U_TGWIVR_DCCO;

CREATE OR REPLACE TRIGGER SANKHYA.TRG_BF_U_TGWIVR_DCCO
BEFORE UPDATE ON SANKHYA.TGWIVR FOR EACH ROW

/*
   Author: Danilo Fernando <danilo.fernando@grupocopar.com.br>
   Data: 27/10/2023 16:13
   Obj.: Gerar numera��o das contagens do invent�rio. Assim � poss�vel identificar 
         a sequencia das contagens.
*/
DECLARE
    P_CONTAGEM_ATUAL INT := 1;
    P_ESTOQUE_COMERCIAL INT ;
BEGIN
        -- Identifica qual o estoque comercial para o item
        (SELECT SUM(ESTOQUECOMERCIAL.ESTOQUE) INTO P_ESTOQUE_COMERCIAL FROM TGFEST ESTOQUECOMERCIAL 
        WHERE ESTOQUECOMERCIAL.CODEMP = :NEW.CODEMP AND ESTOQUECOMERCIAL.CODPROD = :NEW.CODPROD 
        AND ESTOQUECOMERCIAL.CODLOCAL NOT IN ('990000000')); 
        
        RAISE_APPLICATION_ERROR(-20101, P_ESTOQUE_COMERCIAL);

        
        -- Verifica se � a primeira contagem para o produto nesse inventario
          SELECT NVL(MAX(AD_CONTAGEM),1) INTO P_CONTAGEM_ATUAL FROM TGWIVR INVT WHERE INVT.CODEMP = :NEW.CODEMP AND INVT.CODPROD = :NEW.CODPROD AND INVT.CODEND = :NEW.CODEND;  
        
        -- Se j� existir contagem, verifica qual o ultima contagem e adiciona 1

END;