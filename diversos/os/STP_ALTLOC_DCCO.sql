CREATE OR REPLACE PROCEDURE SANKHYA.STP_ALTLOC_OS_DCCO
AS

/******************************************************************************
* Alterado por Danilo Fernando <danilo.fernando@grupocopar.com.br>
* Data Alteração: 10/06/2024 14:59:00
* Antes era:

FOR P_ITE IN(SELECT * FROM TGFITE WHERE NUNOTA IN(SELECT NUNOTA FROM TGFCAB
            WHERE CODTIPOPER = 1302 AND DTNEG >= '08/02/2023')
            AND SEQUENCIA < 0 AND CODLOCALORIG <> 930000000)

    LOOP
        UPDATE TGFITE SET CODLOCALORIG = 930000000
        WHERE NUNOTA = P_ITE.NUNOTA AND SEQUENCIA = P_ITE.SEQUENCIA;
    END LOOP;

* Descrição: Usa a sequencia positiva para o Local de Destino [990000000]
* Use sequencia negativa (-1... -2) para o Local de Destino [930000000]
*
*
******************************************************************************/


BEGIN


    -- Cursor para CODEMP = 11
    FOR P_ITE IN (
        SELECT NUNOTA, SEQUENCIA, CODLOCALORIG
        FROM TGFITE
        WHERE NUNOTA IN (
            SELECT NUNOTA
            FROM TGFCAB
            WHERE CODTIPOPER = 1302 -- Tipo de operação de devolução
              AND DTNEG >= TO_DATE('08/02/2023', 'DD/MM/YYYY') -- Data base
              AND CODEMP = 11 -- Empresa que utiliza WMS
        )
        )

        LOOP

            -- Verifica a sequência para definir o destino
            IF P_ITE.SEQUENCIA < 0 AND P_ITE.CODLOCALORIG <> 990000000 THEN
                UPDATE TGFITE
                SET CODLOCALORIG = 990000000
                WHERE NUNOTA = P_ITE.NUNOTA
                  AND SEQUENCIA = P_ITE.SEQUENCIA;

                --  Origem
            ELSIF P_ITE.SEQUENCIA > 0 AND P_ITE.CODLOCALORIG <> 930000000 THEN
                UPDATE TGFITE
                SET CODLOCALORIG = 930000000
                WHERE NUNOTA = P_ITE.NUNOTA
                  AND SEQUENCIA = P_ITE.SEQUENCIA;
            END IF;
        END LOOP;


    -- Commit após o loop para CODEMP =e 11
    COMMIT;



    -- Cursor para CODEMP diferente de 11
    FOR P_ITE IN (
        SELECT NUNOTA, SEQUENCIA, CODLOCALORIG
        FROM TGFITE
        WHERE NUNOTA IN (
            SELECT NUNOTA
            FROM TGFCAB
            WHERE CODTIPOPER = 1302 -- Tipo de operação de devolução
              AND DTNEG >= TO_DATE('08/02/2023', 'DD/MM/YYYY') -- Data base
              AND CODEMP <> 11 -- Outras empresas
        )
          AND SEQUENCIA < 0
          AND CODLOCALORIG <> 990000000
        )

        LOOP


            UPDATE TGFITE
            SET CODLOCALORIG = 990000000
            WHERE NUNOTA = P_ITE.NUNOTA
              AND SEQUENCIA = P_ITE.SEQUENCIA;

        END LOOP;

    -- Commit após o loop para CODEMP diferente de 11
    COMMIT;

END;
/
