CREATE OR REPLACE PROCEDURE STP_EHCONTROLADOWMS_DCCO (
  p_codprod IN VARCHAR2,
  p_ativo_wms OUT VARCHAR2
)

AS
    
    l_existe_wms NUMBER; 

BEGIN
    -- Consulta para verificar se o produto utiliza WMS
    SELECT COUNT(*)
    INTO l_existe_wms
    FROM TGFPRO
    WHERE UTILIZAWMS = 'S'
    AND CODPROD = p_codprod;

    -- Atribuição do valor à variável de saída
    p_ativo_wms := CASE WHEN l_existe_wms > 0 THEN 'S' ELSE 'N' END;
  
END STP_EHCONTROLADOWMS_DCCO;
