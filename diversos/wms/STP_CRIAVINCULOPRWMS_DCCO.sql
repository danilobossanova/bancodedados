CREATE OR REPLACE PROCEDURE SANKHYA."STP_CRIAVINCULOPRWMS_DCCO" (
       P_CODUSU NUMBER,        -- C�digo do usu�rio logado
       P_IDSESSAO VARCHAR2,    -- Identificador da execu��o. Serve para buscar informa��es dos par�metros/campos da execu��o.
       P_QTDLINHAS NUMBER,     -- Informa a quantidade de registros selecionados no momento da execu��o.
       P_MENSAGEM OUT VARCHAR2 -- Caso seja passada uma mensagem aqui, ela ser� exibida como uma informa��o ao usu�rio.
) AS
       
       FIELD_NUPRODSEMWMS   NUMBER;
       FIELD_NUIVT          NUMBER;
       FIELD_CODEMP         NUMBER;
       FIELD_CODPROD        NUMBER;
       FIELD_CODEND         NUMBER;
       --FIELD_DHCONTAGEM     DATE;
       FIELD_CODVOL         VARCHAR2(10);
       
       P_VINCULOOK          VARCHAR2(1);
       I_VINCULO_GERADO     INT := 0;
       I_JATEM_VINCULO      INT :=0;  
       
       
       
BEGIN

        /***********************************************************************
        * Author: Danilo Fernando <danilo.bossanova@hotmail.com>
        * Data: 16/04/2024 17:33
        * Ao som de:
        * Description: Gera vinculo para os produtos que foram inventariados e n�o
          possuem vinculo com o endere�o da contagem.
        ************************************************************************/


       FOR I IN 1..P_QTDLINHAS 
       LOOP 
     

           FIELD_NUPRODSEMWMS   := ACT_INT_FIELD(P_IDSESSAO, I, 'NUPRODSEMWMS');
           FIELD_NUIVT          := ACT_INT_FIELD(P_IDSESSAO, I, 'NUIVT');
           FIELD_CODEMP         := ACT_INT_FIELD(P_IDSESSAO, I, 'CODEMP');
           FIELD_CODPROD        := ACT_INT_FIELD(P_IDSESSAO, I, 'CODPROD');
           FIELD_CODEND         := ACT_INT_FIELD(P_IDSESSAO, I, 'CODEND');
           
           FIELD_CODVOL         := ACT_INT_FIELD(P_SESSAO, I, 'CODVOL'); 

            -- Verifica sen�o existe vinculo com o endere�o atual.
            STP_VER_VINCULOENDERECO_DCCO(FIELD_CODEND,FIELD_CODPROD, P_VINCULOOK);
            
            
            IF(P_VINCULOOK = 'S') THEN
            
                    -- Sen�o exitir vinculo, realiza o vinculo
                    Insert into TGWEXP(CODEND,
                                       CODPROD,
                                       ATIVO,
                                       DTINICIO,
                                       DTFIM, 
                                       ESTMIN,
                                       ESTMAX,
                                       CODVOL,
                                       ESTMINVOLPAD,
                                       ESTMAXVOLPAD, 
                                       ORDEM,
                                       CONTROLE
                                    )
                    Values(
                        FIELD_CODEND,                       -- CODEND
                        FIELD_CODPROD,                      -- CODPROD
                        'S',                                -- ATIVO
                        TO_DATE(SYSDATE, 'YYYY/MM/DD'),     -- DTINICIO
                        NULL,                               -- DTFIM
                        0,                                  -- ESTMIN
                        999,                                -- ESTMAX
                        FIELD_CODVOL,                       -- CODVOL
                        0,                                  -- ESTMINVOLDPAD
                        999,                                -- ESTMAXVOLPAD
                        NULL,                               -- ORDEM
                        ' '                                 -- CONTROLE
                    );
                    
                    COMMIT;
                    
                    I_VINCULO_GERADO := I_VINCULO_GERADO + 1;
            
            -- Informa que um vinculo novo foi gerado como resposta.
            
            ELSE
            
                I_JATEM_VINCULO := I_JATEM_VINCULO + 1;
            
            END IF;


       END LOOP;


    
        P_MENSAGEM := "Gerado vinculo para <b>" || I_VINCULO_GERADO || "<br> .<br>" || "<b>" || I_JATEM_VINCULO || "<b> Produto(s) j� poussem vinculo.";  


END;

/