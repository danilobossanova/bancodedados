CREATE OR REPLACE PROCEDURE STP_USUARIOPJ_DCCO (
    p_codemp        IN  NUMBER,      -- C�digo da empresa
    p_codusu        IN  NUMBER,      -- C�digo do usu�rio
    p_email         OUT VARCHAR2,    -- Email do usu�rio
    p_nomefunc      OUT VARCHAR2     -- Nome completo do usu�rio
) IS
/*
* Autor: Danilo Bossanova <danilo.bossanova@hotmail.com>
* Data Cria��o: 14/01/2025
* Objetivo: Buscar informa��es de usu�rios PJ na tabela TSIUSU
*
* Descri��o: 
* Esta procedure busca os dados b�sicos de um usu�rio PJ diretamente
* da tabela TSIUSU. Os campos retornados s�o o email e o nome completo.
* Caso o usu�rio n�o seja encontrado, os campos de sa�da ser�o NULL.
*
* Par�metros:
* p_codemp   (IN)  - C�digo da empresa do usu�rio
* p_codusu   (IN)  - C�digo do usu�rio PJ
* p_email    (OUT) - Email do usu�rio encontrado
* p_nomefunc (OUT) - Nome completo do usu�rio encontrado
*
* Hist�rico de Altera��es:
* Quando     | Por quem        | O que
* 14/01/2025 | Danilo Fernando | Cria��o inicial da procedure
*
* Tabelas Utilizadas:
* - TSIUSU
*/

BEGIN

    -- Busca os dados do usu�rio PJ
    SELECT INITCAP(U.NOMEUSUCPLT),
           U.EMAIL
    INTO   p_nomefunc,
           p_email
    FROM   TSIUSU U
    WHERE  U.CODEMP = p_codemp 
    AND    U.CODUSU = p_codusu;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Quando n�o encontrar o usu�rio, retorna NULL
        p_email := NULL;
        p_nomefunc := NULL;
        
    WHEN OTHERS THEN
        RAISE;
        
END STP_USUARIOPJ_DCCO;
/