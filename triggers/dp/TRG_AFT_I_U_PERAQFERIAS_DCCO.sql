-- Trigger to validate and process vacation periods in AD_PERAQFERIAS table
CREATE OR REPLACE TRIGGER TRG_AFT_I_U_PERAQFERIAS_DCCO
AFTER INSERT OR UPDATE ON SANKHYA.AD_PERAQFERIAS
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;

    DATA_FINAL_AQUISICAO   TFPFER.DTFINAQUI%TYPE;
    COD_FUNC               INT;
    COD_EMP                INT;
    P_CODEMP               NUMBER;  -- VILSON
    P_COUNT                INT;
    I_TOTALFERIAS          INT;
    DATA_FERIAS            DATE;
    DSR                    CHARACTER;
    FERIADO                CHARACTER;
    FER3DIASDSR            CHARACTER;
    I_FECHADA              INTEGER;
    I_GOZADA               INTEGER;
    I_MAIORDIA             INTEGER;
    DTFERDOBRADA           AD_PROGFERIAS.DTFINAQUI%TYPE;
    DTFIMFERIAS            AD_PROGFERIAS.DTFINAQUI%TYPE;

    CODFUNC_GERENTE        INTEGER;
    CODEMP_GERENTE         INTEGER;
    NOME_COLABORADOR       VARCHAR2(100);
    USUARIOGERENTE         INTEGER;

    C_TITULO               VARCHAR2(250) := '<b>A T E N Ç Ã O</b>! <span style="color:red !important">Férias Cadastradas</span>!';
    S_COLAB                VARCHAR2(250) := 'Você deve acessar a tela <b>Gerente - Programação de Férias</b> para validar as férias do Colaborador.';
    S_TEXTO                VARCHAR2(250);

    R_FECHA_FERIAS         VARCHAR2(20);
