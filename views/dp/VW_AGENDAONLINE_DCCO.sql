CREATE OR REPLACE VIEW VW_AGENDAONLINE_DCCO AS
SELECT
    NOME_COMPLETO,
    NOME_ABREVIADO,
    COD_EMP,
    COD_FUNC,
    COD_USU,
    USUARIO_AD,
    NOME_FANTASIA,
    COMEMORA_ANIVERSARIO,
    DEPARTAMENTO,
    CARGO,
    DEPARTAMENTO_FUNCAO,
    FUNCAO_DEPARTAMENTO,
    CARGO_VERSARIO,
    DATA_NASCIMENTO,
    DATA_ADMISSAO,
    TEMPO_DECASA,
    COMPLETA_HOJE,
    TELEFONE_OPCIONAL,
    WHATSAPP,
    RAMAL_TELEFONE,
    RAMAL,
    TELEFONE,
    TELEFONE_RAMAL,
    SKYPE,
    ANIVERSARIO,
    FOTO,
    STATUS
FROM (
    -- Primeira parte da query
    SELECT
        DISTINCT FUN.NOMEFUNC AS NOME_COMPLETO,
        FC_ABREVIAR_NOME_DCCO(FC_TIRA_ACENTO_DCCO(AO.NOMECOMPLT),30) AS NOME_ABREVIADO,
        FUN.CODEMP AS COD_EMP,
        FUN.CODFUNC AS COD_FUNC,
        USU.CODUSU AS COD_USU,
        LOWER(NVL(USU.AD_WINDOWSAD, GERAR_USUARIO(FUN.EMAIL,FUN.NOMEFUNC))) AS USUARIO_AD,
        EMP.RAZAOABREV AS NOME_FANTASIA,
        'SIM' AS COMEMORA_ANIVERSARIO,
        NVL(AO.DEPARTAMENTO,'_') AS DEPARTAMENTO,
        NVL(AO.CARGO,'_') AS CARGO,
        fc_cargo_funcao_dcco(AO.DEPARTAMENTO,AO.CARGO, 'SIM') AS DEPARTAMENTO_FUNCAO,
        fc_cargo_funcao_dcco(AO.DEPARTAMENTO,AO.CARGO, 'NAO') AS FUNCAO_DEPARTAMENTO,
        AO.CARGOVERSARIO AS CARGO_VERSARIO,
        FUN.DTNASC AS DATA_NASCIMENTO,
        FUN.DTADM AS DATA_ADMISSAO,
        TRUNC(MONTHS_BETWEEN(SYSDATE, NVL(AO.DTADM,FUN.DTADM)) / 12) AS TEMPO_DECASA,
        EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM NVL(AO.DTADM,FUN.DTADM))  AS COMPLETA_HOJE,
        fc_ramal_dcco(AO.DDD,AO.TELEFONEOPC,2) AS TELEFONE_OPCIONAL,
        fc_ramal_dcco(AO.DDD,AO.WHATSAPP,2) AS WHATSAPP,
        fc_ramaltelefone_dcco(fc_ramal_dcco(AO.DDD,AO.RAMAL,1),fc_ramal_dcco(AO.DDD,AO.TELEFONE,2)) AS RAMAL_TELEFONE,
        AO.RAMAL,
        TRIM(TRAILING ' ' FROM TRIM(TRUNC(SUBSTR(EMP.TELEFONE, 0, 4))) || ' ' || TRIM(SUBSTR(EMP.TELEFONE, 5, 4)) || ' ' || TRIM(SUBSTR(EMP.TELEFONE, 9))) AS TELEFONE, -- Remove quaisquer espaços em branco à direita da concatenação dos números
        fc_ramaltelefone_dcco(TRIM(TRAILING ' ' FROM TRIM(TRUNC(SUBSTR(EMP.TELEFONE, 0, 4))) || ' ' || TRIM(SUBSTR(EMP.TELEFONE, 5, 4)) || ' ' || TRIM(SUBSTR(EMP.TELEFONE, 9))), AO.RAMAL) AS TELEFONE_RAMAL,
        AO.SKYPE,
        TO_CHAR(AO.DTNASC,'DD/MM') AS ANIVERSARIO,
        FC_URLIMGFUNC_DCCO(FUN.CODEMP,FUN.CODFUNC) AS FOTO,
        AO.ATIVO AS STATUS

    FROM TFPFUN FUN
    INNER JOIN TSIEMP EMP ON EMP.CODEMP = FUN.CODEMP
    INNER JOIN TSIUSU USU ON USU.CODFUNC = FUN.CODFUNC AND USU.CODEMP = FUN.CODEMP
    INNER JOIN AD_TBTIAGENDAONLINE AO ON AO.CODFUNC = FUN.CODFUNC AND AO.CODEMP = FUN.CODEMP

    WHERE FUN.SITUACAO = 1
    AND USU.DTLIMACESSO IS NULL
    AND AO.ATIVO = 'S'

    UNION

    -- Segunda parte da query
    SELECT
        DISTINCT AO.NOMECOMPLT AS NOME_COMPLETO,
        FC_ABREVIAR_NOME_DCCO(FC_TIRA_ACENTO_DCCO(AO.NOMECOMPLT),30) AS NOME_ABREVIADO,
        AO.CODEMP AS COD_EMP,
        AO.CODFUNC AS COD_FUNC,
        USU.CODUSU AS COD_USU,
        LOWER(USU.AD_WINDOWSAD) AS USUARIO_AD,
        EMP.RAZAOABREV AS NOME_FANTASIA,
        'SIM' AS COMEMORA_ANIVERSARIO,
        NVL(AO.DEPARTAMENTO,'_') AS DEPARTAMENTO,
        NVL(AO.CARGO,'_') AS CARGO,
        fc_cargo_funcao_dcco(AO.DEPARTAMENTO,AO.CARGO, 'SIM') AS DEPARTAMENTO_FUNCAO,
        fc_cargo_funcao_dcco(AO.DEPARTAMENTO,AO.CARGO, 'NAO') AS FUNCAO_DEPARTAMENTO,
        AO.CARGOVERSARIO AS CARGO_VERSARIO,
        AO.DTNASC AS DATA_NASCIMENTO,
        AO.DTADM AS DATA_ADMISSAO,
        TRUNC(MONTHS_BETWEEN(SYSDATE, NVL(AO.DTADM,SYSDATE)) / 12) AS TEMPO_DECASA,
        EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM NVL(AO.DTADM,SYSDATE))  AS COMPLETA_HOJE,
        fc_ramal_dcco(AO.DDD,AO.TELEFONEOPC,2) AS TELEFONE_OPCIONAL,
        fc_ramal_dcco(AO.DDD,AO.WHATSAPP,2) AS WHATSAPP,
        fc_ramaltelefone_dcco(fc_ramal_dcco(AO.DDD,AO.RAMAL,1),fc_ramal_dcco(AO.DDD,AO.TELEFONE,2)) AS RAMAL_TELEFONE,
        AO.RAMAL,
        TRIM(TRAILING ' ' FROM TRIM(TRUNC(SUBSTR(EMP.TELEFONE, 0, 4))) || ' ' || TRIM(SUBSTR(EMP.TELEFONE, 5, 4)) || ' ' || TRIM(SUBSTR(EMP.TELEFONE, 9))) AS TELEFONE, -- Remove quaisquer espaços em branco à direita da concatenação dos números
        fc_ramaltelefone_dcco(TRIM(TRAILING ' ' FROM TRIM(TRUNC(SUBSTR(EMP.TELEFONE, 0, 4))) || ' ' || TRIM(SUBSTR(EMP.TELEFONE, 5, 4)) || ' ' || TRIM(SUBSTR(EMP.TELEFONE, 9))), AO.RAMAL) AS TELEFONE_RAMAL,
        AO.SKYPE,
        TO_CHAR(AO.DTNASC,'DD/MM') AS ANIVERSARIO,
        FC_URLIMGUSUARIO_DCCO(USU.CODUSU) AS FOTO,
        AO.ATIVO AS STATUS

    FROM AD_TBTIAGENDAONLINE AO
    INNER JOIN TSIEMP EMP ON EMP.CODEMP = AO.CODEMP
    INNER JOIN TSIUSU USU ON AO.CODUSU = USU.CODUSU

    WHERE USU.AD_PJ = 'S'
    AND USU.DTLIMACESSO IS NULL
    AND AO.ATIVO = 'S'
);