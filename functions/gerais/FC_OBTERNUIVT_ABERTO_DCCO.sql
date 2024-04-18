CREATE OR REPLACE FUNCTION obter_nuivt_concatenado RETURN VARCHAR2 IS
    nuivt_concatenado VARCHAR2(4000);
BEGIN
    SELECT LISTAGG(NUIVT, ', ') WITHIN GROUP (ORDER BY NUIVT) INTO nuivt_concatenado
    FROM TGWIVT
    WHERE DTFINAL IS NULL;

    RETURN nuivt_concatenado;
END;
/
