DROP TRIGGER SANKHYA.TRG_BFU_TGWITE_DCCO;

CREATE OR REPLACE TRIGGER SANKHYA.TRG_BFU_TGWITE_DCCO
    BEFORE INSERT
    ON SANKHYA.TGWITE
    FOR EACH ROW
DECLARE
    N_EMPRESA            TGFCAB.CODEMP%TYPE;
    N_ESTOQUECOMERCIAL   NUMBER;
    N_ESTOQUEWMS         NUMBER;
    N_WMSBLOQUEADO       TGFEST.WMSBLOQUEADO%TYPE;
    
    S_REFERENCIA         TGFPRO.REFERENCIA%TYPE;
    S_DESCRPROD          TGFPRO.DESCRPROD%TYPE;
    
    C_EMPRESAUTILIZAWMS  CHAR := NULL;
    
    V_MENSAGEM           CLOB := '';
    S_PRODUTOS           CLOB := NULL;

    /***************************************************************************
    * @author: Danilo Fernando <danilo.bossanova@hotmail.com>
    * @since 30/07/2024 17:34
    * @Description: Trigger que verifica se existe saldo comercial suficiente.
    *   Caso o saldo wms seja maior que o saldo comercial, não será possível
    *   faturar após a separação. Essa trigger visa impedir que isso ocorra.
    *   Geralmente isso ocorre quando há sobra e não há feito ajuste.
    ****************************************************************************/

BEGIN

    IF STP_GET_ATUALIZANDO THEN
        RETURN;
    END IF;


    --RAISE_APPLICATION_ERROR(-20101, 'Galera boa de luta. Teste.');

    -- Só deve verificar se a empresa utiliza WMS, se o produto é controlado pelo WMS
    -- Loop Criado para apresentar a mensagem de todos os itens divergentes de uma só vez -- Daniel Batista 28/08/2023
    FOR CUR IN (
        SELECT CODPROD, SEQUENCIA, CODEMP, CODLOCALORIG 
        FROM TGFITE 
        WHERE NUNOTA = :NEW.NUNOTA
    ) LOOP
    
    
        -- Verifica se a empresa utiliza WMS
        STP_EMP_UTILIZAWMS_DCCO(CUR.CODEMP, C_EMPRESAUTILIZAWMS);



        -- Só valida se a empresa utiliza WMS
        IF C_EMPRESAUTILIZAWMS = 'S' THEN
            

            -- Saldo WMS de todos os endereços que permitem expedição de mercadoria
            SELECT NVL(SUM(WEST.ESTOQUE), 0) 
            INTO N_ESTOQUEWMS 
            FROM TGWEST WEST 
            INNER JOIN TGWEND ENDE ON ENDE.CODEMP = WEST.CODEMP AND ENDE.CODEND = WEST.CODEND
            WHERE 
                WEST.CODEMP = CUR.CODEMP   -- Empresa
                AND WEST.CODPROD = CUR.CODPROD  -- Produto
                AND WEST.CODEND NOT IN (15189, 15190, 15191, 15192, 15193, 15194, 15195, 15196, 15197) -- Endereços especiais
                AND ENDE.EXPEDICAO = 'S'  -- Apenas endereços que aceitam expedição
            GROUP BY WEST.CODEMP, WEST.CODPROD;
            


            -- Verifica se o estoque WMS é maior que o estoque comercial
            SELECT NVL(SUM(WMSBLOQUEADO), 0), NVL(SUM(ESTOQUE), 0)
            INTO N_WMSBLOQUEADO, N_ESTOQUECOMERCIAL
            FROM TGFEST EST
            WHERE EST.CODEMP = CUR.CODEMP -- Empresa
                AND EST.CODLOCAL = CUR.CODLOCALORIG -- Local
                AND EST.CODPROD = CUR.CODPROD -- Código do produto
            GROUP BY EST.CODEMP, EST.CODLOCAL, EST.CODPROD;


            --RAISE_APPLICATION_ERROR(-20101, 'ESTIQEWMS: ' || N_ESTOQUEWMS || '  ESTCOM-wmsbloq: ' || (N_ESTOQUECOMERCIAL - N_WMSBLOQUEADO) || '  QTDWMS: ' || :NEW.QTDWMS || ' ESTCOM: ' ||   N_ESTOQUECOMERCIAL);            


            -- Verifica se o estoque WMS é maior que o estoque comercial
            IF N_ESTOQUEWMS > (N_ESTOQUECOMERCIAL - N_WMSBLOQUEADO ) THEN
            
                -- Verifica se a quantidade que está sendo enviada para separação é menor
                -- que o saldo comercial. Isso serve para evitar o bloqueio completo da 
                -- separação do item, caso a separação seja de até o limite do saldo comercial
                IF :NEW.QTDWMS > N_ESTOQUECOMERCIAL THEN
                
                    -- Dados do produto [Referência e Descrição]
                    SELECT NVL(PRODUTOS.REFERENCIA, '#REF '), NVL(PRODUTOS.DESCRPROD, '## ')
                    INTO S_REFERENCIA, S_DESCRPROD 
                    FROM TGFPRO PRODUTOS 
                    WHERE PRODUTOS.CODPROD = CUR.CODPROD;
                
                    -- Criar mensagem na regra de parâmetros
                    S_PRODUTOS := S_REFERENCIA || ' - ' || S_DESCRPROD || '<br><p><b>Est. WMS:</b> '  ||  N_ESTOQUEWMS || ' | <b>Est. Com.:</b> ' || N_ESTOQUECOMERCIAL || '<br/>';
                    
                END IF;
            END IF;
        

        ELSE
            -- Caso a empresa não utilize WMS, não adiciona registro na TGWITE
            show_raise('TGWITE', 2);
    
        END IF;
        
    END LOOP;
    

    IF S_PRODUTOS IS NOT NULL THEN 
        -- Criar uma regra em parâmetros e regras
        show_raise('TGWITE', 1, VETOR('PRODUTOS'), VETOR(S_PRODUTOS));
        -- RAISE_APPLICATION_ERROR(-20101, V_MENSAGEM);
    END IF;
    
    
    RAISE_APPLICATION_ERROR(-20101, 'Parada aqui...');

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20101, SQLERRM);
END;
/
