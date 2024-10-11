/**
* @author: Danilo Fernando <danilo.bossanova@hotmail.com>
* @since: 11/10/2024 13:19
* @description: Package que concentra funcoes e procedures ligadas aos checkouts disponiveis.

*/
CREATE OR REPLACE PACKAGE WMSendereco_checkout AS
   -- Constantes para intervalos de endereços de checkout
    c_inicio_intervalo_1    CONSTANT VARCHAR2(16) := '11.98.001.01';
    c_fim_intervalo_1       CONSTANT VARCHAR2(16) := '11.98.001.99';
    c_inicio_intervalo_2    CONSTANT VARCHAR2(16) := '11.98.002.01';
    c_fim_intervalo_2       CONSTANT VARCHAR2(16) := '11.98.002.99';
    
    FUNCTION buscar_codend_disponivel RETURN NUMBER;
    FUNCTION obter_endereco(p_codend IN NUMBER) RETURN VARCHAR2;
    
    /* Procedures que irão liberar checkout que estão reservados para separação */
    PROCEDURE liberar_checkout(p_codend IN NUMBER);
    PROCEDURE limpar_checkouts_expirados;
    
END WMSendereco_checkout;
/