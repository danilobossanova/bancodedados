CREATE OR REPLACE procedure SANKHYA.STP_DUPLICA_PEDIDO(
                  P_NUNOTAORIGEM INT, -- NUNOTA DE ORIGEM
                  P_TOPDESTINO   INT  -- NUMERO DA NOVA TOP
) AS


  P_NOVA_DHTIPOPER TGFTOP.DHALTER%TYPE;
  P_NOVO_NUNOTA    TGFCAB.NUNOTA%TYPE;

  I_JA_INSERIDO INT :=0;
  NUMNONTA_ORIGEM   TGFCAB.NUMNOTA%TYPE;
  CODEMP_ORIGEM     TGFCAB.CODEMP%TYPE;
  DHTIPOPER_ORIGEM TGFCAB.DHTIPOPER%TYPE;
  CODPARC_ORIGEM   TGFCAB.CODPARC%TYPE;

begin
  
       /*******************************************************************************

       @Autor: Danilo Fernando <danilo.fernando@grupocopar.com.br>
       @Data: 03/09/2021
       @Ao Som de: Tom Walker - Leave a Light On
       @Solicitante: Controladoria - Chamado #0003 - 01/09/2021
       @Objetivo:
       
       Duplica Pedido e itens do pedido com nova TOP.

       ********************************************************************************/



       --RAISE_APPLICATION_ERROR(-20101,'NOTA ORIGEM: ' || P_NUNOTAORIGEM );
       --RAISE_APPLICATION_ERROR(-20101,'TOP DESTINO: ' || P_TOPDESTINO );

       IF P_NUNOTAORIGEM IS NOT NULL THEN

           /********************************************************************************************
                VALIDAR PARA IMPEDIR QUE SEJAM FEITOS MAIS DE UMA ENTRADA
          *********************************************************************************************/

            SELECT CAB.NUMNOTA, CAB.CODEMP, CAB.DHTIPOPER, CAB.CODPARC
              INTO NUMNONTA_ORIGEM, CODEMP_ORIGEM,DHTIPOPER_ORIGEM, CODPARC_ORIGEM
            FROM TGFCAB CAB WHERE CAB.NUNOTA = P_NUNOTAORIGEM;


            SELECT  COUNT(1) INTO I_JA_INSERIDO FROM TGFCAB CAB
            WHERE CAB.NUMNOTA = NUMNONTA_ORIGEM AND CAB.CODEMP = CODEMP_ORIGEM AND CAB.CODTIPOPER = P_TOPDESTINO
            AND CAB.CODPARC = CODPARC_ORIGEM;

            /*******************************************************************************************/

            IF I_JA_INSERIDO > 0 THEN

              RETURN;

            ELSE


                 -- PEGA DATA HORA DA TOP
                 SELECT MAX(DHALTER) INTO P_NOVA_DHTIPOPER FROM TGFTOP WHERE CODTIPOPER = P_TOPDESTINO;

                 --RAISE_APPLICATION_ERROR(-20101,'DHALTER: ' || P_NOVA_DHTIPOPER );

                 -- GERA NOVA CHAVE PRA CAB
                 Stp_OBTEMID('TGFCAB',P_NOVO_NUNOTA);

                -- iNSERT NA CAB
                INSERT INTO TGFCAB

                (
                  NUNOTA,
                   NUMNOTA,
                   DTNEG,
                   TIPMOV,
                   VLRNOTA,

                   CODPARC,
                   CODVEND,

                   CODEMP,
                   CODCENCUS,
                   SERIENOTA,
                   DTFATUR,
                   DTENTSAI,
                   DTVAL,
                   DTMOV,
                   DTCONTAB,

                   HRMOV,
                   CODEMPNEGOC,
                   CODCONTATO,
                   RATEADO,
                   CODVEICULO,
                   CODTIPOPER,
                   DHTIPOPER,

                   CODTIPVENDA,
                   DHTIPVENDA,
                   NUMCOTACAO,
                   COMISSAO,
                   CODMOEDA,
                   CODOBSPADRAO,

                   OBSERVACAO,
                   VLRSEG,
                   VLRICMSSEG,
                   VLRDESTAQUE,
                   VLRJURO,
                   VLRVENDOR,
                   VLROUTROS,

                   VLREMB,
                   VLRICMSEMB,
                   VLRDESCSERV,
                   IPIEMB,
                   TIPIPIEMB,
                   VLRDESCTOT,
                   VLRDESCTOTITEM,

                   VLRFRETE,
                   ICMSFRETE,
                   BASEICMSFRETE,
                   TIPFRETE,
                   CIF_FOB,
                   VENCFRETE,
                   VENCIPI,
                   ORDEMCARGA,

                   SEQCARGA,
                   KMVEICULO,
                   CODPARCTRANSP,
                   QTDVOL,
                   PENDENTE,
                   BASEICMS,
                   VLRICMS,
                   BASEIPI,

                   VLRIPI,
                   ISSRETIDO,
                   BASEISS,
                   VLRISS,
                   APROVADO,
                   STATUSNOTA,
                   IRFRETIDO,
                   COMGER,
                   VLRIRF,

                   DTALTER,
                   VOLUME,
                   CODPARCDEST,
                   VLRSUBST,
                   BASESUBSTIT,
                   CODPROJ,
                   NUMCONTRATO,
                   BASEINSS,

                   VLRINSS,
                   VLRREPREDTOT,
                   PERCDESC,
                   CODPARCREMETENTE,
                   CODPARCCONSIGNATARIO,

                   CODPARCREDESPACHO,
                   LOCALCOLETA,
                   LOCALENTREGA,
                   VLRMERCADORIA,
                   PESO,
                   NOTASCF,

                   CODNAT,
                   CODUSU,
                   NROREDZ,
                   CODMAQ,
                   NUMALEATORIO,
                   NUMPROTOC,
                   DHPROTOC,
                   DANFE,

                   CHAVENFE,
                   DTENVIOPMB,
                   TIPNOTAPMB,
                   DTENVSUF,
                   NATUREZAOPERDES,
                   SERIENFDES,
                   MODELONFDES,
                   UFEMBARQ,
                   LOCEMBARQ,
                   NUMNFSE
               )

                  SELECT

                   P_NOVO_NUNOTA, -- Novo NUNOTA
                   NUMNOTA,
                   DTNEG,
                   TIPMOV,
                   VLRNOTA,

                   CODPARC,
                   CODVEND,

                   CODEMP,
                   CODCENCUS,
                   SERIENOTA,
                   DTFATUR,
                   DTENTSAI,
                   DTVAL,
                   DTMOV,
                   DTCONTAB,

                   HRMOV,
                   CODEMPNEGOC,
                   CODCONTATO,
                   RATEADO,
                   CODVEICULO,
                   P_TOPDESTINO     AS CODTIPOPER, -- TOP DE DESTINO
                   P_NOVA_DHTIPOPER as DHTIPOPER,  -- DATA ALTERACAO DA TOP DE DESTINO

                   CODTIPVENDA,
                   DHTIPVENDA,
                   NUMCOTACAO,
                   COMISSAO,
                   CODMOEDA,
                   CODOBSPADRAO,

                   OBSERVACAO || '    NU DUPLICADA AUTOMATICAMENTE' AS OBSERVACAO,
                   VLRSEG,
                   VLRICMSSEG,
                   VLRDESTAQUE,
                   VLRJURO,
                   VLRVENDOR,
                   VLROUTROS,

                   VLREMB,
                   VLRICMSEMB,
                   VLRDESCSERV,
                   IPIEMB,
                   TIPIPIEMB,
                   VLRDESCTOT,
                   VLRDESCTOTITEM,

                   VLRFRETE,
                   ICMSFRETE,
                   BASEICMSFRETE,
                   TIPFRETE,
                   CIF_FOB,
                   VENCFRETE,
                   VENCIPI,
                   ORDEMCARGA,

                   SEQCARGA,
                   KMVEICULO,
                   CODPARCTRANSP,
                   QTDVOL,
                   PENDENTE,
                   BASEICMS,
                   VLRICMS,
                   BASEIPI,

                   VLRIPI,
                   ISSRETIDO,
                   BASEISS,
                   VLRISS,
                   APROVADO,
                  'L',      ----> Marca como Aprovado a Nota
                   IRFRETIDO,
                   COMGER,
                   VLRIRF,

                   DTALTER,
                   VOLUME,
                   CODPARCDEST,
                   VLRSUBST,
                   BASESUBSTIT,
                   CODPROJ,
                   NUMCONTRATO,
                   BASEINSS,

                   VLRINSS,
                   VLRREPREDTOT,
                   PERCDESC,
                   CODPARCREMETENTE,
                   CODPARCCONSIGNATARIO,

                   CODPARCREDESPACHO,
                   LOCALCOLETA,
                   LOCALENTREGA,
                   VLRMERCADORIA,
                   PESO,
                   NOTASCF,

                   CODNAT,
                   CODUSU,
                   NROREDZ,
                   CODMAQ,
                   NUMALEATORIO,
                   NUMPROTOC,
                   DHPROTOC,
                   DANFE,

                   NULL,--CHAVENFE,
                   DTENVIOPMB,
                   TIPNOTAPMB,
                   DTENVSUF,
                   NATUREZAOPERDES,
                   SERIENFDES,
                   MODELONFDES,
                   UFEMBARQ,
                   LOCEMBARQ,
                   NUMNFSE

                    FROM TGFCAB
                   WHERE nunota = P_NUNOTAORIGEM;
                COMMIT;

                /*****************************************************************************/
                -- INSERT NA ITE
                INSERT INTO TGFITE
                  (NUTAB,
                   NUNOTA,
                   SEQUENCIA,
                   CODEMP,
                   CODPROD,
                   CODLOCALORIG,

                   CONTROLE,
                   USOPROD,
                   CODCFO,
                   QTDNEG,
                   QTDENTREGUE,
                   QTDCONFERIDA,
                   VLRUNIT,

                   VLRTOT,
                   VLRCUS,
                   BASEIPI,
                   VLRIPI,
                   BASEICMS,
                   VLRICMS,
                   VLRDESC,
                   BASESUBSTIT,

                   VLRSUBST,
                   ALIQICMS,
                   ALIQIPI,
                   PENDENTE,
                   CODVOL,
                   CODTRIB,
                   ATUALESTOQUE,

                   OBSERVACAO,
                   RESERVA,
                   STATUSNOTA,
                   CODOBSPADRAO,
                   CODVEND,
                   CODEXEC,
                   FATURAR,

                   PERCDESC)

                  SELECT

                   NUTAB,
                   P_NOVO_NUNOTA, --Novo NU
                   SEQUENCIA,
                   CODEMP,
                   CODPROD,
                   CODLOCALORIG,

                   CONTROLE,
                   USOPROD,
                   CODCFO,
                   QTDNEG,
                   QTDENTREGUE,
                   QTDCONFERIDA,
                   VLRUNIT,

                   VLRTOT,
                   VLRCUS,
                   BASEIPI,
                   VLRIPI,
                   BASEICMS,
                   VLRICMS,
                   VLRDESC,
                   BASESUBSTIT,

                   VLRSUBST,
                   ALIQICMS,
                   ALIQIPI,
                   PENDENTE,
                   CODVOL,
                   CODTRIB,
                   1,

                   OBSERVACAO,
                   RESERVA,
                   STATUSNOTA,
                   CODOBSPADRAO,
                   CODVEND,
                   CODEXEC,
                   FATURAR,

                   PERCDESC

                    FROM TGFITE
                   WHERE nunota = P_NUNOTAORIGEM;

                 COMMIT;
          END IF;

      END IF;

end STP_DUPLICA_PEDIDO;

/
