CREATE OR REPLACE TRIGGER TRG_AU_TGFCABWMS_DCCO
BEFORE UPDATE OF CODDOCA ON TGFCAB
FOR EACH ROW
WHEN(NEW.CODEMP = 11 AND NEW.CODDOCA IS NOT NULL AND NEW.CODTIPOPER = 1788)

DECLARE

    v_cursor SYS_REFCURSOR;
    v_codprod TGFITE.CODPROD%TYPE;
    
    v_skus VARCHAR2(1500) := "";



BEGIN
    
    /**************************************************************************
    * @Author: Danilo Fernando <danilo.bossanova@hotmail.com>
    * @Date: 22/04/2024 11:10
    * @Ao som de:
    * @Description: Trigger que monitora o campo CODDOCA e analisa os produtos
    *               que est�o em separa��o no wms. Os produtos que est�o listados
    *               e est�o sendo inventariados n�o poder�o ser movimentados.
    ***************************************************************************/

     -- Chama a fun��o para verificar os SKUs em invent�rio para o n�mero do pedido
    v_cursor := FC_SKU_EMINVENTARIO_DCCO(:NEW.NUNOTA);

    -- Loop para percorrer os resultados
    LOOP
        FETCH v_cursor INTO v_codprod;
        EXIT WHEN v_cursor%NOTFOUND;

        IF v_codprod IS NOT NULL THEN
            v_skus := v_skus || ' ' || v_codprod || '<br>';
        END IF;
        
    END LOOP;

    -- Fecha o cursor
    CLOSE v_cursor;
    
    
    -- Mostra mensagem de produto bloqueado por invent�rio
    IF v_skus IS NOT NULL THEN
     SHOW_RAISE('TGFCAB',141);
    END IF;


END;
/
