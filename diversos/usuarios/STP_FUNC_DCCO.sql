CREATE OR REPLACE PROCEDURE STP_FUNC_DCCO (
    p_codemp        IN  NUMBER,      -- Código da empresa
    p_codfunc       IN  NUMBER,      -- Código do funcionário
    p_codcargo      OUT NUMBER,      -- Código do cargo
    p_coddept       OUT NUMBER,      -- Código do departamento
    p_nomefunc      OUT VARCHAR2,    -- Nome do funcionário
    p_descrdep      OUT VARCHAR2,    -- Descrição do departamento
    p_email         OUT VARCHAR2     -- Email do funcionário
) IS
/*
* Autor: Danilo Fernando <danilo.fernando@grupocopar.com.br>
* Data Criação: 14/01/2025
* Objetivo: Buscar informações completas de funcionários nas tabelas TFPFUN e TFPDEP
*
* Descrição: 
* Esta procedure busca os dados completos de um funcionário, incluindo
* informações do seu departamento. Os dados são obtidos através de um
* JOIN entre as tabelas TFPFUN (funcionários) e TFPDEP (departamentos).
* Se o funcionário não for encontrado, todos os campos de saída serão
* inicializados com valores padrão (0 para números e NULL para textos).
*
* Parâmetros:
* p_codemp   (IN)  - Código da empresa do funcionário
* p_codfunc  (IN)  - Código do funcionário
* p_codcargo (OUT) - Código do cargo do funcionário
* p_coddept  (OUT) - Código do departamento
* p_nomefunc (OUT) - Nome completo do funcionário
* p_descrdep (OUT) - Descrição do departamento
* p_email    (OUT) - Email do funcionário
*
* Histórico de Alterações:
* Quando     | Por quem | O que
* 14/01/2025 | Danilo  | Criação inicial da procedure
*
* Tabelas Utilizadas:
* - TFPFUN
* - TFPDEP
*/

BEGIN
  
    -- Busca os dados do funcionário e departamento
    SELECT NVL(F.CODCARGO, 0),
           NVL(F.CODDEP, 0),
           INITCAP(F.NOMEFUNC),
           INITCAP(DEP.DESCRDEP),
           F.EMAIL
    INTO   p_codcargo,
           p_coddept,
           p_nomefunc,
           p_descrdep,
           p_email
    FROM   TFPFUN F
    LEFT JOIN TFPDEP DEP ON DEP.CODDEP = F.CODDEP
    WHERE  F.CODEMP = p_codemp 
    AND    F.CODFUNC = p_codfunc;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Quando não encontrar o funcionário, inicializa com valores padrão
        p_codcargo := 0;
        p_coddept := 0;
        p_email := NULL;
        p_nomefunc := NULL;
        p_descrdep := NULL;

        
    WHEN OTHERS THEN
        -- Propaga o erro
        RAISE;
        
END STP_FUNC_DCCO;
/