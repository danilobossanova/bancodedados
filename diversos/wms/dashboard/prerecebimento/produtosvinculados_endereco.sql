/*******************************************************************************
* @description: Mostra os endereços vinculados para cada uma dos produtos
* listados no select acima
*
********************************************************************************/
SELECT

 WEXP.CODPROD,
 WEXP.CODEND,
 ENDE.DESCREND,
 ENDE.ENDERECO,
 WEXP.ATIVO,
 WEXP.CODVOL,
 WEXP.ESTMIN,
 WEXP.ESTMAX,
 WEXP.DTINICIO

FROM TGWEXP WEXP
INNER JOIN TGWEND ENDE ON WEXP.CODEND = ENDE.CODEND
WHERE WEXP.CODPROD = 723921;