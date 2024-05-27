/*******************************************************************************
* @description: Mostra o estoque no Endereço
*
********************************************************************************/
SELECT

    WEST.CODEMP,
    WEST.CODPROD,
    WEST.CODEND,
    WEST.ESTOQUE,
    WEST.ENTRADASPEND,
    WEST.SAIDASPEND

FROM TGWEST WEST
WHERE WEST.CODEND = 15200
AND WEST.CODPROD = 723921;