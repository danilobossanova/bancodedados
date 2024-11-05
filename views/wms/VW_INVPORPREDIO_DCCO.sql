DROP VIEW SANKHYA.VW_INVPORPREDIO_DCCO;

CREATE OR REPLACE FORCE VIEW SANKHYA.VW_INVPORPREDIO_DCCO
(NUTAREFA, CODUSU, DTTAREFA, NUIVT, CODTAREFA, 
 AD_ID_DCCO, CODEMP, CODENDDESTINO, CODENDORIGEM, CODLOCAL, 
 CODPROD, CODUSUEXEC, DHFIMMAPA, DHFINALEXEC, DHIMPMAPA, 
 DHINICIALEXEC, DHINICIOMAPA, SEQUENCIA, SITUACAO, CODEND, 
 DESCREND, ENDERECO, END_RUA, END_PREDIO, END_RUA_PREDIO)
BEQUEATH DEFINER
AS 
SELECT 
    TAR.NUTAREFA, 
    TAR.CODUSU,
    TAR.DTTAREFA,
    TAR.NUIVT,
    TAR.CODTAREFA,
    ITT.AD_ID_DCCO,
    ITT.CODEMP,
    ITT.CODENDDESTINO,
    ITT.CODENDORIGEM, 
    ITT.CODLOCAL,
    ITT.CODPROD,
    ITT.CODUSUEXEC,
    ITT.DHFIMMAPA,
    ITT.DHFINALEXEC,
    ITT.DHIMPMAPA,
    ITT.DHINICIALEXEC,
    ITT.DHINICIOMAPA,
    ITT.SEQUENCIA,
    ITT.SITUACAO,
    END.CODEND,
    END.DESCREND,
    END.ENDERECO,
    SUBSTR(END.ENDERECO, 4, 2) AS end_rua,  -- Extrai a RUA (01)
    SUBSTR(END.ENDERECO, 7, 3) AS end_predio,  -- Extrai o PREDIO (005)
    SUBSTR(END.ENDERECO, 4, 2) || '.' || SUBSTR(END.ENDERECO, 7, 3) AS end_rua_predio  -- Campo concatenado de RUA e PR�DIO
FROM 
    TGWTAR TAR
JOIN 
    TGWITT ITT ON TAR.NUTAREFA = ITT.NUTAREFA
JOIN 
    TGWEND END ON ITT.CODENDORIGEM = END.CODEND
WHERE 
        END.ATIVO = 'S'
    AND END.ANALITICO = 'S'
    AND END.TIPO = 'AP';
