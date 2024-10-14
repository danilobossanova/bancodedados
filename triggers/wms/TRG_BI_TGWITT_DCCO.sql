/**
* @author Danilo Fernando <danilo.bossanova@hotmail.com>
* @version 1.0
* @since 14.10.2024
* @description Esta trigger � acionada antes de uma inser��o na tabela TGWITT.
* Ela verifica se a tarefa associada � inser��o � do tipo 'SEPARACAO' e, 
* em caso afirmativo, atribui um endere�o dispon�vel ao campo CODENDDESTINO.
* A trigger ignora erros e n�o realiza nenhuma a��o em caso de exce��o.
* A trigger s� ser� executada para tarefas da area de separa��o diferente da
* area de separa��o do VLM e cujo codigo de endere�o destino = 15195 que � o
* endere�o do checkout indefinido para empresa 11
*/

CREATE OR REPLACE TRIGGER TRG_BI_TGWITT_DCCO
BEFORE INSERT ON TGWITT
FOR EACH ROW
WHEN (
    :NEW.CODAREASEP != 3
    AND :NEW.CODENDORIGEM != 15200
    AND (:NEW.CODENDDESTINO IS NULL OR :NEW.CODENDDESTINO = 15195)
)
DECLARE
    v_endereco_disponivel NUMBER;
    v_codtarefa TGWTAR.CODTAREFA%TYPE;
    TAREFA_SEPARACAO CONSTANT NUMBER := 3;
BEGIN

    -- Buscar o CODTAREFA associado ao NUTAREFA na tabela TGWTAR
    BEGIN
        SELECT CODTAREFA INTO v_codtarefa
        FROM TGWTAR
        WHERE NUTAREFA = :NEW.NUTAREFA;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Se n�o encontrar a tarefa, simplesmente sai da trigger
            RETURN;
    END;
    
    -- Verificar se a tarefa � de separa��o
    IF v_codtarefa = TAREFA_SEPARACAO THEN
        -- Chama a fun��o que retorna o endere�o dispon�vel
        v_endereco_disponivel := WMSendereco_checkout.buscar_codend_disponivel();
        
       
        IF v_endereco_disponivel IS NOT NULL THEN
            :NEW.CODENDDESTINO := v_endereco_disponivel;
        END IF;
    END IF;
    
    
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;