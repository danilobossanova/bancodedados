/**
 * Procedure de a��o customizada para copiar Centros de Resultados entre usu�rios.
 *
 * @author Danilo Bossanova <danilo.bossanova@hotmail.com>
 * @version 1.0
 * @created 07/01/2025 13:23
 *
 * @param P_CODUSU C�digo do usu�rio logado que est� executando a a��o
 * @param P_IDSESSAO Identificador da sess�o para recuperar par�metros
 * @param P_QTDLINHAS Quantidade de registros selecionados
 * @param P_MENSAGEM Mensagem de retorno para o usu�rio
 */
CREATE OR REPLACE PROCEDURE SANKHYA."STP_COPCR_DCCO" (
       P_CODUSU NUMBER,        -- C�digo do usu�rio logado
       P_IDSESSAO VARCHAR2,    -- Identificador da execu��o. Serve para buscar informa��es dos par�metros/campos da execu��o.
       P_QTDLINHAS NUMBER,     -- Informa a quantidade de registros selecionados no momento da execu��o.
       P_MENSAGEM OUT VARCHAR2 -- Caso seja passada uma mensagem aqui, ela ser� exibida como uma informa��o ao usu�rio.
) AS
        v_usuario_origem  NUMBER;
    v_usuario_destino NUMBER;
    v_status         NUMBER;
BEGIN
    -- Obt�m os par�metros da tela
    v_usuario_origem := TO_NUMBER(ACT_TXT_PARAM(P_IDSESSAO, 'USUORIGEM'));
    v_usuario_destino := TO_NUMBER(ACT_TXT_PARAM(P_IDSESSAO, 'USUDESTINO'));
    
    -- Chama a procedure de c�pia
    COPIAR_USUARIO_CR(
        p_usuario_origem  => v_usuario_origem,
        p_usuario_destino => v_usuario_destino,
        p_mensagem       => P_MENSAGEM,
        p_status        => v_status
    );
    
    -- Se houver erro, levanta exce��o para o Sankhya tratar
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