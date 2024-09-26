CREATE OR REPLACE PROCEDURE SANKHYA."EV_FATAUTOM_DCCO" (
       P_TIPOEVENTO INT,    -- Identifica o tipo de evento
       P_IDSESSAO VARCHAR2, -- Identificador da execução. Serve para buscar informações dos campos da execução.
       P_CODUSU INT         -- Código do usuário logado
) AS
       BEFORE_INSERT INT;
       AFTER_INSERT  INT;
       BEFORE_DELETE INT;
       AFTER_DELETE  INT;
       BEFORE_UPDATE INT;
       AFTER_UPDATE  INT;
       BEFORE_COMMIT INT;
BEGIN
       BEFORE_INSERT := 0;
       AFTER_INSERT  := 1;
       BEFORE_DELETE := 2;
       AFTER_DELETE  := 3;
       BEFORE_UPDATE := 4;
       AFTER_UPDATE  := 5;
       BEFORE_COMMIT := 10;
       
/*******************************************************************************
   É possível obter o valor dos campos através das Functions:
   
  EVP_GET_CAMPO_DTA(P_IDSESSAO, 'NOMECAMPO') -- PARA CAMPOS DE DATA
  EVP_GET_CAMPO_INT(P_IDSESSAO, 'NOMECAMPO') -- PARA CAMPOS NUMÉRICOS INTEIROS
  EVP_GET_CAMPO_DEC(P_IDSESSAO, 'NOMECAMPO') -- PARA CAMPOS NUMÉRICOS DECIMAIS
  EVP_GET_CAMPO_TEXTO(P_IDSESSAO, 'NOMECAMPO')   -- PARA CAMPOS TEXTO
  
  O primeiro argumento é uma chave para esta execução. O segundo é o nome do campo.
  
  Para os eventos BEFORE UPDATE, BEFORE INSERT e AFTER DELETE todos os campos estarão disponíveis.
  Para os demais, somente os campos que pertencem à PK
  
  * Os campos CLOB/TEXT serão enviados convertidos para VARCHAR(4000)
  
  Também é possível alterar o valor de um campo através das Stored procedures:
  
  EVP_SET_CAMPO_DTA(P_IDSESSAO,  'NOMECAMPO', VALOR) -- VALOR DEVE SER UMA DATA
  EVP_SET_CAMPO_INT(P_IDSESSAO,  'NOMECAMPO', VALOR) -- VALOR DEVE SER UM NÚMERO INTEIRO
  EVP_SET_CAMPO_DEC(P_IDSESSAO,  'NOMECAMPO', VALOR) -- VALOR DEVE SER UM NÚMERO DECIMAL
  EVP_SET_CAMPO_TEXTO(P_IDSESSAO,  'NOMECAMPO', VALOR) -- VALOR DEVE SER UM TEXTO
********************************************************************************/

/*     IF P_TIPOEVENTO = BEFORE_INSERT THEN
             --DESCOMENTE ESTE BLOCO PARA PROGRAMAR O "BEFORE INSERT"
       END IF;*/
       
       
       SEND_NOTIFICATION(68, NULL, 'Evento ', 'tIPO DE eVENTO:' || P_TIPOEVENTO , 2);
       COMMIT; 
       
        IF P_TIPOEVENTO = AFTER_INSERT THEN
        
            DECLARE
            
                P_NUNOTA                    NUMBER(10);                     -- NUNOTA
                P_SITUACAO                  VARCHAR2(30);                   -- SITUACAO ATUAL 
                P_DHFATURAMENTO AD_PEDIDOSFATURAR.DHFATURAMENTO%TYPE;       -- DATAHORA FATURAMENTO
                P_TOP           NUMBER(10);                                 -- TOP DE PEDIDO

                
                 -- Variáveis locais
                v_mensagem_notificacao VARCHAR2(3000);
                v_resultado_faturamento BOOLEAN;
                v_msg_resposta_faturamento_automatico VARCHAR2(1000);
                
            
            BEGIN
            
            
                /* CAPTURA OS VALORES */
                P_NUNOTA    := EVP_GET_CAMPO_INT(P_IDSESSAO, 'NUNOTA');
                P_SITUACAO  := EVP_GET_CAMPO_TEXTO(P_IDSESSAO, 'SITUACAO');
                P_TOP       := EVP_GET_CAMPO_INT(P_IDSESSAO, 'CODTIPOPER'); 

                IF P_TOP NOT IN (1000) THEN
                    
                    IF NOT P_SITUACAO = 'FATURADO' THEN
                                    
                    --PKG_FATURAMENTOAUTOMATICO.FATURAPELOESTOQUE(P_NUNOTA, v_resultado_faturamento, v_msg_resposta_faturamento_automatico); -- Se todas estiverm concluidas, fatura
                    -- Atualiza a tabela AD_PEDIDOSFATURAR.
                    
                     SEND_NOTIFICATION(0, NULL, 'Evento Faturamento Automático '  || p_NUNOTA, 'SITUACAO: ' || P_SITUACAO || ' TOP: ' || P_TOP , 2);
                     COMMIT;   

                    END IF;
                
                END IF;

                
                
                
                
            END;
            
            
            SEND_NOTIFICATION(68, NULL, 'Evento Faturamento Automático ', 'cHEGOU AQUI' , -1);
            COMMIT; 
            
            
       END IF;

/*     IF P_TIPOEVENTO = BEFORE_DELETE THEN
             --DESCOMENTE ESTE BLOCO PARA PROGRAMAR O "BEFORE DELETE"
       END IF;*/
/*     IF P_TIPOEVENTO = AFTER_DELETE THEN
             --DESCOMENTE ESTE BLOCO PARA PROGRAMAR O "AFTER DELETE"
       END IF;*/

/*     IF P_TIPOEVENTO = BEFORE_UPDATE THEN
             --DESCOMENTE ESTE BLOCO PARA PROGRAMAR O "BEFORE UPDATE"
       END IF;*/
/*     IF P_TIPOEVENTO = AFTER_UPDATE THEN
             --DESCOMENTE ESTE BLOCO PARA PROGRAMAR O "AFTER UPDATE"
       END IF;*/

/*     IF P_TIPOEVENTO = BEFORE_COMMIT THEN
             --DESCOMENTE ESTE BLOCO PARA PROGRAMAR O "BEFORE COMMIT"
       END IF;*/

END;
/