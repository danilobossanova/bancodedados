CREATE OR REPLACE PROCEDURE SANKHYA."STP_COPIAEMPLIB_DCCO" (
       P_CODUSU NUMBER,        -- Código do usuário logado
       P_IDSESSAO VARCHAR2,    -- Identificador da execução. Serve para buscar informações dos parâmetros/campos da execução.
       P_QTDLINHAS NUMBER,     -- Informa a quantidade de registros selecionados no momento da execução.
       P_MENSAGEM OUT VARCHAR2 -- Caso seja passada uma mensagem aqui, ela será exibida como uma informação ao usuário.
) AS
       PARAM_USUDESTINO VARCHAR2(4000);
       PARAM_USUORIGEM VARCHAR2(4000);
       
        v_usuario_origem  NUMBER;
        v_usuario_destino NUMBER;
        v_status         NUMBER;
        
BEGIN

      -- Obtém os parâmetros da tela
        v_usuario_origem := TO_NUMBER(ACT_TXT_PARAM(P_IDSESSAO, 'USUORIGEM'));
        v_usuario_destino := TO_NUMBER(ACT_TXT_PARAM(P_IDSESSAO, 'USUDESTINO'));

      
        -- Chama a procedure de cópia
        COPIAR_USULIBEMP(
            p_usuario_origem  => v_usuario_origem,
            p_usuario_destino => v_usuario_destino,
            p_mensagem       => P_MENSAGEM,
            p_status        => v_status
        );
        
        -- Se houver erro, levanta exceção para o Sankhya tratar
        IF v_status = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, P_MENSAGEM);
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Em caso de outro erro, propaga a mensagem
            P_MENSAGEM := SQLERRM;
            RAISE;

END STP_COPIAEMPLIB_DCCO;
/