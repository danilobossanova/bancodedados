/**
O código abaixo realiza uma consulta em duas etapas usando uma expressão de tabela comum (common table expression ou CTE).
A CTE "FUN" é uma forma de definir uma "tabela virtual" que representa os funcionários filtrados com base nas condições especificadas.
Isso ajuda a separar a lógica da filtragem dos dados da lógica de agregação e contagem. Cada etapa tem um propósito claro e pode ser 
compreendida separadamente.
o usar uma CTE, o otimizador de consultas do banco de dados pode processar cada etapa separadamente e otimizar a execução de acordo.
Isso pode levar a um desempenho melhor, especialmente se houver índices adequados nas colunas utilizadas nas condições de filtro. 
*/

WITH FUN AS (
  SELECT 
    CODEMP,
    DTADM,
    CODFUNC
  FROM TFPFUN
  WHERE DTADM >= :PERIODO.INI
    AND DTADM <= :PERIODO.FIN
    AND CODEMP IN :EMPRESAS
)

SELECT 
  FUN.CODEMP,
  TO_CHAR(FUN.DTADM, 'YYYY') AS ANO,
  COUNT(DISTINCT FUN.CODFUNC) AS QTD
FROM FUN
GROUP BY 
  FUN.CODEMP,
  TO_CHAR(FUN.DTADM, 'YYYY')
ORDER BY 2 ASC