CREATE OR REPLACE TRIGGER TRG_IU_TSIUSU_AFT_DCCO
    AFTER INSERT OR UPDATE
    ON TSIUSU
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
DECLARE
    V_NUCHAVE    NUMBER;
    V_COUNT      NUMBER;
    P_MSG        VARCHAR2 (32000);
    P_CODCARGO   NUMBER;
    P_CODDEPT    NUMBER;
    P_NOMEFUNC   VARCHAR2 (4000);
    P_DESCRDEP   VARCHAR2 (4000);
    V_SKYPE      VARCHAR2 (100);
    P_EMAIL      VARCHAR2 (100); 
    V_EMAIL_FINAL VARCHAR2(100);
    
    PRAGMA AUTONOMOUS_TRANSACTION;
    
/* Atualizado em 08/01/2025 13:45
 * Autor: Danilo Fernando <danilo.bossanova@hotmail.com>
 * Descrição: Na atualização, é inserido e-mail e skype automaticamente
 * na agenda online. O email pode vir tanto da tabela TSIUSU quanto da TFPFUN,
 * priorizando o email da TSIUSU quando existir.
 */

BEGIN
    -- ATUALIZAÇÃO
    IF UPDATING AND :NEW.CODUSU != 0 THEN
        BEGIN
            SELECT F.CODCARGO,
                   F.CODDEP,
                   INITCAP (F.NOMEFUNC),
                   INITCAP (DEP.DESCRDEP),
                   F.EMAIL
              INTO P_CODCARGO,
                   P_CODDEPT,
                   P_NOMEFUNC,
                   P_DESCRDEP,
                   P_EMAIL
              FROM TFPFUN F 
              LEFT JOIN TFPDEP DEP ON DEP.CODDEP = F.CODDEP
             WHERE CODEMP = :NEW.CODEMP AND CODFUNC = :NEW.CODFUNC;
             
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                P_CODCARGO := 0;
                P_CODDEPT := 0;
                P_EMAIL := NULL;
        END;

        IF P_CODCARGO <> 0 AND P_CODDEPT <> 0 THEN
            -- Define qual email será usado, priorizando o da TSIUSU
            V_EMAIL_FINAL := NVL(:NEW.EMAIL, P_EMAIL);
            
            -- Determina o Skype baseado no email definido
            IF V_EMAIL_FINAL IS NOT NULL THEN
                V_SKYPE := DETERMINAR_SKYPE_DCCO(V_EMAIL_FINAL);
            END IF;
        
            UPDATE AD_TBTIAGENDAONLINE
               SET CODEMP = :NEW.CODEMP,
                   CODFUNC = :NEW.CODFUNC,
                   ATIVO = NVL (:NEW.AD_STATUS, 'N'),
                   NUMID = 2,
                   CODCARGO = P_CODCARGO,
                   CODDEPT = P_CODDEPT,
                   NOMECOMPLT = NVL (NOMECOMPLT, NVL (P_NOMEFUNC, :NEW.NOMEUSU)),
                   DEPARTAMENTO = NVL (DEPARTAMENTO, P_DESCRDEP),
                   EMAIL = V_EMAIL_FINAL,
                   SKYPE = V_SKYPE,
                   TELEFONEOPC = :NEW.AD_RAMAL
             WHERE CODUSU = :NEW.CODUSU;

            UPDATE AD_EQPGRUPOGER
               SET CODEMP = :NEW.CODEMP, 
                   CODFUNC = :NEW.CODFUNC
             WHERE CODEMP = :OLD.CODEMP 
               AND CODFUNC = :OLD.CODFUNC;
        END IF;
        
    -- INSERÇÃO
    ELSIF INSERTING THEN
        BEGIN
            SELECT F.CODCARGO,
                   F.CODDEP,
                   INITCAP (F.NOMEFUNC),
                   INITCAP (DEP.DESCRDEP),
                   F.EMAIL
              INTO P_CODCARGO,
                   P_CODDEPT,
                   P_NOMEFUNC,
                   P_DESCRDEP,
                   P_EMAIL
              FROM TFPFUN F 
              LEFT JOIN TFPDEP DEP ON DEP.CODDEP = F.CODDEP
             WHERE CODEMP = :NEW.CODEMP AND CODFUNC = :NEW.CODFUNC;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                P_CODCARGO := 0;
                P_CODDEPT := 0;
                P_EMAIL := NULL;
        END;
        
        -- Define qual email será usado, priorizando o da TSIUSU
        V_EMAIL_FINAL := NVL(:NEW.EMAIL, P_EMAIL);
        
        -- Determina o Skype baseado no email definido
        IF V_EMAIL_FINAL IS NOT NULL THEN
            V_SKYPE := DETERMINAR_SKYPE_DCCO(V_EMAIL_FINAL);
        END IF;

        INSERT INTO AD_TBTIAGENDAONLINE (
            CODUSU, CODVEND, CODEMP, CODFUNC, ATIVO, CODPARC, 
            CODCARGO, CODDEPT, NUMID, NOMECOMPLT, DEPARTAMENTO,
            EMAIL, SKYPE, TELEFONEOPC
        ) VALUES (
            :NEW.CODUSU, :NEW.CODVEND, :NEW.CODEMP, :NEW.CODFUNC,
            NVL(:NEW.AD_STATUS,'N'), :NEW.CODPARC, P_CODCARGO, P_CODDEPT,
            2, P_NOMEFUNC, P_DESCRDEP, V_EMAIL_FINAL, V_SKYPE, :NEW.AD_RAMAL
        );
    END IF;

    COMMIT;
END;
/