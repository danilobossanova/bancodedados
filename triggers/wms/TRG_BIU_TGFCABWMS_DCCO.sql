CREATE OR REPLACE TRIGGER SANKHYA.TRG_BIU_TGFCABWMS_DCCO
BEFORE INSERT OR UPDATE
ON SANKHYA.TGFCAB
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW

    /*
    * @author: Danilo Fernando <danilo.bossanova@hotmail.com>
    * @since: 09/05/2024 12:53
    * @description: Valida tipo de Entrega
    */

DECLARE

    -- Constante
    AGUARDANDO_APROVACAO    CONSTANT CHAR(1) := 'A';
    PEDIDO_CONFIRMADO       CONSTANT CHAR(1) := 'L';
    INFORME_TIPO_ENTREGA    CONSTANT CHAR(1) := 'Z';
    
    MOTOBOY_TIPO_ENTREGA    CONSTANT CHAR(1) := 'M';
    CLIENTE_BALCAO          CONSTANT CHAR(1) := 'B';
    ENTREGA_DCCO            CONSTANT CHAR(1) := 'E';
    CLIENTE_RETIRA          CONSTANT CHAR(1) := 'R';
    ENTREGA_TRANSPORTADOR   CONSTANT CHAR(1) := 'L';
    TRANSPORTADORA_RETIRA   CONSTANT CHAR(1) := 'T';
    ENTREGA_LEVAR_MAQUINA   CONSTANT CHAR(2) := 'TT';
    EDI_PARTNET             CONSTANT CHAR(1) := 'D';
    
    
    TIPO_FRETE_INCLUSO      CONSTANT CHAR(1) := 'S';
    TIPO_FRETE_EXTRANOTA    CONSTANT CHAR(1) := 'N';

    CIF                     CONSTANT CHAR(1) := 'C';
    FOB                     CONSTANT CHAR(1) := 'F';
    SEM_FRETE               CONSTANT CHAR(1) := 'S';
    TRANSPORTE_PROPRIO_DEST CONSTANT CHAR(1) := 'D';
    TERCEIROS               CONSTANT CHAR(1) := 'T';
    TRANSPORTE_PROPRIO_REM  CONSTANT CHAR(1) := 'R';
    

    -- Variaveis
    C_UTILIZAWMS TGFEMP.UTILIZAWMS%TYPE;
    
