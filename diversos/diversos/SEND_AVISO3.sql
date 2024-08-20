CREATE OR REPLACE PROCEDURE SANKHYA.SEND_AVISO3 (
    P_TO      NUMBER,        -- Informa para qual usuário será enviada a mensagem
    P_SUBJECT VARCHAR2,      -- Informa o problema
    P_MSG     VARCHAR2,      -- Informa a solução
    P_PRIORI  NUMBER DEFAULT 3,  -- Nível de prioridade: 3: Baixa; 2: Médio; 1: Alta; 0: Super Urgente (Aviso na tela)
    P_FROM    NUMBER DEFAULT STP_GET_CODUSULOGADO,  -- Cód. do usuário que está mandando o aviso
    P_GTO     NUMBER DEFAULT NULL  -- Informa qual grupo será enviado a mensagem, se nulo, será obrigatório o cód. do usuário
) AS
    P_NEXTNUAVISO  NUMBER;
    V_FROM         NUMBER := P_FROM;
    V_TO           NUMBER := P_TO;
    V_GTO          NUMBER := P_GTO;
    V_PRIORI       NUMBER;
    V_WHO          VARCHAR2(4000);
    P_COUNT        NUMBER;
BEGIN
    -- Ajuste de prioridade
    V_PRIORI := CASE 
                    WHEN P_PRIORI IS NULL THEN 3 
                    WHEN P_PRIORI > 3 THEN 3 
                    WHEN P_PRIORI < 0 THEN 0 
                    ELSE P_PRIORI 
                END;

    -- Validação do remetente (P_FROM)
    SELECT COUNT(*)
    INTO P_COUNT
    FROM TSIUSU
    WHERE CODUSU = V_FROM;

    IF P_COUNT <= 0 THEN
        V_FROM := NULL;
    ELSE
        -- Buscar nome do remetente
        SELECT NOMEUSU INTO V_WHO FROM TSIUSU WHERE CODUSU = V_FROM;
    END IF;

    -- Validação do destinatário (P_TO) ou grupo (P_GTO)
    IF V_TO IS NOT NULL THEN
        SELECT COUNT(*)
        INTO P_COUNT
        FROM TSIUSU
        WHERE CODUSU = V_TO;
    ELSIF V_GTO IS NOT NULL THEN
        SELECT COUNT(*)
        INTO P_COUNT
        FROM TSIGRU
        WHERE CODGRUPO = V_GTO;
    ELSE
        P_COUNT := 0;
    END IF;

    IF P_COUNT <= 0 THEN
        V_TO := NULL;
        V_GTO := NULL;
    END IF;

    -- Verificação final e inserção do aviso
    IF V_FROM IS NOT NULL AND NVL(V_TO, V_GTO) IS NOT NULL AND P_SUBJECT IS NOT NULL THEN
        SELECT NVL(MAX(NUAVISO), 0) + 1 INTO P_NEXTNUAVISO FROM TSIAVI;

        INSERT INTO TSIAVI (
            NUAVISO,
            TITULO,
            DESCRICAO,
            SOLUCAO,
            IDENTIFICADOR,
            IMPORTANCIA,
            CODUSU,
            CODGRUPO,
            TIPO,
            DHCRIACAO,
            CODUSUREMETENTE,
            NUAVISOPAI,
            DTEXPIRACAO
        ) VALUES (
            P_NEXTNUAVISO,
            V_WHO,
            P_SUBJECT,
            SUBSTR(P_MSG, 0, 2000),
            'PERSONALIZADO',
            V_PRIORI,
            V_TO,
            V_GTO,
            'P',
            SYSDATE - (CASE WHEN V_PRIORI = 0 THEN 0.1 / 24 ELSE 0 END),
            V_FROM,
            NULL,
            SYSDATE + (CASE WHEN V_PRIORI = 0 THEN 1 / 24 ELSE 0 END)
        );
    END IF;
END;
/
