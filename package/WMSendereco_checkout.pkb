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
    
    
    
    
    
END WMSendereco_checkout;
/