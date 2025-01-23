CREATE OR REPLACE PROCEDURE STP_FUNC_DCCO (
    p_codemp        IN  NUMBER,      -- C�digo da empresa
    p_codfunc       IN  NUMBER,      -- C�digo do funcion�rio
    p_codcargo      OUT NUMBER,      -- C�digo do cargo
    p_coddept       OUT NUMBER,      -- C�digo do departamento
    p_nomefunc      OUT VARCHAR2,    -- Nome do funcion�rio
    p_descrdep      OUT VARCHAR2,    -- Descri��o do departamento
    p_email         OUT VARCHAR2     -- Email do funcion�rio
) IS
/*
* Autor: Danilo Fernando <danilo.fernando@grupocopar.com.br>
* Data Cria��o: 14/01/2025
* Objetivo: Buscar informa��es completas de funcion�rios nas tabelas TFPFUN e TFPDEP
*
* Descri��o: 
* Esta procedure busca os dados completos de um funcion�rio, incluindo
* informa��es do seu departamento. Os dados s�o obtidos atrav�s de um
* JOIN entre as tabelas TFPFUN (funcion�rios) e TFPDEP (departamentos).
* Se o funcion�rio n�o for encontrado, todos os campos de sa�da ser�o
* inicializados com valores padr�o (0 para n�meros e NULL para textos).
*
* Par�metros:
* p_codemp   (IN)  - C�digo da empresa do funcion�rio
* p_codfunc  (IN)  - C�digo do funcion�rio
* p_codcargo (OUT) - C�digo do cargo do funcion�rio
* p_coddept  (OUT) - C�digo do departamento
* p_nomefunc (OUT) - Nome completo do funcion�rio
* p_descrdep (OUT) - Descri��o do departamento
* p_email    (OUT) - Email do funcion�rio
*
* Hist�rico de Altera��es:
* Quando     | Por quem | O que
* 14/01/2025 | Danilo  | Cria��o inicial da procedure
*
* Tabelas Utilizadas:
* - TFPFUN
* - TFPDEP
*/

BEGIN
  
    -- Busca os dados do funcion�rio e departamento
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
        -- Quando n�o encontrar o funcion�rio, inicializa com valores padr�o
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