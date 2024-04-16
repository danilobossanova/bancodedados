CREATE OR REPLACE TRIGGER SANKHYA.TRG_B_I_TGWIVR_DCCO
BEFORE INSERT 
ON SANKHYA.TGWIVR 
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW

/*
   Author: Danilo Fernando <danilo.fernando@grupocopar.com.br>
   Data: 27/10/2023 16:13
   Obj.: Gerar numeração das contagens do inventário. Assim é possível identificar 
         a sequencia das contagens.
*/
DECLARE

    Pragma Autonomous_Transaction;
    P_CONTAGEM_ATUAL INT := 0;
    P_ESTOQUE_COMERCIAL INT ;
    p_MENSAGEM VARCHAR2(3000);
    P_CONTROLADOWMS VARCHAR2(1) := 'S';
    P_VINCULOOK VARCHAR2(1) := 'S';
    
    
BEGIN


        /*  Ajuste feio por Danilo Fernando - 14/03/2024 */
        -- Verifica se o item é controlado pelo WMS
        STP_EHCONTROLADOWMS_DCCO(:NEW.CODPROD, P_CONTROLADOWMS);
        
        
        /* Ajuste feito por Danilo Fernando - 16/03/2024 15:01
          Verifica se o produto tem vinculo com o endereço que esta  sendo
          inventariado 
        */
        STP_VER_VINCULOENDERECO_DCCO(:NEW.CODEND,:NEW.CODPROD, P_VINCULOOK);
        
        --RAISE_APPLICATION_ERROR(-20001, 'Produto sem Vinculo: ' || P_VINCULOOK);   
             
        
        
        
        -- Identifica qual o estoque comercial para o item no momento da contagem.
        SELECT NVL(SUM(ESTOQUECOMERCIAL.ESTOQUE),0) INTO P_ESTOQUE_COMERCIAL FROM TGFEST ESTOQUECOMERCIAL 
        WHERE ESTOQUECOMERCIAL.CODEMP = :NEW.CODEMP AND ESTOQUECOMERCIAL.CODPROD = :NEW.CODPROD 
        AND ESTOQUECOMERCIAL.CODLOCAL NOT IN ('990000000'); 
        
        --RAISE_APPLICATION_ERROR(-20101,'Estoque Comercial: ' ||  P_ESTOQUE_COMERCIAL);
        
        -- Verifica se é a primeira contagem para o produto nesse inventario
        SELECT NVL(COUNT(AD_CONTAGEM),0) INTO P_CONTAGEM_ATUAL FROM TGWIVR INVT WHERE INVT.CODEMP = :NEW.CODEMP AND INVT.CODPROD = :NEW.CODPROD AND INVT.CODEND = :NEW.CODEND;  
            
        -- Informa o estoque comercial no momento da contagem
        :NEW.AD_QTDESTCOMLOGICA := P_ESTOQUE_COMERCIAL;


        -----------------------------------------------------------------------
        -- Ação para tratar a resposta do VLM que NÃO inATIVA as count anteriores
        -- Se CODEND = 15200, atualiza a contagem como ATIVA='S'
        -----------------------------------------------------------------------
        IF INSERTING THEN

            -- SE O ITEM É CONTROLADO POR WMS REALIZA O INSERT - AJUSTE FEITO POR Danilo Fernando
            IF(P_CONTROLADOWMS = 'S') THEN
            
                -- VERIFICA SE O PRODUTO TEM VINCULO NO ENDEREÇO DE CONTAGEM
                IF(P_VINCULOOK = 'S') THEN
            
                    -- Se já existir contagem, verifica qual o ultima contagem e adiciona 1
                    P_CONTAGEM_ATUAL := P_CONTAGEM_ATUAL + 1;
                    
                    -- Informa a sequencia da contagem para o insert
                    :NEW.AD_CONTAGEM := P_CONTAGEM_ATUAL;
                    
                    :NEW.DHCONTAGEM := SYSDATE;
                   

                    IF(:NEW.CODEND = 15200)THEN
                        ATIVA_CONTAGEM_INVT_DCCO (:NEW.NUIVT,:NEW.CODPROD,:NEW.CODEND,:NEW.AD_CONTAGEM,p_MENSAGEM); 
                    END IF;
                
                ELSE

                      :NEW.ATIVA := 'N';

                      -- iTEM NÃO POSSUI VINCULO COM O ENDEREÇO DE CONTAGEM É SALVO ESSA INFORMAÇÃO
                      STP_PRODSEMWMS_DCCO(:NEW.NUIVT,:NEW.CODEMP,:NEW.CODPROD,:NEW.CODEND,:NEW.DHCONTAGEM,:NEW.CODVOL,:NEW.QTDESTCONTADA,:NEW.QTDESTLOGICA,:NEW.CODUSU,:NEW.ATIVA,:NEW.AD_CONTAGEM, :NEW.SEQUENCIA, 'VINCULO');
                      COMMIT;
                    
                      -- Gera uma Notificação que o Produto não foi contabilizado 
                      SEND_AVISO2(0,'INVT' || :NEW.NUIVT ,'Produto sem vinculo WMS: ' || :NEW.CODPROD,0,1);
                      COMMIT;

                END IF;         
            
            ELSE
            
                    :NEW.ATIVA := 'N';
                    
                    -- Se o PRODUTO NÃO É CONTROLADO PELO WMS
                    
                    -- iTEM NÃO POSSUI VINCULO COM O ENDEREÇO DE CONTAGEM É SALVO ESSA INFORMAÇÃO
                    STP_PRODSEMWMS_DCCO(:NEW.NUIVT,:NEW.CODEMP,:NEW.CODPROD,:NEW.CODEND,:NEW.DHCONTAGEM,:NEW.CODVOL,:NEW.QTDESTCONTADA,:NEW.QTDESTLOGICA,:NEW.CODUSU,:NEW.ATIVA,:NEW.AD_CONTAGEM, :NEW.SEQUENCIA,'CONTROLE');
                    COMMIT;
                    
                    -- Gera uma Notificação que o Produto não foi contabilizado 
                    SEND_AVISO2(0,'INVT' || :NEW.NUIVT ,'Produto não controlado pelo WMS: ' || :NEW.CODPROD,0,1);
                    COMMIT;
                     
                     
            END IF; 

          
        END IF;
        
         EXCEPTION
                WHEN VALUE_ERROR THEN
                RETURN;
                NULL; -- Ignora a exceção VALUE_ERROR (que ocorre quando tentamos inserir NULL em uma coluna NOT NULL)
            
END;
/