BEGIN
    -- Comment explaining the purpose of the trigger

    IF INSERTING THEN
        -- Insertion logic
        SELECT AD_PROGFERIAS.CODFUNC, AD_PROGFERIAS.CODEMP INTO COD_FUNC, COD_EMP FROM AD_PROGFERIAS WHERE AD_PROGFERIAS.NU = :NEW.NU;
        SELECT (PROG.DTFINAQUI + 365) INTO DTFERDOBRADA FROM AD_PROGFERIAS PROG WHERE PROG.NU = :NEW.NU;
        SELECT :NEW.DTPREVISTA + :NEW.NUMDIASFER INTO DTFIMFERIAS FROM DUAL;
        
        SELECT COUNT(NUAQUI) INTO P_COUNT FROM AD_PERAQFERIAS WHERE NU = :NEW.NU AND STATUS <> 'C';
        SELECT SUM(NUMDIASFER) INTO I_TOTALFERIAS FROM AD_PERAQFERIAS WHERE NU = :NEW.NU AND AD_PERAQFERIAS.STATUS NOT IN ('C');
    
        -- Férias só depois da data final de aquisição
        SELECT MAX(FER.DTFINAQUI) INTO DATA_FINAL_AQUISICAO FROM TFPFER FER WHERE FER.CODFUNC = COD_FUNC AND FER.CODEMP = COD_EMP;  -- VILSON CODEMP

        IF (:NEW.DTPREVISTA <= DATA_FINAL_AQUISICAO) THEN
            raise_application_error(-20001, 'A data de início das férias deve ser posterior à data final de aquisição.');
        END IF;

        -- Data não pode ser menor que a data de hoje
        IF (:NEW.DTPREVISTA < SYSDATE) THEN
            raise_application_error(-20002, 'A data de início das férias não pode ser anterior à data atual.');
        END IF;

        -- Nenhum período de férias pode ser menor que 5 dias
        IF (:NEW.NUMDIASFER < 5) THEN
            raise_application_error(-20003, 'O período de férias deve ter no mínimo 5 dias.');
        END IF;

        -- Nenhum período de férias pode ser maior que 30 dias
        IF (:NEW.NUMDIASFER > 30) THEN
            raise_application_error(-20004, 'O período de férias não pode exceder 30 dias.');
        END IF;

        -- Se houver mais de 1 período de férias, pelo menos 1 deve ter pelo menos 14 dias
        IF (P_COUNT = 2) THEN
            -- Pega o maior número de dias já lançado
            SELECT MAX(NUMDIASFER) INTO I_MAIORDIA FROM AD_PERAQFERIAS WHERE NU = :NEW.NU;
            
            IF (I_MAIORDIA < 14) THEN
                IF (:NEW.NUMDIASFER < 14) THEN
                    raise_application_error(-20005, 'Pelo menos um período de férias deve ter no mínimo 14 dias.');
                END IF;
            END IF;
        END IF;

        -- Podem haver no máximo 3 períodos de férias por aquisição de férias
        IF (P_COUNT > 3) THEN
            raise_application_error(-20006, 'Não é permitido cadastrar mais de 3 períodos de férias para a mesma aquisição.');
        END IF;

        -- Número total de dias de férias não pode ser superior a 30 dias
        IF (I_TOTALFERIAS + :NEW.NUMDIASFER > 30) THEN
            raise_application_error(-20007, 'O número total de dias de férias não pode exceder 30 dias.');
        END IF;

        -- Verifica se a data de início das férias coincide com o dia de descanso semanal
        SELECT FC_DSRFUNC_DCCO(COD_EMP, COD_FUNC, :NEW.DTPREVISTA) INTO DSR FROM DUAL;
        IF (DSR = 'S') THEN
            raise_application_error(-20008, 'A data de início das férias não pode coincidir com o dia de descanso semanal.');
        END IF;

        -- Verifica se a data de início das férias coincide com um feriado
        SELECT FC_FERFUNC_DCCO(COD_EMP, COD_FUNC, :NEW.DTPREVISTA) INTO FERIADO FROM DUAL;
        IF (FERIADO = 'S') THEN
            raise_application_error(-20009, 'A data de início das férias não pode coincidir com um feriado.');
        END IF;

        -- Verifica se a data de início das férias está pelo menos 3 dias antes de um feriado
        SELECT FC_FER3DIASFERIADO_DCCO(COD_EMP, COD_FUNC, :NEW.DTPREVISTA) INTO FERIADO FROM DUAL;
        IF (FERIADO = 'S') THEN
            raise_application_error(-20010, 'A data de início das férias deve estar pelo menos 3 dias antes de um feriado.');
        END IF;

        -- Férias só podem começar 3 dias antes do dia de descanso semanal do colaborador
        SELECT FC_FER3DIASDSR_DCCO(COD_EMP, COD_FUNC, :NEW.DTPREVISTA) INTO FER3DIASDSR FROM DUAL;
        IF (FER3DIASDSR = 'N') THEN
            raise_application_error(-20011, 'As férias devem começar pelo menos 3 dias antes do dia de descanso semanal do colaborador.');
        END IF;

        -- Verifica se as férias não estão sendo cadastradas durante o período de gozo do colaborador
        FOR I IN 1 .. P_COUNT LOOP
            SELECT FC_CALCDTFINALPERFERIAS(:NEW.NU, I) INTO DATA_FERIAS FROM DUAL;
            IF (DATA_FERIAS >= :NEW.DTPREVISTA) THEN
                raise_application_error(-20012, 'As férias não podem ser cadastradas durante o período de gozo do colaborador.');
            END IF;
        END LOOP;

        -- Não permitir que o período de férias informado seja maior que a data final do período de aquisição
        IF ((DTFIMFERIAS - 1) > DTFERDOBRADA) THEN
            raise_application_error(-20013, 'O período de férias não pode exceder a data final do período de aquisição.');
        END IF;

        -- Notificar o gerente sobre o cadastro das férias do colaborador
        SELECT NVL(FUNCIONARIO.CODFUNCSUP, 0), FUNCIONARIO.CODEMPFUNCSUP, FUNCIONARIO.NOMEFUNC, FUNCIONARIO.CODUSU
        INTO CODFUNC_GERENTE, CODEMP_GERENTE, NOME_COLABORADOR, USUARIOGERENTE
        FROM TFPFUN FUNCIONARIO
        WHERE FUNCIONARIO.CODFUNC = COD_FUNC
            AND FUNCIONARIO.CODEMP = COD_EMP;

        IF CODFUNC_GERENTE > 0 THEN
            -- Notificar o gerente
            S_TEXTO := S_COLAB;
            PROC_NOTIF_FERIAS_GER_DCCO(CODFUNC_GERENTE, CODEMP_GERENTE, NOME_COLABORADOR);
            COMMIT;
        END IF;
    END IF;

    IF UPDATING THEN
        -- Updation logic
        SELECT AD_PROGFERIAS.CODFUNC, AD_PROGFERIAS.CODEMP INTO COD_FUNC, COD_EMP FROM AD_PROGFERIAS WHERE AD_PROGFERIAS.NU = :NEW.NU;
        SELECT COUNT(NUAQUI) INTO P_COUNT FROM AD_PERAQFERIAS WHERE NU = :OLD.NU AND STATUS <> 'C';
        SELECT SUM(NUMDIASFER) INTO I_TOTALFERIAS FROM AD_PERAQFERIAS WHERE NU = :NEW.NU;

        -- Férias só depois da data final de aquisição
        SELECT MAX(FER.DTFINAQUI) INTO DATA_FINAL_AQUISICAO FROM TFPFER FER WHERE FER.CODFUNC = COD_FUNC AND FER.CODEMP = COD_EMP;  -- VILSON CODEMP
        IF (:NEW.DTPREVISTA <= DATA_FINAL_AQUISICAO) THEN
            raise_application_error(-20014, 'A data de início das férias deve ser posterior à data final de aquisição.');
        END IF;

        -- Data não pode ser menor que a data de hoje
        IF (:NEW.DTPREVISTA < SYSDATE) THEN
            raise_application_error(-20015, 'A data de início das férias não pode ser anterior à data atual.');
        END IF;

        -- Nenhum período de férias pode ser menor que 5 dias
        IF (:NEW.NUMDIASFER < 5) THEN
            raise_application_error(-20016, 'O período de férias deve ter no mínimo 5 dias.');
        END IF;

        -- Nenhum período de férias pode ser maior que 30 dias
        IF (:NEW.NUMDIASFER > 30) THEN
            raise_application_error(-20017, 'O período de férias não pode exceder 30 dias.');
        END IF;

        -- Se houver mais de 1 período de férias, pelo menos 1 deve ter pelo menos 14 dias
        IF (P_COUNT = 2) THEN
            -- Pega o maior número de dias já lançado
            SELECT MAX(NUMDIASFER) INTO I_MAIORDIA FROM AD_PERAQFERIAS WHERE NU = :NEW.NU;
            
            IF (I_MAIORDIA < 14) THEN
                IF (:NEW.NUMDIASFER < 14) THEN
                    raise_application_error(-20018, 'Pelo menos um período de férias deve ter no mínimo 14 dias.');
                END IF;
            END IF;
        END IF;

        -- Podem haver no máximo 3 períodos de férias por aquisição de férias
        IF (P_COUNT > 3) THEN
            raise_application_error(-20019, 'Não é permitido cadastrar mais de 3 períodos de férias para a mesma aquisição.');
        END IF;

        -- Número total de dias de férias não pode ser superior a 30 dias
        IF (I_TOTALFERIAS + :NEW.NUMDIASFER > 30) THEN
            raise_application_error(-20020, 'O número total de dias de férias não pode exceder 30 dias.');
        END IF;

        -- Verifica se a data de início das férias coincide com o dia de descanso semanal
        SELECT FC_DSRFUNC_DCCO(COD_EMP, COD_FUNC, :NEW.DTPREVISTA) INTO DSR FROM DUAL;
        IF (DSR = 'S') THEN
            raise_application_error(-20021, 'A data de início das férias não pode coincidir com o dia de descanso semanal.');
        END IF;

        -- Verifica se a data de início das férias coincide com um feriado
        SELECT FC_FERFUNC_DCCO(COD_EMP, COD_FUNC, :NEW.DTPREVISTA) INTO FERIADO FROM DUAL;
        IF (FERIADO = 'S') THEN
            raise_application_error(-20022, 'A data de início das férias não pode coincidir com um feriado.');
        END IF;

        -- Verifica se a data de início das férias está pelo menos 3 dias antes de um feriado
        SELECT FC_FER3DIASFERIADO_DCCO(COD_EMP, COD_FUNC, :NEW.DTPREVISTA) INTO FERIADO FROM DUAL;
        IF (FERIADO = 'S') THEN
            raise_application_error(-20023, 'A data de início das férias deve estar pelo menos 3 dias antes de um feriado.');
        END IF;

        -- Férias só podem começar 3 dias antes do dia de descanso semanal do colaborador
        SELECT FC_FER3DIASDSR_DCCO(COD_EMP, COD_FUNC, :NEW.DTPREVISTA) INTO FER3DIASDSR FROM DUAL;
        IF (FER3DIASDSR = 'N') THEN
            raise_application_error(-20024, 'As férias devem começar pelo menos 3 dias antes do dia de descanso semanal do colaborador.');
        END IF;

        -- Verifica se as férias não estão sendo cadastradas durante o período de gozo do colaborador
        FOR I IN 1 .. P_COUNT LOOP
            SELECT FC_CALCDTFINALPERFERIAS(:NEW.NU, I) INTO DATA_FERIAS FROM DUAL;
            IF (DATA_FERIAS >= :NEW.DTPREVISTA) THEN
                raise_application_error(-20025, 'As férias não podem ser cadastradas durante o período de gozo do colaborador.');
            END IF;
        END LOOP;

        -- Não permitir que o período de férias informado seja maior que a data final do período de aquisição
        IF ((DTFIMFERIAS - 1) > DTFERDOBRADA) THEN
            raise_application_error(-20026, 'O período de férias não pode exceder a data final do período de aquisição.');
        END IF;

        -- Verifica se houve alteração no status das férias
        IF (:OLD.STATUS <> :NEW.STATUS) THEN
            IF (:NEW.STATUS = 'AP') THEN
                -- Realizar ações para férias aprovadas
                STP_FECHAFERIAS_DCCO(:NEW.NU);
                SEND_AVISO2(NULL, 'Férias Aprovadas Portal RH', 'Férias aprovadas no Portal RH e na Programação de Férias', 1, 0, 2);  -- Grupo Analistas TI
                SEND_AVISO2(NULL, 'Férias Aprovadas Portal RH', 'Férias aprovadas no Portal RH e na Programação de Férias', 1, 0, 23); -- Grupo DP SUPERVISAO
                SEND_AVISO2(NULL, 'Férias Aprovadas Portal RH', 'Férias aprovadas no Portal RH e na Programação de Férias', 1, 0, 24); -- Grupo DP ANALISTAS
                COMMIT;
            END IF;
        END IF;
    END IF;
END;
/
