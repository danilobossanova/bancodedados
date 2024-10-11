/**
* @author: Danilo Fernando <danilo.bossanova@hotmail.com>
* @since: 11/10/2024 13:19
* @description: Package que concentra funcoes e procedures ligadas aos checkouts disponiveis.

*/
CREATE OR REPLACE PACKAGE WMSendereco_checkout AS
    -- Constantes para intervalos de endereços de checkout
    c_inicio_intervalo_1    CONSTANT    VARCHAR2(16) := '11.98.001.01';
    c_fim_intervalo_1       CONSTANT    VARCHAR2(16) := '11.98.001.99';
    
    c_inicio_intervalo_2    CONSTANT    VARCHAR2(16) := '11.98.002.01';
    c_fim_intervalo_2       CONSTANT    VARCHAR2(16) := '11.98.002.99';
    
    /**
     * Busca o CODEND de um endereço de checkout disponível.
     *
     * @return NUMBER CODEND do endereço de checkout disponível, ou NULL se nenhum for encontrado.
     */
    FUNCTION buscar_codend_disponivel RETURN NUMBER;

    /**
     * Retorna o ENDERECO correspondente ao CODEND fornecido.
     *
     * @param p_codend NUMBER O código do endereço (CODEND) para buscar o ENDERECO.
     * @return VARCHAR2 ENDERECO correspondente ao CODEND fornecido, ou NULL se não encontrado.
     */
    FUNCTION obter_endereco(p_codend IN NUMBER) RETURN VARCHAR2;
END WMSendereco_checkout;
/