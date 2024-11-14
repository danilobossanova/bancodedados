CREATE OR REPLACE PROCEDURE SANKHYA."STP_GERUXT_RECONTAGEM_DCCO" (
       P_CODUSU NUMBER,        -- C�digo do usu�rio logado
       P_IDSESSAO VARCHAR2,    -- Identificador da execu��o. Serve para buscar informa��es dos par�metros/campos da execu��o.
       P_QTDLINHAS NUMBER,     -- Informa a quantidade de registros selecionados no momento da execu��o.
       P_MENSAGEM OUT VARCHAR2 -- Caso seja passada uma mensagem aqui, ela ser� exibida como uma informa��o ao usu�rio.
) AS
    PARAM_NUIVT NUMBER;
    FIELD_NUIVT NUMBER;
    FIELD_SEQUENCIA NUMBER;
    v_count NUMBER;
    v_situacao VARCHAR2(20);
    v_nome_usuario VARCHAR2(100);
    
BEGIN
    
    -- Inicializa a mensagem
    P_MENSAGEM := NULL;
    
    
    -- Recupera o n�mero do invent�rio do par�metro
    BEGIN
        PARAM_NUIVT := ACT_INT_PARAM(P_IDSESSAO, 'NUIVT');
        
        IF PARAM_NUIVT IS NULL THEN
            RAISE_APPLICATION_ERROR(-20103, 'N�mero do invent�rio n�o informado.');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20104, 'Erro ao recuperar par�metro NUIVT: ' || SQLERRM);
    END;
    
   
    
    -- Verifica se o invent�rio existe e est� aberto
    BEGIN
        SELECT COUNT(*),
               MAX(CASE WHEN DTFINAL IS NULL THEN 'Aberto' ELSE 'Fechado' END)
        INTO v_count, v_situacao
        FROM TGWIVT
        WHERE NUIVT = PARAM_NUIVT;
        
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20107, 'Invent�rio ' || PARAM_NUIVT || ' n�o encontrado.');
        END IF;
        
        IF v_situacao != 'Aberto' THEN
            RAISE_APPLICATION_ERROR(-20108, 'Invent�rio ' || PARAM_NUIVT || ' n�o est� aberto. Situa��o atual: ' || v_situacao);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20109, 'Erro ao verificar situa��o do invent�rio: ' || SQLERRM);
    END;
    
    -- Chama a procedure de designa��o de inventariantes
    BEGIN
        STP_DESIGNA_INVENTARIANTES(PARAM_NUIVT, P_MENSAGEM);
        
        -- Se a mensagem retornada indicar erro, converte para exception
        IF P_MENSAGEM LIKE 'Erro%' THEN
            RAISE_APPLICATION_ERROR(-20110, P_MENSAGEM);
        END IF;
        
        -- Adiciona informa��es complementares � mensagem de sucesso
        P_MENSAGEM := 'Processo executado com sucesso por ' || v_nome_usuario || 
                      ' em ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || 
                      CHR(10) || P_MENSAGEM;
                      
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20111, 'Erro na designa��o de inventariantes: ' || SQLERRM);
    END;

EXCEPTION
    WHEN OTHERS THEN
        -- Retorna a mensagem de erro para o usu�rio
        P_MENSAGEM := 'Erro na execu��o do processo: ' || SQLERRM;
END;

/