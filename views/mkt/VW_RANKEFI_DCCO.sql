CREATE OR REPLACE VIEW VW_RANKEFIC_DCCO AS

/*
    View que retorna a eficiente do gerente do departamento em responder a um
    lead
    
    Critérios:
    Leads respondidos dentro do prazo (fechados no prazo) devem ter um peso mais elevado, ou seja, aumentam bastante a eficiência.
    Leads respondidos fora do prazo devem aumentar a eficiência, mas com um peso menor (recompensa pela resposta, mas penalização por atraso).
    Leads abertos e atrasados devem penalizar fortemente a eficiência, pois mostram ineficiência.
    Leads abertos no prazo não afetam a eficiência, pois ainda não se sabe se serão respondidos dentro do prazo ou não.
    
    fórmula que atribua diferentes pesos para cada situação:

    Leads fechados dentro do prazo (peso alto, recompensa total) ? peso 1.0.
    Leads fechados fora do prazo (peso médio, recompensa parcial) ? peso 0.7.
    Leads abertos e atrasados (peso baixo, penalização severa) ? peso -1.0 (forte penalização).
    Leads abertos no prazo (neutro, não impacta a eficiência) ? peso 0.
    
*/

WITH lead_stats AS (
    SELECT
        DEPTO,
        CASE 
            WHEN TO_CHAR(DEPTO) = 'GE' THEN 'Fabio'
            WHEN TO_CHAR(DEPTO) = 'MA' THEN 'Lucas'
            WHEN TO_CHAR(DEPTO) = 'PE' THEN 'Roygen'
            WHEN TO_CHAR(DEPTO) = 'RE' THEN 'Revalino'
            WHEN TO_CHAR(DEPTO) = 'SE' THEN 'Sérgio'
            WHEN TO_CHAR(DEPTO) = 'SO' THEN 'Guilherme'
            ELSE 'A definir'
        END AS Gerente,
        
        COUNT(*) AS Total_Leads,

        -- Contagem de leads abertos e fechados
        COUNT(CASE WHEN STATUS = 'AB' THEN 1 END) AS Total_Abertos,
        COUNT(CASE WHEN STATUS = 'FE' THEN 1 END) AS Total_Fechados,

        -- Contagem de leads atrasados
        NVL(SUM(CASE WHEN STATUS = 'AB' AND SYSDATE > DTCRIACAO + TEMPORET THEN 1 ELSE 0 END), 0) AS Total_Abertos_Atrasados,
        NVL(SUM(CASE WHEN STATUS = 'FE' AND SYSDATE > DTCRIACAO + TEMPORET THEN 1 ELSE 0 END), 0) AS Total_Fechados_Atrasados,

        -- Contagem de leads respondidos no prazo
        NVL(SUM(CASE WHEN STATUS = 'FE' AND SYSDATE <= DTCRIACAO + TEMPORET THEN 1 ELSE 0 END), 0) AS Total_Fechados_No_Prazo,

        -- Contagem de leads abertos no prazo
        NVL(SUM(CASE WHEN STATUS = 'AB' AND SYSDATE <= DTCRIACAO + TEMPORET THEN 1 ELSE 0 END), 0) AS Total_Abertos_No_Prazo,

        -- Cálculo da eficiência com pesos
        CASE
            WHEN COUNT(*)> 0 THEN
                ROUND(
                    (
                        (NVL(SUM(CASE WHEN STATUS = 'FE' AND SYSDATE <= DTCRIACAO + TEMPORET THEN 1 ELSE 0 END),0) * 1.0)				 -- FECHADO NO PRAZO (PESO 1.0)
                        +
                        (NVL(SUM(CASE WHEN STATUS = 'FE' AND SYSDATE > DTCRIACAO + TEMPORET THEN 1 ELSE 0 END),0) * 0.9)			 	 -- FECHADOS FORA DO PRAZO (PESO 0.7)
                        -
                        (NVL(SUM(CASE WHEN STATUS='AB' AND SYSDATE > DTCRIACAO + TEMPORET THEN 1 ELSE 0 END),0) * 0.3)					-- ABERTOS E ATRASADOS (PENALIDADE FORTE, PESO -0.3)

                    ) / COUNT(*) * 100 ,2    -- DIVIDIDO PELO TOTAL * 100. ARRENDONDANDO PRA 2 CASAS DECIMAIS
                ) 
            ELSE 0
        END AS Eficiencia

    FROM 
        AD_CRMGESINT
    WHERE 
        ORIGEM = 'SI' 
        AND TIPINT = 'SO'
        --AND TRUNC(DTCRIACAO) BETWEEN TRUNC(:PERIODO.INI) AND TRUNC(:PERIODO.FIN)
    GROUP BY
        DEPTO,
        CASE 
            WHEN TO_CHAR(DEPTO) = 'GE' THEN 'Fabio'
            WHEN TO_CHAR(DEPTO) = 'MA' THEN 'Lucas'
            WHEN TO_CHAR(DEPTO) = 'PE' THEN 'Roygen'
            WHEN TO_CHAR(DEPTO) = 'RE' THEN 'Revalino'
            WHEN TO_CHAR(DEPTO) = 'SE' THEN 'Sérgio'
            WHEN TO_CHAR(DEPTO) = 'SO' THEN 'Guilherme'
            ELSE 'A definir'
        END
)

SELECT 
    Gerente,
    Total_Leads,
    Total_Abertos,
    Total_Fechados,
    Total_Abertos_Atrasados,
    Total_Fechados_Atrasados,
    Total_Fechados_No_Prazo,
    Total_Abertos_No_Prazo,
    Eficiencia,
    RANK() OVER (ORDER BY Eficiencia DESC) AS Ranking
FROM lead_stats;