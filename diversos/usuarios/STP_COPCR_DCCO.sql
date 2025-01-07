/**
 * Procedure de ação customizada para copiar Centros de Resultados entre usuários.
 *
 * @author Danilo Bossanova <danilo.bossanova@hotmail.com>
 * @version 1.0
 * @created 07/01/2025 13:23
 *
 * @param P_CODUSU Código do usuário logado que está executando a ação
 * @param P_IDSESSAO Identificador da sessão para recuperar parâmetros
 * @param P_QTDLINHAS Quantidade de registros selecionados
 * @param P_MENSAGEM Mensagem de retorno para o usuário
 */
CREATE OR REPLACE PROCEDURE SANKHYA."STP_COPCR_DCCO" (
       P_CODUSU NUMBER,        -- Código do usuário logado
       P_IDSESSAO VARCHAR2,    -- Identificador da execução. Serve para buscar informações dos parâmetros/campos da execução.
       P_QTDLINHAS NUMBER,     -- Informa a quantidade de registros selecionados no momento da execução.
       P_MENSAGEM OUT VARCHAR2 -- Caso seja passada uma mensagem aqui, ela será exibida como uma informação ao usuário.
) AS
        v_usuario_origem  NUMBER;
    v_usuario_destino NUMBER;
    v_status         NUMBER;
BEGIN
    -- Obtém os parâmetros da tela
    v_usuario_origem := TO_NUMBER(ACT_TXT_PARAM(P_IDSESSAO, 'USUORIGEM'));
    v_usuario_destino := TO_NUMBER(ACT_TXT_PARAM(P_IDSESSAO, 'USUDESTINO'));
    
    -- Chama a procedure de cópia
    COPIAR_USUARIO_CR(
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
        
END STP_COPCR_DCCO;
/