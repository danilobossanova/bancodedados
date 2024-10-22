/**
* @author: Danilo Fernando <danilo.bossanova@hotmail.com>
* @since: 11/10/2024 13:19
* @description: Package que concentra funcoes e procedures ligadas aos checkouts disponiveis.

   Script  para gerar a tabela temporaria:

    CREATE GLOBAL TEMPORARY TABLE temp_checkouts_em_uso (
        codend NUMBER PRIMARY KEY,
        data_bloqueio TIMESTAMP DEFAULT SYSTIMESTAMP
    ) ON COMMIT PRESERVE ROWS;

*/
CREATE OR REPLACE PACKAGE BODY WMSendereco_checkout AS

 /* Limpar CHeckouts Expirados */
 PROCEDURE limpar_checkouts_expirados IS
    BEGIN
        DELETE FROM temp_checkouts_em_uso
        WHERE data_bloqueio < SYSTIMESTAMP - INTERVAL '60' MINUTE;
    END limpar_checkouts_expirados;

    /* Buscar Condend Disponivel */
    FUNCTION buscar_codend_disponivel RETURN NUMBER IS
        v_codend NUMBER;
    BEGIN
    
        -- Verificar se já existe um CODENDDESTINO definido na TGWITT para NUTAREFA
        BEGIN
            SELECT DISTINCT i.codenddestino
            INTO v_codenddestino
            FROM tgwitt i
            WHERE i.nutarefa = p_nutarefa
              AND i.codenddestino IS NOT NULL
              AND i.codenddestino NOT IN (15195, 15200)
              AND i.codenddestino != i.codendorigem;
            
            -- Se encontrou um CODENDDESTINO válido, retornar este valor
            RETURN v_codenddestino;
            
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- Continuar com a lógica original se não encontrar um CODENDDESTINO válido
                NULL;
        END;
     
        -- Limpar checkouts expirados antes de buscar um novo
        limpar_checkouts_expirados;
        
        SELECT e.codend
        INTO v_codend
        FROM tgwend e
        WHERE e.analitico = 'S'
          AND e.ativo = 'S'
          AND e.codend <> 0
          AND e.picking = 'N'
          AND (
              (e.endereco BETWEEN c_inicio_intervalo_1 AND c_fim_intervalo_1)
              OR (e.endereco BETWEEN c_inicio_intervalo_2 AND c_fim_intervalo_2)
          )
          AND NOT EXISTS (
              SELECT 1
              FROM vgwsepchk v
              WHERE v.codenddestino = e.codend
          )
          AND NOT EXISTS (
              SELECT 1
              FROM temp_checkouts_em_uso t
              WHERE t.codend = e.codend
          )
        ORDER BY e.endereco
        FETCH FIRST 1 ROW ONLY;
        
        -- Bloquear o checkout selecionado
        INSERT INTO temp_checkouts_em_uso (codend) VALUES (v_codend);
        COMMIT;
        
        RETURN v_codend;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END buscar_codend_disponivel;
    
    /* Obter Endereço */
    FUNCTION obter_endereco(p_codend IN NUMBER) RETURN VARCHAR2 IS
        v_endereco VARCHAR2(100);
    BEGIN
        SELECT endereco
        INTO v_endereco
        FROM tgwend
        WHERE codend = p_codend;
        
        RETURN v_endereco;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END obter_endereco;

    /* Liberar Checkout */
    PROCEDURE liberar_checkout(p_codend IN NUMBER) IS
    BEGIN
        DELETE FROM temp_checkouts_em_uso WHERE codend = p_codend;
        COMMIT;
    END liberar_checkout;  
    
    
    /*
    */
    /* Atualizar Endereço de Checkout */
    PROCEDURE ATUALIZA_CHECKOUT_NAITT(p_nutarefa IN NUMBER) IS
        v_codend_disponivel NUMBER;
    BEGIN
        -- Buscar endereço de checkout disponível
        v_codend_disponivel := buscar_codend_disponivel();
        
        IF v_codend_disponivel IS NOT NULL THEN
            -- Atualizar o endereço de checkout na tabela TGWITT
            UPDATE TGWITT ITT
            SET ITT.CODENDDESTINO = v_codend_disponivel
            WHERE ITT.NUTAREFA = p_nutarefa
              AND ITT.CODENDORIGEM <> 15200  -- Verifica se o CODENDORIGEM é diferente de 15200
              AND ITT.CODAREASEP <> 3  -- Verifica se a área de separação é diferente de 3
              AND EXISTS (
                  SELECT 1
                  FROM TGWTAR TAR
                  WHERE TAR.CODTAREFA = 3  -- Verifica se o CODTAREFA é igual a 3 na tabela TGWTAR
                    AND TAR.NUTAREFA = ITT.NUTAREFA
              );
            
            COMMIT;
        END IF;
    END ATUALIZA_CHECKOUT_NAITT;
    
    
END WMSendereco_checkout;
/