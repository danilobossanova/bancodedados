CREATE OR REPLACE PROCEDURE SANKHYA."STP_GERUXT_RECONTAGEM_DCCO" (
       P_CODUSU NUMBER,        -- Código do usuário logado
       P_IDSESSAO VARCHAR2,    -- Identificador da execução. Serve para buscar informações dos parâmetros/campos da execução.
       P_QTDLINHAS NUMBER,     -- Informa a quantidade de registros selecionados no momento da execução.
       P_MENSAGEM OUT VARCHAR2 -- Caso seja passada uma mensagem aqui, ela será exibida como uma informação ao usuário.
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
    
    
    -- Recupera o número do inventário do parâmetro
    BEGIN
        PARAM_NUIVT := ACT_INT_PARAM(P_IDSESSAO, 'NUIVT');
        
        IF PARAM_NUIVT IS NULL THEN
            RAISE_APPLICATION_ERROR(-20103, 'Número do inventário não informado.');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20104, 'Erro ao recuperar parâmetro NUIVT: ' || SQLERRM);
    END;
    
   
    
    -- Verifica se o inventário existe e está aberto
    BEGIN
        SELECT COUNT(*),
               MAX(CASE WHEN DTFINAL IS NULL THEN 'Aberto' ELSE 'Fechado' END)
        INTO v_count, v_situacao
        FROM TGWIVT
        WHERE NUIVT = PARAM_NUIVT;
        
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20107, 'Inventário ' || PARAM_NUIVT || ' não encontrado.');
        END IF;
        
        IF v_situacao != 'Aberto' THEN
            RAISE_APPLICATION_ERROR(-20108, 'Inventário ' || PARAM_NUIVT || ' não está aberto. Situação atual: ' || v_situacao);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20109, 'Erro ao verificar situação do inventário: ' || SQLERRM);
    END;
    
    -- Chama a procedure de designação de inventariantes
    BEGIN
        STP_DESIGNA_INVENTARIANTES(PARAM_NUIVT, P_MENSAGEM);
        
        -- Se a mensagem retornada indicar erro, converte para exception
        IF P_MENSAGEM LIKE 'Erro%' THEN
            RAISE_APPLICATION_ERROR(-20110, P_MENSAGEM);
        END IF;
        
        -- Adiciona informações complementares à mensagem de sucesso
        P_MENSAGEM := 'Processo executado com sucesso por ' || v_nome_usuario || 
                      ' em ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || 
                      CHR(10) || P_MENSAGEM;
                      
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20111, 'Erro na designação de inventariantes: ' || SQLERRM);
    END;

EXCEPTION
    WHEN OTHERS THEN
        -- Retorna a mensagem de erro para o usuário
        P_MENSAGEM := 'Erro na execução do processo: ' || SQLERRM;
END;

/