CREATE OR REPLACE TRIGGER SANKHYA.TRG_AFR_UPD_TGWSEP
   AFTER UPDATE
   ON SANKHYA.TGWSEP
   FOR EACH ROW
DECLARE
   
   v_situacao    					CHAR(1);
   v_separation_count      			NUMBER(10);
   v_incomplete_separation_count 	NUMBER(10);
   v_notification_message  			VARCHAR2(3000); -- Mensagem de notifica��o para faturamento
   v_user_id     					INT;            -- ID do usu�rio que receber� a notifica��o
   
   P_RESULTADO                      BOOLEAN;
  

  PRAGMA AUTONOMOUS_TRANSACTION;
   
BEGIN


   IF stp_get_atualizando THEN
      RETURN;
   END IF;

   /******************************************************************************
   * CRIADO POR: YURI MESAK PEREIRA 17/05/2023
   * SOLICITANTE: LEONI
   * MOTIVO: TRIGGER QUE ENVIA MENSAGEM AO VENDEDOR PARA A CONFIRMA��O DA NOTA.
   *******************************************************************************/
  
   -- REFEITA POR YURI MESAK 19/12/2023, DEVIDO � MUDAN�A NO PROCESSO DE SEPARA��O, QUE AGORA GERA DUAS FICHAS (WMS E VLM)
   
   /********************************************************************************************************************
   
				REFATORADO POR DANILO FERNANDO EM 21/08/2024 --- USADO NO FATURAMENTO AUTOMATICO
				
				Situacao = 5 --> Conferencia validada
				Situacao = 6 --> Conclu�da
				
   *********************************************************************************************************************/
   
  
   -- Verifica se a nota est� presente em TGWSXN e conta quantas vezes aparece
   SELECT NVL(COUNT(1), 0)
     INTO v_separation_count
     FROM TGWSXN sxn 
     INNER JOIN TGFCAB cab ON cab.nunota = sxn.nunota
    WHERE sxn.nunota = :NEW.nunota OR sxn.nunota = :OLD.nunota;

   IF v_separation_count >= 2 THEN
       
       -- Verifica se existem separa��es incompletas (situa��es diferentes de 5 e 6)
       SELECT NVL(COUNT(1), 0)
         INTO v_incomplete_separation_count
         FROM TGWSXN sxn 
         INNER JOIN TGWSEP sep ON sep.nuseparacao = sxn.nuseparacao
         INNER JOIN TGFCAB cab ON cab.nunota = sxn.nunota
        WHERE (sxn.nunota = :NEW.nunota OR sxn.nunota = :OLD.nunota)
          AND (sep.situacao <> '5' AND sep.situacao <> '6');
       
       IF UPDATING('SITUACAO') THEN
       
           IF NVL(v_incomplete_separation_count, 0) = 0 THEN
               
               -- Verifica se existe pelo menos uma separa��o v�lida
               SELECT NVL(COUNT(1), 0)
                 INTO v_separation_count
                 FROM TGWSXN sxn 
                 INNER JOIN TGFCAB cab ON cab.nunota = sxn.nunota
                WHERE sxn.nuseparacao = :NEW.nuseparacao OR sxn.nuseparacao = :OLD.nuseparacao
                  AND ROWNUM = 1;

               IF NVL(v_separation_count, 0) >= 1 THEN
               
                   -- Chama a procedure de faturamento ap�s todas as fichas estarem conclu�das
                    PKG_FATURAMENTOAUTOMATICO.FATURAPELOESTOQUE(:NEW.nunota,P_RESULTADO);

                    --v_notification_message := '1 SEP__P_Resultado: ';

                /*send_aviso2(68, v_notification_message , '', 1);
                commit;*/   
                    
                    IF P_RESULTADO = TRUE THEN
                    
                        SELECT 'O PEDIDO N� UNICO: ' || NVL(CAB.NUNOTA,0) || ' FOI SEPARADO, CONFERIDO E FATURADO COM SUCESSO!',
                        NVL(CAB.CODUSU,0)
                        INTO v_notification_message, v_user_id
                         FROM TGWSXN sxn 
                         INNER JOIN TGFCAB cab ON cab.nunota = sxn.nunota
                        WHERE sxn.nuseparacao = :NEW.nuseparacao AND ROWNUM = 1;
                    
                    ELSE

                        SELECT 'A CONFER�NCIA DO N� �NICO: ' || NVL(cab.nunota, 0) || ' FOI CONCLU�DA, PODE SEGUIR COM O FATURAMENTO.',
                              NVL(cab.codusu, 0)
                         INTO v_notification_message, v_user_id
                         FROM TGWSXN sxn 
                         INNER JOIN TGFCAB cab ON cab.nunota = sxn.nunota
                        WHERE sxn.nuseparacao = :NEW.nuseparacao AND ROWNUM = 1;

                    END IF;
                    

                   -- Envia a notifica��o para o usu�rio respons�vel
                   IF NVL(v_user_id, 0) > 0 THEN
                       send_aviso2(v_user_id, v_notification_message, '', 0);
                       send_aviso2(v_user_id, v_notification_message, '', 1);
                       send_aviso2(68, v_notification_message, '', 1); -- Notifica um usu�rio adicional
                       COMMIT;
  
                   END IF;
               END IF;
               
           ELSE
               
               -- Notifica o conferente que h� fichas pendentes
               
               SELECT 'O PEDIDO DE N� �NICO: ' || NVL(cab.nunota, 0) || ' AINDA POSSUI SEPARA��ES PENDENTES.',
                      NVL(cab.codusu, 0)
                 INTO v_notification_message, v_user_id
                 FROM TGWSXN sxn 
                 INNER JOIN TGFCAB cab ON cab.nunota = sxn.nunota
                WHERE sxn.nuseparacao = :NEW.nuseparacao AND ROWNUM = 1;

               IF NVL(v_user_id, 0) > 0 THEN
               
                   send_aviso2(v_user_id, v_notification_message, '', 0);
                   send_aviso2(v_user_id, v_notification_message, '', 1);
                   send_aviso2(68, v_notification_message, '', 1); -- Notifica um usu�rio adicional
                   COMMIT;
                   
               END IF;
           END IF;
       END IF;

   ELSIF v_separation_count = 1 THEN
       
	   -- Se houver apenas uma separa��o e a situa��o mudou para 5 (Conclu�da)
       IF UPDATING('SITUACAO') AND :NEW.situacao = '5' AND :OLD.situacao <> '5' THEN
	   
           SELECT NVL(COUNT(1), 0)
             INTO v_separation_count
             FROM TGWSXN sxn 
             INNER JOIN TGFCAB cab ON cab.nunota = sxn.nunota
            WHERE sxn.nuseparacao = :NEW.nuseparacao OR sxn.nuseparacao = :OLD.nuseparacao
              AND ROWNUM = 1;

           IF NVL(v_separation_count, 0) >= 1 THEN
		   
               -- Cria a mensagem de notifica��o para faturamento
           
                -- Chama a procedure de faturamento ap�s todas as fichas estarem conclu�das
                PKG_FATURAMENTOAUTOMATICO.FATURAPELOESTOQUE(:NEW.nunota,P_RESULTADO);

                /*v_notification_message := '2 SEP__P_Resultado: ' ||  P_RESULTADO;

                send_aviso2(68, v_notification_message , '', 1);
                commit;*/

                IF P_RESULTADO = TRUE THEN
                
                    SELECT 'O PEDIDO N� UNICO: ' || NVL(CAB.NUNOTA,0) || ' FOI SEPARADO, CONFERIDO E FATURADO COM SUCESSO!',
                    NVL(CAB.CODUSU,0)
                    INTO v_notification_message, v_user_id
                     FROM TGWSXN sxn 
                     INNER JOIN TGFCAB cab ON cab.nunota = sxn.nunota
                    WHERE sxn.nuseparacao = :NEW.nuseparacao AND ROWNUM = 1;
                
                ELSE

                    SELECT 'A CONFER�NCIA DO N� �NICO: ' || NVL(cab.nunota, 0) || ' FOI CONCLU�DA, PODE SEGUIR COM O FATURAMENTO.',
                          NVL(cab.codusu, 0)
                     INTO v_notification_message, v_user_id
                     FROM TGWSXN sxn 
                     INNER JOIN TGFCAB cab ON cab.nunota = sxn.nunota
                    WHERE sxn.nuseparacao = :NEW.nuseparacao AND ROWNUM = 1;

                END IF;
                
               -- Envia a notifica��o para o usu�rio respons�vel
               IF NVL(v_user_id, 0) > 0 THEN
               
                   send_aviso2(v_user_id, v_notification_message, '', 0);
                   send_aviso2(v_user_id, v_notification_message, '', 1);
				   
                   send_aviso2(68, v_notification_message, '', 1); -- Notifica um usu�rio adicional
                   COMMIT;

                   
				   
               END IF;
           END IF;
       END IF;
   END IF;
END;
/