-- View para exibir informações sobre leads com status aberto,
-- incluindo dados de contato, área de interesse, gerente responsável
-- e situação em relação à data prevista de retorno.
-- Author: Danilo Fernando <danilo.bossanova@hotmail.com>
-- Data de criação: 12/09/2024 14:07 (-03)

CREATE OR REPLACE VIEW VW_LEADS_AB_COM_INFORMACOES AS

SELECT 
    LEADS.DTCRIACAO,
    TRIM(VW.DTPREVRET) AS DATA_PREVISTA_RETORNO,
    TRIM(VW.AREA_INTERESSE) AS AREA_INTERESSE,
    TRIM(VW.CONTATO) AS NOME_CONTATO,
    TRIM(VW.CIDADE) AS CIDADE,
    LEADS.URL,
    LEADS.DEPTO,
    
    CASE
        WHEN TO_CHAR(DEPTO) = 'GE' THEN 'Fábio Carvalho'
        WHEN TO_CHAR(DEPTO) = 'MA' THEN 'Lucas Duarte'
        WHEN TO_CHAR(DEPTO) = 'PE' THEN 'Roygen Ramacciotte'
        WHEN TO_CHAR(DEPTO) = 'RE' THEN 'Revalino Jr.'
        WHEN TO_CHAR(DEPTO) = 'SE' THEN 'Sérgio Gabriel'
        WHEN TO_CHAR(DEPTO) = 'SO' THEN 'Guilherme Lobo'
        ELSE 'A definir'
    END AS GERENTE,
    
    CASE
        WHEN TO_CHAR(DEPTO) = 'GE' THEN 'fabio.carvalho@dcco.com.br'
        WHEN TO_CHAR(DEPTO) = 'MA' THEN 'adm.maquinas@dcco.com.br'
        WHEN TO_CHAR(DEPTO) = 'PE' THEN 'roygen.ramacciotte@dcco.com.br'
        WHEN TO_CHAR(DEPTO) = 'RE' THEN 'revalino.junior@dcco.com.br'
        WHEN TO_CHAR(DEPTO) = 'SE' THEN 'sergio.gabriel@dcco.com.br'
        WHEN TO_CHAR(DEPTO) = 'SO' THEN 'guilherme.lobo@dcco.com.br'
        ELSE 'marketing@dcco.com.br'
    END AS EMAILDESTINO,
    
    CASE
        WHEN SYSDATE > VW.DTPREVRET THEN 'ATRASADO'
        WHEN SYSDATE <= VW.DTPREVRET THEN 'NO PRAZO'
    END AS SITUACAO,
    
    CASE
        WHEN SYSDATE > VW.DTPREVRET THEN ROUND(TRUNC(SYSDATE - VW.DTPREVRET))
        ELSE 0
    END AS DIASDEATRASO,
    
    CASE
        WHEN SYSDATE <= VW.DTPREVRET THEN ROUND(TRUNC(VW.DTPREVRET) - TRUNC(SYSDATE))
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