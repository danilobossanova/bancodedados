CREATE OR REPLACE PROCEDURE SANKHYA."STP_RECONTAGEM_DIV_DCCO" (
       P_CODUSU NUMBER,        -- C�digo do usu�rio logado
       P_IDSESSAO VARCHAR2,    -- Identificador da execu��o. Serve para buscar informa��es dos par�metros/campos da execu��o.
       P_QTDLINHAS NUMBER,     -- Informa a quantidade de registros selecionados no momento da execu��o.
       P_MENSAGEM OUT VARCHAR2 -- Caso seja passada uma mensagem aqui, ela ser� exibida como uma informa��o ao usu�rio.
) AS
       PARAM_NUIVT NUMBER;
       FIELD_NUIVT NUMBER;
       FIELD_SEQUENCIA NUMBER;
       
       P_RETORNO VARCHAR2(3000);
       
BEGIN

       

       PARAM_NUIVT := ACT_INT_PARAM(P_IDSESSAO, 'NUIVT');


        /* Verifica se Inventario existe e esta aberto */
        
        
       PR_GERAR_TAREFAS_DIVERGENCIA(P_NUIVT, P_RETORNO);
       COMMIT;    


        P_MENSAGEM := P_RETORNO;
        

END;
/