/**
* @author: Danilo Fernando <danilo.bossanova@hotmail.com>
* @since: 11/10/2024 13:19
* @description: Package que concentra funcoes e procedures ligadas aos checkouts disponiveis.

*/
CREATE OR REPLACE PACKAGE BODY WMSendereco_checkout AS

    /* Fun��o que retorna um endere�o de checkout disponivel */
   FUNCTION buscar_codend_disponivel RETURN NUMBER IS
        v_codend NUMBER;
    BEGIN
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
        ORDER BY e.endereco
        FETCH FIRST 1 ROW ONLY;
        
        RETURN v_codend;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END buscar_codend_disponivel;
    
    
    /* Fun��o que retorna a descri��o do endere�o */
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
    
    
END WMSendereco_checkout;
/