CREATE OR REPLACE FUNCTION SANKHYA.EH_DIA_UTIL_EMP (
    datainicial IN DATE,
    pCodEmp IN NUMBER
)
RETURN INT
IS
    ppais           INT;
    pestado         INT;
    pcidade         INT;
    pcodparc        INT;
    pCount          INT := 0; -- Inicializando pCount
    pdataini        DATE;
    pdia            INT;
    pmes            INT;

    /*******************************************************************************
    @Author: Danilo
    @Description: Retorna se a data informado é um feriado para a empresa informada
    ********************************************************************************/



BEGIN
    -- Verifica se a data inicial é nula
    IF datainicial IS NULL THEN
        RETURN 0;
    END IF;

    -- Verifica se a data inicial é sábado ou domingo
    IF TO_NUMBER(TO_CHAR(datainicial, 'D')) IN (1, 7) THEN
        RETURN 0;
    END IF;

    pdataini := TRUNC(datainicial);

    -- Obtém informações sobre o estado, país e cidade
    SELECT ufs.coduf, ufs.codpais, cid.codcid
    INTO pestado, ppais, pcidade
    FROM TSIUFS ufs
    JOIN TSICID cid ON cid.uf = ufs.coduf
    JOIN TSIEMP emp ON emp.codcid = cid.codcid
    WHERE emp.codemp = pCodEmp;

    -- Conta os feriados não recorrentes
    SELECT COUNT(*)
    INTO pCount
    FROM TSIFER
    WHERE dtferiado = pdataini
    AND recorrente = 'N'
    AND (codpais = ppais OR coduf = pestado OR codcid = pcidade OR nacional = 'I');

    -- Retorna 0 se houver feriado não recorrente
    IF pCount > 0 THEN
        RETURN 0;
    END IF;

    -- Verifica feriados recorrentes
    pdia := TO_NUMBER(TO_CHAR(pdataini, 'DD'));
    pmes := TO_NUMBER(TO_CHAR(pdataini, 'MM'));

    IF pmes = 2 AND pdia = 29 THEN
        pdataini := TO_DATE('1900-03-01', 'YYYY-MM-DD');
    ELSE
        pdataini := TO_DATE('1900-' || TO_CHAR(pmes) || '-' || TO_CHAR(pdia), 'YYYY-MM-DD');
    END IF;

    -- Conta os feriados recorrentes
    SELECT COUNT(*)
    INTO pCount
    FROM TSIFER
    WHERE dtferiado = pdataini
    AND recorrente = 'S'
    AND (codpais = ppais OR coduf = pestado OR codcid = pcidade OR nacional = 'I');

    -- Retorna 0 se houver feriado recorrente
    IF pCount > 0 THEN
        RETURN 0;
    END IF;

    -- Retorna 1 se não houver feriado
    RETURN 1;
END;
/