BEGIN

    -- VERIFICA SE A EMPRESA UTILIZA WMS
    STP_EMP_UTILIZAWMS_DCCO(:NEW.CODEMP, C_UTILIZAWMS);

    IF C_UTILIZAWMS = 'S' THEN
    
        --RAISE_APPLICATION_ERROR(-20001,:NEW.AD_TIPOENTREGA);
    
        CASE

            WHEN INSERTING THEN
            
                ---RAISE_APPLICATION_ERROR(-20001,:NEW.STATUSNOTA);
                -- VALIDAÇÕES PARA ORÇAMENTO TOP 1700
                IF :NEW.CODTIPOPER = 1700 THEN
                    --SENÃO FOI INFORMADO TIPO DE ENTREGA, ATRIBUI UM TIPO PADRAO
                    IF :NEW.AD_TIPOENTREGA IS NULL THEN
                        :NEW.AD_TIPOENTREGA := INFORME_TIPO_ENTREGA;
                    END IF;
                END IF;
                
                
                -- VALIDAÇÕES PRA PEDIDOS NA TOP 1729 E 1788
                IF :NEW.CODTIPOPER IN (1729,1788) THEN
                    --SENÃO FOI INFORMADO TIPO DE ENTREGA, ATRIBUI UM TIPO PADRAO
                    IF :NEW.AD_TIPOENTREGA IS NULL THEN
                        :NEW.AD_TIPOENTREGA := INFORME_TIPO_ENTREGA;
                    END IF;
                END IF;    



            WHEN UPDATING THEN
            
            
            --RAISE_APPLICATION_ERROR(-20001,:NEW.STATUSNOTA);
            
            
            
                -- VERIFICA ATUALIZAÇÃO DO ORÇAMENTO 1700
                IF :OLD.CODTIPOPER = 1700 THEN
                    --SENÃO FOI INFORMADO TIPO DE ENTREGA, ATRIBUI UM TIPO PADRAO
                    IF :NEW.AD_TIPOENTREGA IS NULL THEN
                        :NEW.AD_TIPOENTREGA := INFORME_TIPO_ENTREGA;
                    END IF;
                END IF;

    
                -- ATUALIZA O PEDIDO NA TOP 1729 E 1788
                IF :OLD.CODTIPOPER IN (1729,1788) THEN
                    
                    -- SE ESTIVER CONFIRMANDO O PEDIDO NÃO PODE DEIXAR 
                    -- O TIPO DE ENTREGA IGUAL A 9
                    IF :NEW.STATUSNOTA = PEDIDO_CONFIRMADO THEN
                    
                        IF :NEW.AD_TIPOENTREGA = INFORME_TIPO_ENTREGA THEN
                            --RAISE_APPLICATION_ERROR(-20001,:NEW.AD_TIPOENTREGA);
                            SHOW_RAISE('TGFCAB',142);
                        END IF;
                        
                    END IF;

                    
                    -- Não deixa trocar o Tipo de Entrega para o Tipo padrao.
                    IF :NEW.AD_TIPOENTREGA = INFORME_TIPO_ENTREGA THEN
                        SHOW_RAISE('TGFCAB',143);
                    END IF;
                    
                    
                    -- SE FOR CLIENTE BALCAO SÓ PODE NA TOP 1729
                    IF :NEW.AD_TIPOENTREGA = CLIENTE_BALCAO  AND :NEW.CODTIPOPER <> 1729  THEN
                        SHOW_RAISE('TGFCAB',144);
                    END IF;
                    
                    /***********************************************************
                    * Ajustado a pedido de Silvado e Daniel Jr. 30/09/2024. 
                    * Data da solicitação 02/09/2024 08:35 [Email]
                    * Criar regras forçando tipo de frete por tipo de entrega e top
                    *
                    * Cliente Balcao --> 'Entrega Propia' -> Deve ser informado o codigo do parceiro no código da transportadora
                    * Motoboy Entrega --> 'Transporte proprio do Remetente'
                    * Cliente Retira --> 'Transporte proprio do Destinatario' --> Código do Parceiro no código da transportadora
                    * Entrega na Transportadora --> CIF -> Por conta do Remetente ou FOB por conta o Destinatario. --> Aceitar apenas 1 dos 2
                    * Transportadora Retira --> CIF -> Por conta do Remetente ou FOB por conta o Destinatario. --> Aceitar apenas 1 dos 2
                    * Entrega DCCO --> CIF/FOB - Transporte próprio do Remetente.
                    * Entregar [Levar Maquina] --> CIF/FOB --> Transporte Proprio do Destinatario
                    *
                    *  CODPARCTRANSP --> cODIGO DO PARCEIRO TRANSPORTADOR
                    *
                    ***********************************************************/
                    
                    -- NOVOS VALORES
                    CASE :NEW.AD_TIPOENTREGA

                        WHEN CLIENTE_BALCAO THEN -- 0 - CLIENTE BALCAO
                        
                            -- lógica para cliente balcão
                            :NEW.CIF_FOB := TRANSPORTE_PROPRIO_DEST;
                            :NEW.CODPARCTRANSP := :NEW.CODPARC;
                            :NEW.TIPFRETE := TIPO_FRETE_EXTRANOTA; 
                            

                        WHEN MOTOBOY_TIPO_ENTREGA THEN -- 1 - MOTOBOY ENTREGA
                           
                            -- lógica para motoboy entrega
                            :NEW.CIF_FOB    := TRANSPORTE_PROPRIO_REM;
                            :NEW.CIF_FOB    := CIF;
                            :NEW.TIPFRETE   := TIPO_FRETE_INCLUSO;
                            

                        WHEN CLIENTE_RETIRA THEN -- 2 - CLIENTE RETIRA
                            -- lógica para cliente retira
                            :NEW.CIF_FOB := TRANSPORTE_PROPRIO_DEST;
                            
                            
                        WHEN ENTREGA_TRANSPORTADOR, TRANSPORTADORA_RETIRA THEN -- -- 3 e 4 - ENTREGA TRANSPORTADORA e TRANSPORTADORA RETIRA
                            -- lógica para entrega na transportadora
                            IF(:NEW.CIF_FOB NOT IN (TRANSPORTE_PROPRIO_REM, TRANSPORTE_PROPRIO_DEST)) THEN
                                SHOW_RAISE('TGFCAB',145); -- sÓ PODE ESSES DOIS ACIMA
                            END IF;
                        
                        WHEN ENTREGA_DCCO THEN -- 5 - ENTREGA DCCO
                            -- lógica para entrega DCCO
                            :NEW.CIF_FOB := TRANSPORTE_PROPRIO_REM;

                        WHEN ENTREGA_LEVAR_MAQUINA THEN -- 6 - ENTREGA LEVAR MAQUINA
                            -- lógica para entrega levar maquina
                            :NEW.CIF_FOB := TRANSPORTE_PROPRIO_REM;

                        WHEN EDI_PARTNET THEN -- 7 - EDI PARTNER
                            -- lógica para EDI Partner
                            :NEW.CIF_FOB := TRANSPORTE_PROPRIO_DEST;

                    END CASE;
                    
                    -- Se o tipo de Entrega for 1 - Motoboy Entrega, o VLR do Frete deve ser informado
                    IF :NEW.AD_TIPOENTREGA = MOTOBOY_TIPO_ENTREGA THEN
                    
                        -- VERIFICA SE O VALOR DO FRETE FOI INFORMADO
                        IF :NEW.VLRFRETE < 1 THEN
                            SHOW_RAISE('TGFCAB',145);
                        END IF;
                        
                        -- SETAR O TIPO DE FRETE E CIF/FOB
                        IF (:NEW.TIPFRETE <> TIPO_FRETE_INCLUSO) OR (:NEW.CIF_FOB <> CIF) THEN
                        
                            :NEW.TIPFRETE   := TIPO_FRETE_INCLUSO;
                            :NEW.CIF_FOB    := CIF;
                        
                        END IF; 
                        
                    
                    END IF;
                    
                END IF;
                
        END CASE;
        
    END IF;

END;
/