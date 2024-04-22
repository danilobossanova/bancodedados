CREATE OR REPLACE FUNCTION SANKHYA.IS_DATA_DCCO(P_VALUE   VARCHAR2, P_RETURN  INT DEFAULT 0)
RETURN VARCHAR2
IS
  P_TXT          VARCHAR2(32000);
  P_ISDATA     BOOLEAN := FALSE;
  P_PADRAO   VARCHAR2(1000) := '';
  P_CONTINUAR   BOOLEAN := FALSE;

  V_VALOR       NUMBER;
BEGIN
              -- PRIMEIRAS VALIDAÇÕES
              P_CONTINUAR := (IS_NUMBER_DCCO(P_VALUE) IS NULL);

              -- CRIADO POR: MARCUS VINICIUS OLIVEIRA SILVA
              -- DATA: 11/07/2017 AS 13:40
              -- MOTIVO: TESTAR SE VALOR É UMA DATA
             IF P_VALUE IS NOT NULL AND LENGTH(P_VALUE) >= 6 AND P_CONTINUAR THEN
                 BEGIN
                        P_PADRAO := 'DD/MM/RRRR HH24:MI:SS';
                        SELECT TO_DATE(P_VALUE, P_PADRAO) INTO P_TXT
                        FROM DUAL;

                        P_ISDATA := TRUE;
                 EXCEPTION
                 WHEN OTHERS THEN

                       BEGIN
                          P_PADRAO := 'DD-MM-RRRR HH24:MI:SS';
                          SELECT TO_DATE(P_VALUE, P_PADRAO) INTO P_TXT
                          FROM DUAL;

                          P_ISDATA := TRUE;
                       EXCEPTION
                       WHEN OTHERS THEN

                           BEGIN
                              P_PADRAO := 'RRRR/MM/DD HH24:MI:SS';
                              SELECT TO_DATE(P_VALUE, P_PADRAO) INTO P_TXT
                              FROM DUAL;

                              P_ISDATA := TRUE;
                           EXCEPTION
                           WHEN OTHERS THEN

                               BEGIN
                                   P_PADRAO := 'RRRR-MM-DD HH24:MI:SS';
                                  SELECT TO_DATE(P_VALUE, P_PADRAO) INTO P_TXT
                                  FROM DUAL;

                                  P_ISDATA := TRUE;
                               EXCEPTION
                               WHEN OTHERS THEN

                                 BEGIN
                                    P_PADRAO := 'MM/DD/RRRR HH24:MI:SS';
                                    SELECT TO_DATE(P_VALUE, P_PADRAO) INTO P_TXT
                                    FROM DUAL;

                                    P_ISDATA := TRUE;
                                 EXCEPTION
                                 WHEN OTHERS THEN

                                    BEGIN
                                        P_PADRAO := 'MM-DD-RRRR HH24:MI:SS';
                                        SELECT TO_DATE(P_VALUE, P_PADRAO) INTO P_TXT
                                        FROM DUAL;

                                        P_ISDATA := TRUE;
                                     EXCEPTION
                                     WHEN OTHERS THEN
                                        BEGIN
                                            P_PADRAO := 'RRRR-DD-MM HH24:MI:SS';
                                            SELECT TO_DATE(P_VALUE, P_PADRAO) INTO P_TXT
                                            FROM DUAL;

                                            P_ISDATA := TRUE;
                                         EXCEPTION
                                         WHEN OTHERS THEN
                                           BEGIN
                                            P_PADRAO := 'Month/RRRR HH24:MI:SS';
                                            SELECT TO_DATE(P_VALUE, P_PADRAO) INTO P_TXT
                                            FROM DUAL;

                                            P_ISDATA := TRUE;
                                            EXCEPTION
                                            WHEN OTHERS THEN
                                              
                                                BEGIN
                                                   P_PADRAO := 'Month/RRRR';
                                                   SELECT TO_DATE(P_VALUE, P_PADRAO) INTO P_TXT
                                                   FROM DUAL;

                                                   P_ISDATA := TRUE;
                                                 EXCEPTION
                                                 WHEN OTHERS THEN
                                                    BEGIN
                                                       P_PADRAO := 'Month-RRRR';
                                                       SELECT TO_DATE(P_VALUE, P_PADRAO) INTO P_TXT
                                                       FROM DUAL;

                                                       P_ISDATA := TRUE;
                                                     EXCEPTION
                                                     WHEN OTHERS THEN
                                                        P_PADRAO := '';
                                                        P_ISDATA := FALSE;
                                                     END;
                                                 END;
                                            END;
                                            
                                         END;
                                         
                                     END;

                                 END;

                               END;

                           END;

                       END;

                  END;

              END IF;

              IF P_ISDATA THEN
                IF P_RETURN != 0 THEN
                   IF INSTR(P_VALUE,'-') > 0 THEN
                     RETURN REPLACE(P_PADRAO,'/','-');
                   ELSIF INSTR(P_VALUE,'/') > 0 THEN
                     RETURN REPLACE(P_PADRAO,'-','/');
                   ELSE
                     RETURN P_PADRAO;
                   END IF;
                ELSE
                  
                  IF INSTR(P_VALUE,'-') > 0 THEN
                     P_PADRAO := REPLACE(P_PADRAO,'/','-');
                   ELSIF INSTR(P_VALUE,'/') > 0 THEN
                     P_PADRAO := REPLACE(P_PADRAO,'-','/');
                   ELSE
                     P_PADRAO := P_PADRAO;
                   END IF;
                   
                  P_TXT := null;
                  BEGIN
                       SELECT TO_CHAR(TO_DATE(P_VALUE, P_PADRAO), P_PADRAO) INTO P_TXT
                       FROM DUAL;
                   EXCEPTION
                   WHEN OTHERS THEN
                      P_TXT := NULL;  
                   END;
                   
                   IF P_TXT IS NOT NULL THEN
                      RETURN 'S';
                    ELSE
                      RETURN 'N';
                    END IF;
                END IF;
              ELSE
                IF P_RETURN != 0 THEN
                   IF INSTR(P_VALUE,'-') > 0 THEN
                     RETURN REPLACE(P_PADRAO,'/','-');
                   ELSIF INSTR(P_VALUE,'/') > 0 THEN
                     RETURN REPLACE(P_PADRAO,'-','/');
                   ELSE
                     RETURN P_PADRAO;
                   END IF;
                ELSE
                   RETURN 'N';
                END IF;
              END IF;
END;

/