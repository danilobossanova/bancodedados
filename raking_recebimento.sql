/*********************************************************************************************************************
* @author: Danilo Fernando <danilo.bossanova@hotmail.com>
* @description: Gera um rank de prioridade de recebimento, baseado nas reserva. Olha a quantidade peças e data de
  prioridade. As prioridades de recebimento nos produtos da Nota.
*********************************************************************************************************************/


SELECT
    R.CODPROD,
    SUM(R.QTDNEG) AS TOTAL_QTDNEG,
    MIN(R.DHPRIORIDADE) AS MIN_DHPRIORIDADE,
    RANK() OVER (ORDER BY SUM(R.QTDNEG) DESC, MIN(R.DHPRIORIDADE) ASC) AS RANKING
FROM AD_GERENCRESERVA R
WHERE R.CODEMP = 11
AND R.CODPROD IN (SELECT TGFITE.CODPROD FROM TGFITE WHERE TGFITE.NUNOTA = 4672929)
GROUP BY R.CODPROD
ORDER BY RANKING;
/