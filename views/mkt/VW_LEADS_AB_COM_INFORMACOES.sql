-- View para exibir informações sobre leads com status aberto,
-- incluindo dados de contato, área de interesse, gerente responsável
-- e situação em relação à data prevista de retorno.
-- Author: Danilo Fernando <danilo.bossanova@hotmail.com>
-- Data de criação: 12/09/2024 14:07 (-03)



CREATE OR REPLACE FORCE VIEW SANKHYA.VW_LEADS_AB_COM_INFORMACOES
(DTCRIACAO, DATA_PREVISTA_RETORNO, AREA_INTERESSE, NOME_CONTATO, CIDADE, 
 URL, DEPTO, GERENTE, EMAILDESTINO, SITUACAO, 
 DIASDEATRASO, DIASPARAVENCIMENTO)
BEQUEATH DEFINER
AS 
SELECT 
    TRUNC(LEADS.DTCRIACAO) AS DTCRIACAO,
    TRIM(TRUNC(VW.DTPREVRET)) AS DATA_PREVISTA_RETORNO,
    TRIM(VW.AREA_INTERESSE) AS AREA_INTERESSE,
    TRIM(VW.CONTATO) AS NOME_CONTATO,
    TRIM(VW.CIDADE) AS CIDADE,
    LEADS.URL,
    LEADS.DEPTO,
    
    -- Verifica se DEPTO é válido antes de usar o CASE
    CASE
        WHEN LEADS.DEPTO = 'GE' THEN 'Fábio Carvalho'
        WHEN LEADS.DEPTO = 'MA' THEN 'Lucas Duarte'
        WHEN LEADS.DEPTO = 'PE' THEN 'Roygen Ramacciotte'
        WHEN LEADS.DEPTO = 'RE' THEN 'Revalino Jr.'
        WHEN LEADS.DEPTO = 'SE' THEN 'Sérgio Gabriel'
        WHEN LEADS.DEPTO = 'SO' THEN 'Guilherme Lobo'
        ELSE 'A definir'
    END AS GERENTE,
    
    CASE
        WHEN LEADS.DEPTO = 'GE' THEN 'fabio.carvalho@dcco.com.br'
        WHEN LEADS.DEPTO = 'MA' THEN 'adm.maquinas@dcco.com.br'
        WHEN LEADS.DEPTO = 'PE' THEN 'roygen.ramacciotte@dcco.com.br'
        WHEN LEADS.DEPTO = 'RE' THEN 'revalino.junior@dcco.com.br'
        WHEN LEADS.DEPTO = 'SE' THEN 'sergio.gabriel@dcco.com.br'
        WHEN LEADS.DEPTO = 'SO' THEN 'guilherme.lobo@dcco.com.br'
        ELSE 'marketing@dcco.com.br'
    END AS EMAILDESTINO,
    
    -- Verifica se VW.DTPREVRET é não nulo antes de comparar com SYSDATE
    CASE
        WHEN VW.DTPREVRET IS NOT NULL AND SYSDATE > VW.DTPREVRET THEN 'ATRASADO'
        WHEN VW.DTPREVRET IS NOT NULL AND SYSDATE <= VW.DTPREVRET THEN 'NO PRAZO'
        ELSE 'SEM DATA'  -- Caso VW.DTPREVRET seja NULL
    END AS SITUACAO,
    
    CASE
        WHEN VW.DTPREVRET IS NOT NULL AND SYSDATE > VW.DTPREVRET THEN ROUND(TRUNC(SYSDATE - VW.DTPREVRET))
        ELSE 0
    END AS DIASDEATRASO,
    
    CASE
        WHEN VW.DTPREVRET IS NOT NULL AND SYSDATE <= VW.DTPREVRET THEN ROUND(TRUNC(VW.DTPREVRET) - TRUNC(SYSDATE))
        ELSE 0
    END AS DIASPARAVENCIMENTO
    
FROM AD_CRMGESINT LEADS
LEFT JOIN VW_LeadInfo_DCCO VW ON VW.CODPAP = LEADS.CODPAP AND VW.SEQ = LEADS.SEQ
WHERE 1=1
    AND LEADS.ORIGEM = 'SI'
    AND LEADS.STATUS = 'AB'
    AND LEADS.TIPINT = 'SO'
    AND VW.OBSGESTOR IS NULL
    AND VW.DTRESPOSTA IS NULL
    AND LEADS.DEPTO IS NOT NULL
ORDER BY DTCRIACAO DESC;
