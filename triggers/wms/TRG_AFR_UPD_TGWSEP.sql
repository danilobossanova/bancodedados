DROP TRIGGER SANKHYA.TRG_AFR_UPD_TGWSEP;

CREATE OR REPLACE TRIGGER SANKHYA.TRG_AFR_UPD_TGWSEP
   AFTER UPDATE
   ON SANKHYA.TGWSEP
   FOR EACH ROW
DECLARE
   v_situacao    CHAR(1);
   v_separation_count      NUMBER(10);
   v_incomplete_separation_count NUMBER(10);
   v_notification_message  VARCHAR2(3000); -- Mensagem de notificação para faturamento
   v_user_id     INT;                      -- ID do usuário que receberá a notificação
   PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN

   IF stp_get_atualizando THEN
      RETURN;
   END IF;

   /******************************************************************************
   * CRIADO POR: YURI MESAK PEREIRA 17/05/2023
   * SOLICITANTE: LEONI
   * MOTIVO: TRIGGER QUE ENVIA MENSAGEM AO VENDEDOR PARA A CONFIRMAÇÃO DA NOTA.
   
   *  OBSERVAÇÃO: Refatorado por Danilo Fernando em 21/08/2024.
   
   *******************************************************************************/
  
   -- REFEITA POR YURI MESAK 19/12/2023, DEVIDO À MUDANÇA NO PROCESSO DE SEPARAÇÃO, QUE AGORA GERA DUAS FICHAS (WMS E VLM)
  
   -- Verifica se a nota está presente em TGWSXN e conta quantas vezes aparece
   SELECT NVL(COUNT(1), 0)
     INTO v_separation_count
     FROM TGWSXN sxn 
     INNER JOIN TGFCAB cab ON cab.nunota = sxn.nunota
    WHERE sxn.nunota = :NEW.nunota OR sxn.nunota = :OLD.nunota;

	-- SITUACAO = 5 --> Conferencia Validada
	-- SITUACAO = 6 --> Concluida [Doca Liberada

	-- Se houver mais de 1 separação para o pedido

   IF v_separation_count >= 2 THEN
       -- Verifica se existem separações incompletas (situações diferentes de 5 e 6)
       SELECT NVL(COUNT(1), 0)
         INTO v_incomplete_separation_count
         FROM TGWSXN sxn 
         INNER JOIN TGWSEP sep ON sep.nuseparacao = sxn.nuseparacao
         INNER JOIN TGFCAB cab ON cab.nunota = sxn.nunota
        WHERE (sxn.nunota = :NEW.nunota OR sxn.nunota = :OLD.nunota)
          AND (sep.situacao <> '5' AND sep.situacao <> '6');
		  
       -- Verifica se esta atualizado a situacao da Separacao e senão existe separações pendentes
       IF UPDATING('SITUACAO') AND NVL(v_incomplete_separation_count, 0) = 0 THEN
	   
           -- Verifica se existe pelo menos uma separação válida
           SELECT NVL(COUNT(1), 0)
             INTO v_separation_count
             FROM TGWSXN sxn 
             INNER JOIN TGFCAB cab ON cab.nunota = sxn.nunota
            WHERE sxn.nuseparacao = :NEW.nuseparacao OR sxn.nuseparacao = :OLD.nuseparacao
              AND ROWNUM = 1;

           IF NVL(v_separation_count, 0) >= 1 THEN
               -- Cria a mensagem de notificação
               SELECT 'A CONFERÊNCIA DO Nº ÚNICO: ' || NVL(cab.nunota, 0) || ' FOI CONCLUÍDA, PODE SEGUIR COM O FATURAMENTO.',
                      NVL(cab.codus_u, 0)
                 INTO v_notification_message, v_user_id
                 FROM TGWSXN sxn 
                 INNER JOIN TGFCAB cab ON cab.nunota = sxn.nunota
                WHERE sxn.nuseparacao = :NEW.nuseparacao AND ROWNUM = 1;

               -- Envia a notificação para o usuário responsável
               IF NVL(v_user_id, 0) > 0 THEN
                   send_aviso2(v_user_id, v_notification_message, '', 0);
                   send_aviso2(v_user_id, v_notification_message, '', 1);
                   send_aviso2(324, v_notification_message, '', 1); -- Notifica um usuário adicional
                   COMMIT;
               END IF;
           END IF;
       END IF;


	-- Se houver apenas 1 separação para o pedido

   ELSIF v_separation_count = 1 THEN
       -- Se houver apenas uma separação e a situação mudou para 5 (Conferencia validada)
       IF UPDATING('SITUACAO') AND :NEW.situacao = '5' AND :OLD.situacao <> '5' THEN
           -- Verifica se existe pelo menos uma separação válida
           SELECT NVL(COUNT(1), 0)
             INTO v_separation_count
             FROM TGWSXN sxn 
             INNER JOIN TGFCAB cab ON cab.nunota = sxn.nunota
            WHERE sxn.nuseparacao = :NEW.nuseparacao OR sxn.nuseparacao = :OLD.nuseparacao
              AND ROWNUM = 1;

           IF NVL(v_separation_count, 0) >= 1 THEN
               -- Cria a mensagem de notificação
               SELECT 'A CONFERÊNCIA DO Nº ÚNICO: ' || NVL(cab.nunota, 0) || ' FOI CONCLUÍDA, PODE SEGUIR COM O FATURAMENTO.',
                      NVL(cab.codus_u, 0)
                 INTO v_notification_message, v_user_id
                 FROM TGWSXN sxn 
                 INNER JOIN TGFCAB cab ON cab.nunota = sxn.nunota
                WHERE sxn.nuseparacao = :NEW.nuseparacao AND ROWNUM = 1;

               -- Envia a notificação para o usuário responsável
               IF NVL(v_user_id, 0) > 0 THEN
                   send_aviso2(v_user_id, v_notification_message, '', 0);
                   send_aviso2(v_user_id, v_notification_message, '', 1);
                   send_aviso2(324, v_notification_message, '', 1); -- Notifica um usuário adicional
                   COMMIT;
               END IF;
           END IF;
       END IF;
   END IF;
END;
/
