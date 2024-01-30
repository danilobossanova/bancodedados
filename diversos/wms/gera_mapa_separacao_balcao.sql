-- C�digo usado para montar o mapa de separa��o balc�o
SELECT
    SEP.NUSEPARACAO,
    SEP.DTSEPARACAO,
    ITT.CODPROD,
    ITT.CONTROLE,
    PRO.DESCRPROD,
    PRO.USACONTPESOVAR,
    PRO.CODVOLPESOVAR,
    CASE
        WHEN VOA.DIVIDEMULTIPLICA = 'M' THEN ROUND(ITT.QTDORIG * VOA.QUANTIDADE, 0)
        ELSE
            CASE
                WHEN VOA.DIVIDEMULTIPLICA = 'D' THEN ROUND(ITT.QTDORIG / VOA.QUANTIDADE, 0)
                ELSE 0
            END
    END AS QTDPESOVAR,
    CASE
        WHEN ITT.QTDORIG = ROUND(ITT.QTDORIG, 0) THEN ITT.CODVOLORIG
        ELSE PRO.CODVOL
    END AS CODVOLORIG,
    CASE
        WHEN ITT.QTDORIG = ROUND(ITT.QTDORIG, 0) THEN ITT.QTDORIG
        ELSE
            CASE
                WHEN VOA.CODVOL IS NULL THEN ITT.QTDORIG
                ELSE
                    CASE
                        WHEN VOA.DIVIDEMULTIPLICA = 'M' THEN ROUND(ITT.QTDORIG * VOA.QUANTIDADE, 0)
                        ELSE ROUND(ITT.QTDORIG / VOA.QUANTIDADE, 0)
                    END
            END
    END AS QTDORIG,
    CASE
        WHEN EXISTS (
                SELECT 1
                FROM TGWTDP TDP
                         INNER JOIN TGWITT ITTR
                                    ON (ITTR.NUTAREFA = TDP.NUTAREFA AND ITTR.SEQUENCIA = TDP.SEQUENCIA)
                WHERE TDP.NUTAREFADEP = ITT.NUTAREFA
                  AND ITTR.CODPROD = ITT.CODPROD
                  AND ITTR.CONTROLE = ITT.CONTROLE
                  AND ITTR.CODENDDESTINO = ITT.CODENDORIGEM
                  AND ITTR.SITUACAO NOT IN ('C', 'F')
            ) THEN '*'
        ELSE ' '
    END AS REABASTECIMENTO,
    SEP.CODAREACONF,
    ARC.NOMEAREACONF,
    CAB.NUMNOTA,
    CAB.NUNOTA,
    ED.ENDERECO AS DESTINO,
    EO.DESCREND AS ORIGEM,
    ED.DESCREND AS DESCRENDDESTINO,
    ED.CODEND AS CODENDDESTINO,
    EO.ORDEM,
    SEP.ORDEMCARGA,
    PRO.COMPLDESC,
    PRO.REFERENCIA,
    PAR.RAZAOSOCIAL AS NOMEPARCEIRO,
    PAR.CODPARC,
    CAB.CODTIPVENDA,
    TPV.DESCRTIPVENDA,
    REG.NOMEREG,
    PAR.CODREG,
    ITT.IDMAPA,
    CAB.CODVEND,
    VEN.APELIDO,
    CAB.AD_TIPOENTREGA,
    CAB.CODPARCTRANSP,
    PAT.NOMEPARC AS NOMETRANSP,
    TAR.NUTAREFA,
    CASE
        WHEN CAB.AD_TIPOENTREGA = 'R' THEN 'RETIRA LOJA'
        WHEN CAB.AD_TIPOENTREGA = 'B' THEN 'CLIENTE BALC�O'
        WHEN CAB.AD_TIPOENTREGA = 'E' THEN 'ENTREGAR'
        WHEN CAB.AD_TIPOENTREGA = 'T' THEN 'TRANSPORTADORA'
        WHEN CAB.AD_TIPOENTREGA = 'TT' THEN 'ENTREGAR/COBRAR'
        ELSE 'DEFINIR TIPO ENTREGA'
    END AS TIPORET,
    ITT.DHIMPMAPA,
    (SELECT COUNT(*) FROM TGWSEP WHERE TGWSEP.NUNOTA = CAB.NUNOTA) as TOTALMAPAS
FROM
    TGWSEP SEP
    INNER JOIN TGWTAR TAR ON (TAR.NUTAREFA = SEP.NUTAREFA)
    INNER JOIN TGWITT ITT ON (ITT.NUTAREFA = TAR.NUTAREFA)
    INNER JOIN TGWEND EO ON (ITT.CODENDORIGEM = EO.CODEND)
    INNER JOIN TGWEND ED ON (ITT.CODENDDESTINO = ED.CODEND)
    INNER JOIN TGFPRO PRO ON (PRO.CODPROD = ITT.CODPROD)
    INNER JOIN TGWARC ARC ON (ARC.CODAREACONF = SEP.CODAREACONF)
    LEFT JOIN TGFORD OC ON (OC.CODEMP = SEP.CODEMPOC AND OC.ORDEMCARGA = SEP.ORDEMCARGA)
    INNER JOIN (
        SELECT
            S.NUSEPARACAO,
            MAX(S.NUNOTA) AS NUNOTA
        FROM
            TGWSXN S
        WHERE
            S.STATUSNOTA <> 'C'
        GROUP BY
            S.NUSEPARACAO
    ) SXN ON (SXN.NUSEPARACAO = SEP.NUSEPARACAO)
    INNER JOIN TGFCAB CAB ON (CAB.NUNOTA = SXN.NUNOTA)
    INNER JOIN TGFPAR PAR ON (PAR.CODPARC = CAB.CODPARC)
    INNER JOIN TSIREG REG ON (REG.CODREG = PAR.CODREG)
    INNER JOIN TGFVEN VEN ON (VEN.CODVEND = CAB.CODVEND)
    INNER JOIN TGFPAR PAT ON (PAT.CODPARC = CAB.CODPARCTRANSP)
    INNER JOIN TGFTPV TPV ON (CAB.CODTIPVENDA = TPV.CODTIPVENDA AND CAB.DHTIPVENDA = TPV.DHALTER)
    LEFT JOIN TGFVOA VOA ON (VOA.CODPROD = ITT.CODPROD AND VOA.CODVOL = (CASE
        WHEN PRO.USACONTPESOVAR = 'S' AND PRO.CODVOLPESOVAR IS NOT NULL THEN PRO.CODVOLPESOVAR
        ELSE ITT.CODVOLORIG
    END))
WHERE
    SEP.NUSEPARACAO = $P{PK_NUSEPARACAO}
ORDER BY
    CODAREACONF,
    SEP.NUMNOTA,
    EO.DESCREND,
    EO.ORDEM;
