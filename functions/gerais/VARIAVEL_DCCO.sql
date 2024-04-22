CREATE OR REPLACE FUNCTION SANKHYA.VARIAVEL_DCCO(P_NURELPARM NUMBER,P_DESCRICAO VARCHAR2, P_TEXTO VARCHAR2, P_KEY VETOR DEFAULT VETOR(), P_VLR VETOR DEFAULT VETOR(), P_VARINI VARCHAR2 DEFAULT '$', P_VARFIN VARCHAR2 DEFAULT '$')
RETURN VARCHAR2
IS

              P_TMP    VARCHAR2(32000);
              P_VALOR VARCHAR2(32000);
              P_MSG     VARCHAR2(32000);
              P_IGNORA  NUMBER;
              
              P_ISDATA    BOOLEAN := FALSE;
              P_TEXT        VARCHAR2(32000);
              P_PADRAO      VARCHAR2(32000);
              
              --PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN
-- (12,'TITULO','TEXTO E &VALOR1',VETOR('CODEMP','CODFUNC'),VETOR(1,626))

       P_MSG := P_TEXTO;

       FOR F1 IN (SELECT NOMECAMPO, BIGVALOR AS VALOR
       FROM AD_RELPARMAGRUCAMPO
       WHERE NURELPARM = P_NURELPARM
       AND      DESCRICAO = P_DESCRICAO)
       LOOP

           P_TMP := F1.VALOR;

           FOR I IN 1 .. P_KEY.COUNT
           LOOP
               
               -- TESTAR SE VALOR É UMA DATA
               P_ISDATA := (CASE WHEN IS_DATA_DCCO(P_VLR(I)) = 'S'  THEN TRUE ELSE FALSE END);
               P_PADRAO := IS_DATA_DCCO(P_VLR(I), 1);
                 
               -- MONTAR QUERY
               BEGIN
                 
                   IF IS_DATA_DCCO(P_VLR(I)) = 'N' THEN
                      P_TMP := REGEXP_REPLACE(P_TMP,':'||P_KEY(I)||':',NVL(''''||P_VLR(I)||'''','NULL'));
                   ELSE
                     P_TMP := REGEXP_REPLACE(P_TMP,':'||P_KEY(I)||':',NVL('TO_DATE('''||P_VLR(I)||''', ''DD/MM/RRRR HH24:MI:SS'')','NULL'));
                   END IF;
                   
               EXCEPTION
               WHEN OTHERS THEN
                   
                   P_TMP := REGEXP_REPLACE(P_TMP,':'||P_KEY(I)||':','NULL');
                   
               END;
           END LOOP;
           
           
           -- EXECUTAR QUERY
           BEGIN

             EXECUTE IMMEDIATE(P_TMP) INTO P_VALOR;
             
           EXCEPTION
           WHEN OTHERS THEN
               P_VALOR := '';
           END;
           
           BEGIN
             -- TESTAR SE INFORMAÇÃO É DATA
               IF IS_DATA_DCCO(P_VALOR) = 'S' THEN
                 
                    P_PADRAO := IS_DATA_DCCO(P_VALOR, 1);
                    
                    SELECT TO_DATE(P_VALOR, P_PADRAO) INTO P_TEXT
                    FROM DUAL;
                    
                    IF SUBSTR(TO_CHAR(TO_DATE(P_TEXT, P_PADRAO), P_PADRAO),12) = '00:00:00' THEN
                       P_MSG := REPLACE(P_MSG,P_VARINI||F1.NOMECAMPO||P_VARFIN,TO_CHAR(TO_DATE(P_VALOR, P_PADRAO), SUBSTR(P_PADRAO,0,11)));
                    ELSE
                       P_MSG := REPLACE(P_MSG,P_VARINI||F1.NOMECAMPO||P_VARFIN,TO_CHAR(TO_DATE(P_VALOR, P_PADRAO), P_PADRAO));
                    END IF;
              ELSE
                      P_MSG := REPLACE(P_MSG,P_VARINI||F1.NOMECAMPO||P_VARFIN,P_VALOR);                 
               END IF;
           EXCEPTION
           WHEN OTHERS THEN
             RAISE_APPLICATION_ERROR(-20101, SQLERRM||' - '||P_VALOR);
           END;
           
       END LOOP;
       
       IF P_MSG IS NULL THEN
          RETURN P_TEXTO;
       ELSE
          RETURN P_MSG;
       END IF;

END;

/