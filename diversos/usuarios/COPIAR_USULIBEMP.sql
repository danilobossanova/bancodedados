/**
 * Procedimento respons�vel por copiar as libera��es de empresas de um usu�rio para outro.
 *
 * @author Danilo Fernando <danilo.bossanova@hotmail.com>
 * @version 1.0
 * @created 07/01/2025
*
 * @param p_usuario_origem C�digo do usu�rio de origem das libera��es
 * @param p_usuario_destino C�digo do usu�rio de destino que receber� as libera��es
 * @param p_mensagem Mensagem de retorno com o resultado da opera��o
 * @param p_status Status da opera��o (1 = Sucesso, 0 = Erro)
 */
CREATE OR REPLACE PROCEDURE COPIAR_USULIBEMP (
    p_usuario_origem   IN  NUMBER,
    p_usuario_destino  IN  NUMBER,
    p_mensagem        OUT VARCHAR2,
    p_status         OUT NUMBER
)
AS
    -- Constantes para mensagens
    c_erro_parametros    CONSTANT VARCHAR2(100) := 'Os par�metros de entrada n�o podem ser nulos.';
    c_erro_mesmo_usuario CONSTANT VARCHAR2(100) := 'Os usu�rios de origem e destino n�o podem ser iguais.';
    c_sucesso           CONSTANT NUMBER := 1;
    c_erro              CONSTANT NUMBER := 0;
    
    -- Cursor para obter os registros do usu�rio de origem
    CURSOR c_registros_origem IS
        SELECT CODEMP
          FROM AD_USULIBEMP
         WHERE CODUSU = p_usuario_origem;
         
    v_codemp  AD_USULIBEMP.CODEMP%TYPE;
    v_exists  NUMBER;
    v_count_inseridos NUMBER := 0;
    v_ultimo_nrreg NUMBER;
BEGIN
    -- Inicializa��o dos par�metros de sa�da
    p_status := c_erro;
    p_mensagem := NULL;

    -- Valida��o dos par�metros de entrada
    IF p_usuario_origem IS NULL OR p_usuario_destino IS NULL THEN
        p_mensagem := c_erro_parametros;
        RETURN;
    END IF;
    
    -- Valida��o para evitar c�pia para o mesmo usu�rio
    IF p_usuario_origem = p_usuario_destino THEN
        p_mensagem := c_erro_mesmo_usuario;
        RETURN;
    END IF;
    
    -- Obt�m o �ltimo NRREG do usu�rio destino
    SELECT NVL(MAX(NRREG), 0)
      INTO v_ultimo_nrreg
      FROM AD_USULIBEMP
     WHERE CODUSU = p_usuario_destino;
    
    -- Inicia transa��o
    SAVEPOINT inicio_copia;
    
    -- Itera��o sobre os registros do usu�rio de origem
    FOR r IN c_registros_origem LOOP
        -- Verifica��o de exist�ncia da libera��o para o usu�rio destino
        SELECT COUNT(*)
          INTO v_exists
          FROM AD_USULIBEMP
         WHERE CODUSU = p_usuario_destino
           AND CODEMP = r.CODEMP;
           
        -- Inser��o apenas se n�o existir
        IF v_exists = 0 THEN
            -- Incrementa o contador para o pr�ximo NRREG
            v_ultimo_nrreg := v_ultimo_nrreg + 1;
            
            INSERT INTO AD_USULIBEMP (NRREG, CODUSU, CODEMP)
            VALUES (
                v_ultimo_nrreg,
                p_usuario_destino,
                r.CODEMP
            );
            
            v_count_inseridos := v_count_inseridos + 1;
        END IF;
    END LOOP;
    
    -- Commit apenas se houver inser��es
    IF v_count_inseridos > 0 THEN
        COMMIT;
        p_mensagem := 'Foram copiadas ' || v_count_inseridos || 
            ' libera��es do usu�rio ' || p_usuario_origem || 
            ' para o usu�rio ' || p_usuario_destino;
        p_status := c_sucesso;
    ELSE
        p_mensagem := 'Nenhuma nova libera��o foi necess�ria para o usu�rio ' || 
            p_usuario_destino;
        p_status := c_sucesso;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Rollback em caso de erro
        ROLLBACK TO inicio_copia;
        -- Define mensagem e status de erro
        p_mensagem := 'Erro durante a c�pia das libera��es: ' || SQLERRM;
        p_status := c_erro;
END COPIAR_USULIBEMP;
/