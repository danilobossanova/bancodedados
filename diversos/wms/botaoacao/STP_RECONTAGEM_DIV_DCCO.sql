CREATE OR REPLACE PROCEDURE SANKHYA."STP_RECONTAGEM_DIV_DCCO" (
       P_CODUSU NUMBER,        -- Código do usuário logado
       P_IDSESSAO VARCHAR2,    -- Identificador da execução. Serve para buscar informações dos parâmetros/campos da execução.
       P_QTDLINHAS NUMBER,     -- Informa a quantidade de registros selecionados no momento da execução.
       P_MENSAGEM OUT VARCHAR2 -- Caso seja passada uma mensagem aqui, ela será exibida como uma informação ao usuário.
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