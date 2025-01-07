/**
 * Procedimento responsável por copiar os Centros de Resultados de um usuário para outro.
 *
 * @author Danilo Fernando <danilo.fernando@grupocopar.com.br>
 * @version 1.0
 * @created 07/01/2025 13:16
 *
 * @param p_usuario_origem Código do usuário de origem dos CRs
 * @param p_usuario_destino Código do usuário de destino que receberá os CRs
 * @param p_mensagem Mensagem de retorno com o resultado da operação
 * @param p_status Status da operação (1 = Sucesso, 0 = Erro)
 */
CREATE OR REPLACE PROCEDURE COPIAR_USUARIO_CR (
    p_usuario_origem   IN  NUMBER,
    p_usuario_destino  IN  NUMBER,
    p_mensagem        OUT VARCHAR2,
    p_status         OUT NUMBER
)
AS
    -- Constantes para mensagens
    c_erro_parametros    CONSTANT VARCHAR2(100) := 'Os parâmetros de entrada não podem ser nulos.';
    c_erro_mesmo_usuario CONSTANT VARCHAR2(100) := 'Os usuários de origem e destino não podem ser iguais.';
    c_sucesso           CONSTANT NUMBER := 1;
    c_erro              CONSTANT NUMBER := 0;
    
    -- Cursor para obter os registros do usuário de origem
    CURSOR c_registros_origem IS
        SELECT CODCENCUS
          FROM AD_RESPCR
         WHERE CODUSU = p_usuario_origem;
         
    v_exists  NUMBER;
    v_count_inseridos NUMBER := 0;
BEGIN
    -- Inicialização dos parâmetros de saída
    p_status := c_erro;
    p_mensagem := NULL;

    -- Validação dos parâmetros de entrada
    IF p_usuario_origem IS NULL OR p_usuario_destino IS NULL THEN
        p_mensagem := c_erro_parametros;
        RETURN;
    END IF;
    
    -- Validação para evitar cópia para o mesmo usuário
    IF p_usuario_origem = p_usuario_destino THEN
        p_mensagem := c_erro_mesmo_usuario;
        RETURN;
    END IF;
    
    -- Inicia transação
    SAVEPOINT inicio_copia;
    
    -- Iteração sobre os registros do usuário de origem
    FOR r IN c_registros_origem LOOP
        -- Verificação de existência do CR para o usuário destino
        SELECT COUNT(*)
          INTO v_exists
          FROM AD_RESPCR
         WHERE CODUSU = p_usuario_destino
           AND CODCENCUS = r.CODCENCUS;
           
        -- Inserção apenas se não existir
        IF v_exists = 0 THEN
            INSERT INTO AD_RESPCR (CODUSU, CODCENCUS)
            VALUES (
                p_usuario_destino,
                r.CODCENCUS
            );
            
            v_count_inseridos := v_count_inseridos + 1;
        END IF;
    END LOOP;
    
    -- Commit apenas se houver inserções
    IF v_count_inseridos > 0 THEN
        COMMIT;
        p_mensagem := 'Foram copiados ' || v_count_inseridos || 
            ' Centro(s) de Resultado(s) do usuário ' || p_usuario_origem || 
            ' para o usuário ' || p_usuario_destino;
        p_status := c_sucesso;
    ELSE
        p_mensagem := 'Nenhum novo Centro de Resultado foi necessário para o usuário ' || 
            p_usuario_destino;
        p_status := c_sucesso;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Rollback em caso de erro
        ROLLBACK TO inicio_copia;
        -- Define mensagem e status de erro
        p_mensagem := 'Erro durante a cópia dos Centros de Resultados: ' || SQLERRM;
        p_status := c_erro;
END COPIAR_USUARIO_CR;
/