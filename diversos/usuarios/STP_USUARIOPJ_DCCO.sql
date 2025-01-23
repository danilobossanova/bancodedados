CREATE OR REPLACE PROCEDURE STP_USUARIOPJ_DCCO (
    p_codemp        IN  NUMBER,      -- Código da empresa
    p_codusu        IN  NUMBER,      -- Código do usuário
    p_email         OUT VARCHAR2,    -- Email do usuário
    p_nomefunc      OUT VARCHAR2     -- Nome completo do usuário
) IS
/*
* Autor: Danilo Bossanova <danilo.bossanova@hotmail.com>
* Data Criação: 14/01/2025
* Objetivo: Buscar informações de usuários PJ na tabela TSIUSU
*
* Descrição: 
* Esta procedure busca os dados básicos de um usuário PJ diretamente
* da tabela TSIUSU. Os campos retornados são o email e o nome completo.
* Caso o usuário não seja encontrado, os campos de saída serão NULL.
*
* Parâmetros:
* p_codemp   (IN)  - Código da empresa do usuário
* p_codusu   (IN)  - Código do usuário PJ
* p_email    (OUT) - Email do usuário encontrado
* p_nomefunc (OUT) - Nome completo do usuário encontrado
*
* Histórico de Alterações:
* Quando     | Por quem        | O que
* 14/01/2025 | Danilo Fernando | Criação inicial da procedure
*
* Tabelas Utilizadas:
* - TSIUSU
*/

BEGIN

    -- Busca os dados do usuário PJ
    SELECT INITCAP(U.NOMEUSUCPLT),
           U.EMAIL
    INTO   p_nomefunc,
           p_email
    FROM   TSIUSU U
    WHERE  U.CODEMP = p_codemp 
    AND    U.CODUSU = p_codusu;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Quando não encontrar o usuário, retorna NULL
        p_email := NULL;
        p_nomefunc := NULL;
        
    WHEN OTHERS THEN
        RAISE;
        
END STP_USUARIOPJ_DCCO;
/