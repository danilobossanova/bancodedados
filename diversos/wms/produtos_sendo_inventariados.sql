-- *****************************************************************************
-- VIEW: VW_CONTATIVAIVT_DCCO
-- @author:         Danilo Fernando <danilo.fernando@grupocopar.com.br>
-- @description:    Retorna todos os SKU's que estão sendo inventariados nesse momento.
--                  Analisa os inventários Rotativos que ainda não foram finalizados.
--  @date:          07/02/2024 08:23
 
 -- *****************************************************************************
 
CREATE OR REPLACE VIEW VW_CONTATIVAIVT_DCCO AS

SELECT

    IVR.CODEMP,
    IVR.CODPROD,
    IVR.CODEND,
    IVR.CODVOL,
    IVR.DHCONTAGEM,
    IVR.ATIVA,
    IVR.AD_CONTAGEM
FROM 
    TGWIVR IVR 
WHERE 
    IVR.ATIVA = 'S'
    AND IVR.NUIVT IN (
        -- Subconsulta para obter os NUIVT ativos
        SELECT IVT.NUIVT 
        FROM TGWIVT IVT 
        WHERE IVT.DTFINAL IS NULL 
            AND IVT.TIPO = 'R'
    );
