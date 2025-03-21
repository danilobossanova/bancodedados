CREATE OR REPLACE TRIGGER TRG_INC_UPD_TGFCAB_DCCO_SER
    before insert or update
    on TGFCAB
    for each row
DECLARE
   P_EMAIL         TSIUSU.EMAIL%TYPE;
   P_CONTAP        INT;
   P_PRAZOVENC     INT;
   P_QTDMECANICO   INT;
   P_TEMSERVICO    INT;
   P_TIPVEND       CHAR;
   P_CODPARC       NUMBER;
   P_MARCASCOD     NUMBER;
   P_MODELOCOD     NUMBER;
   V_CODPROJ       NUMBER;
   P_QTDINSPECAO   INT;
   P_IDINSP        INT;
   P_TOPCOMPRA     CHAR(1);
   P_CODUSU        NUMBER;
   P_PERCONF       CHAR(1);
   P_TEMNFFAT      INT;
   P_GRUPOTOP      VARCHAR2(50);
   P_TIPMOV        TGFTOP.TIPMOV%TYPE;
   V_COUNT         NUMBER;
   P_SITUACAONFE   NUMBER;
   
   P_COUNT                NUMBER;
   P_CODCENCUS            NUMBER;
   P_PRAZOVALID           NUMBER;
   
   P1_CODAPLI      NUMBER; 
   P1_MARCASCOD    VARCHAR2(100);
   P1_MODELOCOD    VARCHAR2(100);
   
   
   --- Verificacao wms __volumes
   EMPRESA_UTLIZAWMS        CHAR(1);
   PRODUTO_CONTROLADOWMS    CHAR(1);
   QTDVOLUME_REV            NUMBER;
   
   
BEGIN

  IF STP_GET_ATUALIZANDO THEN
    RETURN;
  END IF;
  
   P_EMAIL := 'ti@dcco.com.br';
   

   
   IF INSERTING AND EXISTE.TIPO_OPERACAO(:NEW.CODTIPOPER,52,'TOP_ORCAMENTO') = 'S' THEN
     
     SELECT INTEIRO
     INTO P_PRAZOVALID
     FROM TSIPAR PAR
     WHERE CHAVE = 'DIASVALPED';
     
     IF P_PRAZOVALID != 0 THEN
        :NEW.DTVAL := SYSDATE + P_PRAZOVALID;
     END IF;
     
   END IF;
   
   -- CRIADO POR: MARCUS VINICIUS OLIVEIRA SILVA
   -- DATA DA CRIAÇÃO: 20/09/2016 AS 08:41
   -- MOTIVO: TRATAR PARA INFORMAR A CHAVE NFE QUANDO A TOP ESTÁ MARCADA PARA NOTA DE TERCEIROS E O TIPO DE MOVIMENTO FOR COMPRA
   SELECT COUNT(*) INTO P_COUNT
   FROM TGFTOP TipoOperacao
   WHERE TipoOperacao.CODTIPOPER = :NEW.CODTIPOPER
   AND     TipoOperacao.DHALTER = :NEW.DHTIPOPER
   AND     NVL(TipoOperacao.NFE,'#') = 'T'
   AND     NVL(TipoOperacao.TIPMOV,'#') = 'C';
   
   
   -- VERIFICAR SE PERTENCE A REGRA NA TOP
    --ALTERADO POR LEANDRO.BRITO EM 27/02/2024 PARA ATENDER A NOVA REGRA DE IMPORTAR CTE PELO PORTAL DE COMPRAS
   IF P_COUNT > 0 
   AND ((:NEW.CHAVENFE IS NULL OR LENGTH(:NEW.CHAVENFE) <> 44) 
    AND (:NEW.CHAVECTE IS NULL OR LENGTH(:NEW.CHAVECTE) <> 44) ) -- LINHA INCLUÍDA POR LEANDRO.BRITO
   AND (UPDATING('NUMNOTA') OR UPDATING('SERIENOTA') OR UPDATING('CHAVENFE') OR (NVL(:NEW.STATUSNOTA,'#') = 'L' AND NVL(:OLD.STATUSNOTA,'#') != 'L')) 
   AND (UPDATING)
   AND NVL(:NEW.CODMODDOCNOTA,1) != 901 AND NOT VARIAVEIS_DCCO.V_TGFCAB_NOVALID_ANEXO THEN
        SHOW_RAISE('TGFCAB',47,VETOR('NUNOTA'),VETOR(:NEW.NUNOTA));     
   END IF;
   
   
   -- CRIADO POR: DANIEL BATISTA MACHADO
   -- DATA DA CRIAÇÃO: 23/11/2023 AS 15:29
   -- MOTIVO: VALIDAR A CHAVE DA NOTA DE ENTRADA COM  A CHAVE DO PORTAL DE XML PARA SABER A SITUAÇÃO DA NF SE ESTA AUTORIZADA O USO.
       BEGIN
         SELECT SITUACAONFE
           INTO P_SITUACAONFE 
           FROM TGFIXN 
          WHERE CHAVEACESSO = :NEW.CHAVENFE;
       EXCEPTION
       WHEN OTHERS THEN
            P_SITUACAONFE := 0;
       END;
  
       --  RAISE_APPLICATION_ERROR(-20101,  P_COUNT );
  
   IF P_COUNT > 0 AND P_SITUACAONFE IN(2,3) /*OR P_SITUACAONFE IS NULL*/ AND :NEW.CHAVENFE IS NOT NULL THEN
   
       SHOW_RAISE('TGFCAB',140,VETOR('NUNOTA'),VETOR(:NEW.NUNOTA)); 
   
   END IF; 
   
      
   -- Adicionado por: Marcus Vinicius
   -- Em: 04/12/2015 as 15:12
   -- Motivo: Informar a data de Aprovação do Orçamento, até o momento nas tops: 1760,1780
   IF NVL(:NEW.AD_STATUSORCA,'AGUARDANDO') = 'APROVADO' AND NVL(:OLD.AD_STATUSORCA,'AGUARDANDO') != 'APROVADO' 
       AND EXISTE.TIPO_OPERACAO(:NEW.CODTIPOPER,890,'ORCAMENTO_EXTERNO') = 'S'/* OBTER_DADO('AD_RELPARMAGRUTOP','COUNT(*)',
                VETOR('NURELPARM','DESCRICAO','CODTIPOPER'),
                VETOR(890,'ORCAMENTO_EXTERNO',:NEW.CODTIPOPER)) > 0*/ THEN
                
              :NEW.AD_DTAPROVORCA := SYSDATE;
              /*
   ELSIF NVL(:NEW.AD_STATUSORCA,'AGUARDANDO') != 'APROVADO' AND NVL(:OLD.AD_STATUSORCA,'AGUARDANDO') = 'APROVADO' AND EXISTE.TIPO_OPERACAO(:NEW.CODTIPOPER,890,'ORCAMENTO_EXTERNO') = 'S'*/
       /*AND OBTER_DADO('AD_RELPARMAGRUTOP','COUNT(*)',
                VETOR('NURELPARM','DESCRICAO','CODTIPOPER'),
                VETOR(890,'ORCAMENTO_EXTERNO',:NEW.CODTIPOPER)) > 0*/   /*THEN
                
                :NEW.AD_DTAPROVORCA := NULL;*/
   ELSE
                :NEW.AD_DTAPROVORCA := :OLD.AD_DTAPROVORCA;
   END IF;
   
   IF (INSERTING AND EXISTE.TIPO_OPERACAO(:NEW.CODTIPOPER,52,'TOP_PEDIDO') = 'S'
     /*AND OBTER_DADO('AD_RELPARMAGRUTOP','COUNT(*)',
                VETOR('NURELPARM','DESCRICAO','CODTIPOPER'),
                VETOR(52,'TOP_PEDIDO',:NEW.CODTIPOPER)) > 0*/ AND NVL(:NEW.AD_STATUSORCA,'AGUARDANDO') != 'APROVADO' AND STP_GET_CODUSULOGADO NOT IN (224)) 
  OR (STP_GET_CODUSULOGADO IN (224) AND EXISTE.TIPO_OPERACAO(:NEW.CODTIPOPER,52,'TOP_PEDIDO') = 'S' AND NVL(:NEW.AD_STATUSORCA,'AGUARDANDO') != 'APROVADO'
       AND :NEW.STATUSNOTA = 'L')
  THEN
          SHOW_RAISE('TGFCAB',49);      
   END IF;
   

    -- Adicionado por Vilson Ferreira - 28/01/2019
    -- Solicitação feita pelo Marcelo Resende
    -- Não deixar faturar orçamento na TOP 1760 com starus do orçamento diferente de Aprovado.

  IF (INSERTING AND EXISTE.TIPO_OPERACAO(:NEW.CODTIPOPER,52,'TOP_OS_SERV') = 'S' AND NVL(:NEW.AD_STATUSORCA,'AGUARDANDO') != 'APROVADO'  ) THEN
          SHOW_RAISE('TGFCAB',99);      
   END IF;
   
    -- Adicionado por Vilson Ferreira - 13/07/2020
    -- Solicitado por: Rilder Rabelo
    -- Motivo: Inserir a data de Aguardando Aprovação e a data de Atendimento Concluído.
    
      IF NVL(:NEW.AD_STATUSORCA,'AGUARDANDO') = 'AGUARDANDO'  THEN
         :NEW.AD_DTSTATUSMARAGUAPR := SYSDATE;
      END IF;
    
      IF NVL(:NEW.AD_STATUSORCA,'AGUARDANDO') = 'REAQUECINT' AND NVL(:OLD.AD_STATUSORCA,'AGUARDANDO') != 'REAQUECINT'  THEN
         :NEW.AD_DTATENDCONCL := SYSDATE;
      END IF;
      -- Fim 13/07/2020
      
   
/*   IF UPDATING
     AND OBTER_DADO('AD_RELPARMAGRUTOP','COUNT(*)',
                VETOR('NURELPARM','DESCRICAO','CODTIPOPER'),
                VETOR(890,'ORCAMENTO_EXTERNO',:NEW.CODTIPOPER)) > 0 AND NVL(:NEW.AD_STATUSORCA,'AGUARDANDO') != 'APROVADO' 
     AND NVL(:NEW.STATUSNOTA,'#') = 'L' AND NVL(:OLD.STATUSNOTA,'#') != 'L' THEN
          SHOW_RAISE('TGFCAB',49);      
   END IF;*/
   
   -- CRIADO POR: MARCUS VINICIUS OLIVEIRA SILVA
   -- DATA DA CRIAÇÃO: 08/07/2016 AS 15:13
   -- MOTIVO: TRATAR INDICAÇÃO
   IF INSERTING OR UPDATING THEN
      
      SELECT COUNT(*) INTO P_COUNT
      FROM TGFVEN V, TGFVEN V1
      WHERE V.CODVEND = NVL(:NEW.AD_CODVENDINDICACAO,0)
      AND   V.CODCENCUSPAD = V1.CODCENCUSPAD
      AND   V1.CODVEND = NVL(:NEW.CODVEND,-1);
      
      IF P_COUNT > 0 THEN
      
         SELECT CODCENCUSPAD INTO P_CODCENCUS
         FROM TGFVEN 
         WHERE CODVEND = :NEW.CODVEND;
         
         -- SE ESTIVER INSERINDO E O NOVO INDICADO FOR DIFERENTE DE ZERO OU SEJA DIFERENTE DO VENDEDOR INFORMADO OU
         -- ATUALIZANDO, O INDICADO SEJA DIFERENTE DE ZERO E O NOVO INDICADO DIFERENTE DO ANTIGO OU
         -- ATUALIZANDO E O NOVO VENDEDOR SEJA DIFERENTE DO ANTIGO
         IF (INSERTING AND NVL(:NEW.AD_CODVENDINDICACAO,0) != 0 AND NVL(:NEW.AD_CODVENDINDICACAO,0) != NVL(:NEW.CODVEND,0)) OR
            (UPDATING AND NVL(:NEW.AD_CODVENDINDICACAO,0) != 0 AND NVL(:NEW.AD_CODVENDINDICACAO,0) != NVL(:OLD.CODVEND,0)) OR
            (UPDATING AND NVL(:NEW.CODVEND,0) != NVL(:OLD.CODVEND,-1) AND (:OLD.AD_CODVENDINDICACAO IS NOT NULL)) THEN
            
            SHOW_RAISE('TGFCAB',38,VETOR('CODCENCUS'),VETOR(P_CODCENCUS));
            
         END IF;
      END IF;
      
   END IF;

   --Wanderlan
   --02/01/2014
   --Não permitir confirmação de notas de compra caso a TOP exige usuário cadastrado
   --Premissas: Se na TOP o campo (Exige Usuário Autorizado p/ Confirmar NF de Compra?:) estiver marcado,
   --          somente usuários marcados com a opção(Permite confirmar NF de Compra?:) poderão confirmar

--         RAISE_APPLICATION_ERROR (
--            -20101,   :NEW.AD_STATUS_OS);
   
-- ESTA FUNÇÃO (FC_CONSULTAOPER_CENVALID) RETORNA 0 SE FOR PERMITIDO OU 1 SE FOR NEGADO OU DIFERENTE DE 0 E 1 QUANDO NÃO FOR ENCONTRADO REGRA
IF FC_CONSULTAOPER_CENVALID(322,'TSICUS',:NEW.CODCENCUS,'TGFTOP',:NEW.CODTIPOPER) != 0 THEN
   --- VALIDAR SE A TOP EXIGIRÁ FECHAR ANTES DE FATURAR PARA NF OU NFSE
   
  SELECT COUNT(*) INTO V_COUNT
  FROM AD_RELPARMAGRUTOP
  WHERE DESCRICAO IN ('NFE','NFSE') AND NURELPARM = 655 AND CODTIPOPER = :NEW.CODTIPOPER;
  
  /*V_COUNT := OBTER_DADO('TGFTOP','COUNT(*)',VETOR('*CODTIPOPER','*DHALTER','NVL(AD_USATOPNAPESQREQ,''N'')'),
                                                         VETOR('(SELECT C.CODTIPOPER FROM TGFCAB C, TGFVAR V WHERE V.NUNOTA = '||:NEW.NUNOTA||' AND V.NUNOTAORIG = C.NUNOTA)',
                                                         '(SELECT C.DHTIPOPER FROM TGFCAB C, TGFVAR V WHERE V.NUNOTA = '||:NEW.NUNOTA||' AND V.NUNOTAORIG = C.NUNOTA)','S'));*/
/*  SELECT COUNT(*) INTO V_COUNT
  FROM TGFTOP
  WHERE (CODTIPOPER, DHALTER) = (SELECT C.CODTIPOPER, C.DHTIPOPER FROM TGFCAB C, TGFVAR V WHERE V.NUNOTA = :NEW.NUNOTA AND V.NUNOTAORIG = C.NUNOTA)
  AND      NVL(AD_USATOPNAPESQREQ,'N') = 'S';*/
  
  IF V_COUNT > 0 AND NVL(:NEW.AD_STATUS_OS,'ABERTA') <> 'FECHADA'  THEN
   
         RAISE_APPLICATION_ERROR (
            -20101,
            '<p align="center"><a href="http://www.sankhya.com.br" target="_blank"><img src="http://www.sankhya.com.br/imagens/logo-sankhya.png" width="250" height="60"></img></a></p><br><br><br><br><br><br>'
            || '<p align="left"><font size="12" face="arial" color="#8B1A1A"><b>Atencão: </b>Faturamento não permitido!!<br><br>'
            || '<b>Motivo: </b>Ordem de Serviço não foi fechada! <br><br>'
            || '<b>Solucão: </b>Efetue o fechamento da OS antes de prosseguir.<br><br>'
            || '<a href="mailto:'
            || P_EMAIL
            || '?subject=Erro na trigger TRG_INC_UPD_TGFCAB_DCCO_SER=Email enviada por erro em processo no sistema SankhyaW">'
            || '<p align="center"><font color="#0000CD"><b><i>Clique aqui</i></b></font> para enviar e-mail para o TI</p></a></font></p><br><br>'
            || '<p align="center"><font size="10" color="#008B45"><b>Informacães para o implantador e/ou equipe Sankhya</b></font>');
 
   
   END IF;
   

   
        /* Flávio Carneiro 27/11/2018
           Estava entrando em loop, o DHTIPOPER estava vindo como caracter*/
  /*      BEGIN     
                SELECT NVL(AD_PODECONFCOMPRA,'N') INTO P_TOPCOMPRA FROM TGFTOP TOP
                WHERE
                TOP.CODTIPOPER IN (:NEW.CODTIPOPER) AND
                TOP.DHALTER = :NEW.DHTIPOPER ;   
        EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20101,'TOP NÃO ENCONTRADA NA DATA - '||:NEW.DHTIPOPER);
        END;  
        
        
        IF P_TOPCOMPRA = 'S' AND :NEW.STATUSNOTA = 'L' AND NOT UPDATING('PENDENTE') THEN
        
          SELECT STP_GET_CODUSULOGADO INTO P_CODUSU FROM DUAL;
          
            SELECT NVL(USU.AD_PERMCONFCOMPRA,'N') INTO P_PERCONF FROM TSIUSU USU
            WHERE
            USU.CODUSU = P_CODUSU;
            
            
        
          IF P_PERCONF = 'N' THEN
          
             SHOW_RAISE('TGFCAB',9,VETOR('CODTIPOPER'),VETOR(:NEW.CODTIPOPER));  */
/*          RAISE_APPLICATION_ERROR (
             -20101,
                '<p align="center"><a href="http://www.sankhya.com.br" target="_blank"><img src="http://www.sankhya.com.br/imagens/logo-sankhya.png" width="250" height="60"></img></a></p><br><br><br><br><br><br>'
             || '<p align="left"><font size="12" face="arial" color="#8B1A1A"><b>Atencão: </b>Operação não permitida!<br><br>'
             || '<b>Motivo: </b>TOP: '||:NEW.CODTIPOPER||' exige que somente usuários autorizados confirmem a mesma.<br><br>'
             || '<b>Solucão: </b>Entre em contato com a TI e verifique seus acessos !.<br><br>'
             || '<a href="mailto:'
             || P_EMAIL
             || '?subject=Erro na trigger TRG_INC_UPD_TGFCAB_DCCO_SER=Email enviada por erro em processo no sistema SankhyaW">'
             || '<p align="center"><font color="#0000CD"><b><i>Clique aqui</i></b></font> para enviar e-mail para o TI</p></a></font></p><br><br>'
             || '<p align="center"><font size="10" color="#008B45"><b>Informacães para o implantador e/ou equipe Sankhya</b></font>');        */
        
    /*      END IF;
        
        END IF;*/



   IF     UPDATING ('NUMNOTA')
      AND :NEW.NUMNOTA <> :OLD.NUMNOTA
      AND NVL (:OLD.NUMNOTA, 0) = 0
   THEN
      UPDATE AD_APOTHRMEC
         SET NROS = :NEW.AD_NUMOSDIAG
         , CODEMP = :NEW.CODEMP
       WHERE NUNOTA = :NEW.NUNOTA;
   END IF;



--   IF     UPDATING
--      AND :NEW.AD_STATUS_OS = 'FECHADA' AND :OLD.AD_STATUS_OS = 'FECHADA'
--      AND :NEW.PENDENTE = 'S' 
--      AND :NEW.CODTIPOPER IN
--             (1799,
--              1796,
--              1792,
--              1794,
--              1795,
--              1793,
--              1765,
--              1767,
--              1766,
--              1080,
--              1081,
--              1082,
--              1083,
--              1084,
--              1085)
--   THEN
--      RAISE_APPLICATION_ERROR (
--         -20101,
--            '<p align="center"><a href="http://www.sankhya.com.br" target="_blank"><img src="http://www.sankhya.com.br/imagens/logo-sankhya.png" width="250" height="60"></img></a></p><br><br><br><br><br><br>'
--         || '<p align="left"><font size="12" face="arial" color="#8B1A1A"><b>Atencão: </b>Alteracão de OS não permitida!<br><br>'
--         || '<b>Motivo: </b>Ordem de Servico encontra-se Fechada. <br><br>'
--         || '<b>Solucão: </b>Certifique-se de que a OS não foi faturada e faca a reabertura da OS caso seja necessario!.<br><br>'
--         || '<a href="mailto:'
--         || P_EMAIL
--         || '?subject=Erro na trigger TRG_INC_UPD_TGFCAB_DCCO_SER=Email enviada por erro em processo no sistema SankhyaW">'
--         || '<p align="center"><font color="#0000CD"><b><i>Clique aqui</i></b></font> para enviar e-mail para o TI</p></a></font></p><br><br>'
--         || '<p align="center"><font size="10" color="#008B45"><b>Informacães para o implantador e/ou equipe Sankhya</b></font>');
--   END IF;



   --[PROCESSOS Gerais]
   --[CONSULTOR WANDERLAN]
   --[INICIANDO]

   -- O campo CODVOL devera sempre ser utilizado pelo campo adicional, pois conforme escopo, não pode ser informado automaticamente.
   -- Atualmente o sistema não possui parametro para que não atualize este campo

    /*
        @Author: Danilo Fernando <danilo.bossanova@hotmail.com>
        @date: 24/02/2025 15:10
        @Description: Ajuste para soma dos volumes . Com o uso do WMS, deverá levar em consideração os volumes informados na conferencia.

        EMPRESA_UTLIZAWMS        CHAR(1);
        PRODUTO_CONTROLADOWMS

    */

    -- Verifica se a empresa utilizawms
    STP_EMP_UTILIZAWMS_DCCO (:NEW.CODEMP,EMPRESA_UTLIZAWMS);
    
    IF (EMPRESA_UTLIZAWMS = 'S') THEN
    
    
        -- QUANTIDADE DE ETIQUETAS DE VOLUMES CONFORME TABELA DE ETIQUETA DE VOLUMES.
        PRC_CONTAR_LINHAS_TGWREV_DCCO(:NEW.NUNOTA, QTDVOLUME_REV);
        :NEW.QTDVOL := NVL(QTDVOLUME_REV,0);
    

        -- Se a empresa usa WMS, sincroniza QTDVOL e AD_QTDVOL
        -- verifica se já existe algum valor informado para o campo QTDVOL.
        IF ( NVL(:NEW.QTDVOL,0) > 0  ) THEN
        
            -- Se os campos tiverem valores diferentes
            IF :NEW.QTDVOL <>  :NEW.AD_QTDVOL THEN
                :NEW.AD_QTDVOL := :NEW.QTDVOL;
            END IF;
            

        ELSE
            -- Atribui pelo menos 1 volume o pedido, para evitar null ou zero.
            :NEW.QTDVOL     := 1;
            :NEW.AD_QTDVOL  := 1;
        
        END IF;

    ELSE
    
        /*:NEW.QTDVOL :=
            CASE WHEN :NEW.AD_QTDVOL IS NULL THEN 1 ELSE :NEW.AD_QTDVOL END; */
            
        -- Se não utiliza WMS, apenas define QTDVOL = AD_QTDVOL ou 1 por padrão
        :NEW.QTDVOL := NVL(:NEW.AD_QTDVOL, NVL(QTDVOLUME_REV,1));    
    
    END IF;    

-------------------------------------------------------------------------------------------

   --[PROCESSOS Gerais]
   --[CONSULTOR WANDERLAN]
   --[FINALIZANDO]



   --[PROCESSOS DE O.S. DCCO]
   --[CONSULTOR WANDERLAN]
   --[INICIANDO]

   --Wanderlan
   --13/06/2013
   --Ao confirmar o Nr. de serie do Motor no Cabecalho do Orcamento de OS, preencher os campos que est?o no cadastro de Motores
   
   IF EXISTE.TIPO_OPERACAO(:NEW.CODTIPOPER,935,'TOP_SERIE_MOTOR_DADOS_OS') = 'S'
         /*(1780,
          1781,
          1782,
          1783,
          1784,
          1785,
          1080,
          1081,
          1082,
          1083,
          1084,
          1085,
          -- NOROESTE
          1980,
          1981,
          1982,
          1983,
          1984,
          1985,
          1180,
          1181,
          1182,
          1183,
          1184,
          1185)*/
   THEN
      P_EMAIL := 'gustavo.pacheco@dcco.com.br';
      

      SELECT COUNT (*)
        INTO P_CONTAP
        FROM AD_CADMOTGER MOT
       WHERE MOT.SERIEMOTOR = nvl(:NEW.AD_SERIEMOTOR,0);
       
      SELECT COUNT(*) INTO P_COUNT
      FROM AD_RELPARMAGRUTOP
      WHERE NURELPARM = 876
      AND      DESCRICAO IN ('TOP_SERIE_MOTOR')
      AND      CODTIPOPER = :NEW.CODTIPOPER;
       
      IF P_CONTAP = 0 AND EXISTE.TIPO_OPERACAO(:NEW.CODTIPOPER,876,'TOP_SERIE_MOTOR') = 'N'/* P_COUNT <= 0*/
      THEN
         RAISE_APPLICATION_ERROR (
            -20101,
               '<p align="center"><a href="http://www.sankhya.com.br" target="_blank"><img src="http://www.sankhya.com.br/imagens/logo-sankhya.png" width="250" height="60"></img></a></p><br><br><br><br><br><br>'
            || '<p align="left"><font size="12" face="arial" color="#8B1A1A"><b>Atencão: </b>Parceiro invalido.<br><br>'
            || '<b>Motivo: </b>O campo "Serie do Motor" informado ('
            || :NEW.AD_SERIEMOTOR
            || ') não existe ou foi removido do "Cadastro de Motores".<br><br>'
            || '<b>Solucão: </b>Favor entrar em contato com os setores responsaveis.<br><br>'
            || '<a href="mailto:'
            || P_EMAIL
            || '?subject=Erro na trigger TRG_INC_UPD_TGFCAB_DCCO_SER=Email enviada por erro em processo no sistema SankhyaW">'
            || '<p align="center"><font color="#0000CD"><b><i>Clique aqui</i></b></font> para enviar e-mail para o TI</p></a></font></p><br><br>'
            || '<p align="center"><font size="10" color="#008B45"><b>Informacães para o implantador e/ou equipe Sankhya</b></font>');
      END IF;


       


      IF P_CONTAP > 0
      THEN
         -- Seta o Status do orcamento para aguardando a validacão do cliente
         IF :NEW.AD_STATUSORCA IS NULL
         THEN
            :NEW.AD_STATUSORCA := 'AGUARDANDO';
         END IF;

         SELECT INTEIRO
           INTO P_PRAZOVENC
           FROM TSIPAR PAR
          WHERE CHAVE LIKE 'PRAZOVENCORCAME';

         :NEW.DTVAL := SYSDATE + P_PRAZOVENC;
      END IF;

      -- Busca o codigo do parceiro ligado a este motor

      IF :NEW.AD_SERIEMOTOR IS NOT NULL AND P_COUNT <= 0
      THEN
         SELECT                                              /*MOT.CODPARC, */
               MOT.MARCASCOD, MOT.MODELOCOD
           INTO                                              /*:NEW.CODPARC,*/
               :NEW.AD_MARCASCOD, :NEW.AD_MODELOCOD
           FROM AD_CADMOTGER MOT
          WHERE MOT.SERIEMOTOR = :NEW.AD_SERIEMOTOR;
      END IF;
      


      -- Atualiza o campo de Projeto para as OSs da oficina
      IF P_COUNT <= 0 THEN
      SELECT PRJ.CODPROJ
        INTO V_CODPROJ
        FROM TCSPRJ PRJ, AD_CADMOTGER MOT
       WHERE     PRJ.ABREVIATURA = MOT.CLASSETIPO
             AND MOT.SERIEMOTOR = :NEW.AD_SERIEMOTOR;
      END IF;
      
          --  RAISE_APPLICATION_ERROR(-20101,'TOP: '||:NEW.CODTIPOPER||' Classe: '||:NEW.AD_SERIEMOTOR);


      IF NVL (:NEW.CODPROJ, 0) = 0 AND P_COUNT <= 0
      THEN
      
         :NEW.CODPROJ := V_CODPROJ;
         
      END IF;
      
      IF EXISTE.TIPO_OPERACAO(:NEW.CODTIPOPER,876,'TOP_ENTREGA_TECNICA') = 'S' THEN
      
        :NEW.SERIENOTA := 'OS';
      
      END IF;



      SELECT VEN.TIPVEND
        INTO P_TIPVEND
        FROM TGFVEN VEN
       WHERE VEN.CODVEND = :NEW.CODVEND;
       
      SELECT DISTINCT TOP.TIPMOV INTO P_TIPMOV FROM TGFTOP TOP
      WHERE
      TOP.CODTIPOPER = :NEW.CODTIPOPER;

            --   RAISE_APPLICATION_ERROR (
            --      -20101,P_TIPVEND);

      IF P_TIPVEND NOT IN ('V','S') AND P_TIPMOV NOT IN ('T')
      THEN
         RAISE_APPLICATION_ERROR (
            -20101,
               '<p align="center"><a href="http://www.sankhya.com.br" target="_blank"><img src="http://www.sankhya.com.br/imagens/logo-sankhya.png" width="250" height="60"></img></a></p><br><br><br><br><br><br>'
            || '<p align="left"><font size="12" face="arial" color="#8B1A1A"><b>Atencão: </b>Vendedor invalido.<br><br>'
            || '<b>Motivo: </b>O Vendedor informado não e do Tipo = "Vendedor" ! '
            || '.<br><br>'
            || '<b>Solucão: </b>Selecione um vendedor do Tipo = Vendedor. [Nr. Único: '||:NEW.NUNOTA||']  <br><br>'
            || '<a href="mailto:'
            || P_EMAIL
            || '?subject=Erro na trigger TRG_INC_UPD_TGFCAB_DCCO_SER=Email enviada por erro em processo no sistema SankhyaW">'
            || '<p align="center"><font color="#0000CD"><b><i>Clique aqui</i></b></font> para enviar e-mail para o TI</p></a></font></p><br><br>'
            || '<p align="center"><font size="10" color="#008B45"><b>Informacães para o implantador e/ou equipe Sankhya</b></font>');
      END IF;
   -- Ao faturar para TOPs de ORCAMENTO, setar o "Acompanhamento da OS" para AGUARDANDO APROVACAO
   --      IF :NEW.CODTIPOPER IN (1780, 1781, 1782, 1783, 1784, 1785)
   --      THEN
   --         IF :NEW.AD_STATUSORCA = 'APROVADO'
   --         THEN
   --            :NEW.AD_ACOMPOS := 'EXECREPARO';
   --         ELSE
   --            :NEW.AD_ACOMPOS := 'AGUARDAPRO';
   --         END IF;
   --
   --      END IF;



   END IF;

   SELECT COUNT(*) INTO P_COUNT
   FROM AD_RELPARMAGRUTOP
   WHERE NURELPARM = 876 
   AND      CODTIPOPER = :NEW.CODTIPOPER
   AND      DESCRICAO IN ('TOP_OS','TOP_OS_EXTERNA','TOP_ORCAMENTO');

   --Wanderlan
   --17/06/2013
   --não deixar faturar um Orcamento ou OS se não houver a aprovacão do cliente
   IF     INSERTING
      AND P_COUNT > 0 /*:NEW.CODTIPOPER IN (1765, 1766, 1767, 1768, 1799, 1796, 1792, 1793, 1794, 1795,/* NOROESTE */
                              --1875, 1876, 1877, 1879, 1999, 1996, 1992, 1993, 1994, 1995
      /*1780, 1781, 1782, 1783, 1784, 1785,
                                                                 )*/
      AND :NEW.AD_STATUSORCA <> 'APROVADO' AND UPDATING('STATUSNOTA')                              --AND
   --:OLD.AD_STATUSORCA <> 'APROVADO'
   THEN
      P_EMAIL := 'gustavo.pacheco@dcco.com.br';
      SHOW_RAISE('TGFCAB',49);
      /*RAISE_APPLICATION_ERROR (
         -20101,
            '<p align="center"><a href="http://www.sankhya.com.br" target="_blank"><img src="http://www.sankhya.com.br/imagens/logo-sankhya.png" width="250" height="60"></img></a></p><br><br><br><br><br><br>'
         || '<p align="left"><font size="12" face="arial" color="#8B1A1A"><b>Atencão: </b>Orcamento não foi aprovado pelo cliente!<br><br>'
         || '<b>Motivo: </b>O campo no cabecalho "Status do Orcamento" não esta marcado como Aprovado <br><br>'
         || '<b>Solucão: </b>Verifique se existe a aprovacão do cliente e marque como Aprovado.<br><br>'
         || '<a href="mailto:'
         || P_EMAIL
         || '?subject=Erro na trigger TRG_INC_UPD_TGFCAB_DCCO_SER=Email enviada por erro em processo no sistema SankhyaW">'
         || '<p align="center"><font color="#0000CD"><b><i>Clique aqui</i></b></font> para enviar e-mail para o TI</p></a></font></p><br><br>'
         || '<p align="center"><font size="10" color="#008B45"><b>Informacães para o implantador e/ou equipe Sankhya</b></font>');*/
   END IF;


--@@@@@@@ DEVE SER REVISADO O TRECHO ABAIXO=========================================================================================
   --Wanderlan
   --17/12/2013
   --não deixar faturar um Orcamento SE NÃO INFORMAR A DATA DE PREVISAO DE ENTREGA
--   IF     UPDATING('STATUSNOTA') AND :NEW.STATUSNOTA = 'L' AND :OLD.STATUSNOTA <> 'L' 
--      AND :NEW.CODTIPOPER IN (1799, 1796, 1792, 1793, 1794, 1795 /*1780, 1781, 1782, 1783, 1784, 1785,*/
--                                                                )
--      AND :NEW.DTPREVENT IS NULL
--   THEN
--      P_EMAIL := 'gustavo.pacheco@dcco.com.br';
--
--      RAISE_APPLICATION_ERROR (
--         -20101,
--            '<p align="center"><a href="http://www.sankhya.com.br" target="_blank"><img src="http://www.sankhya.com.br/imagens/logo-sankhya.png" width="250" height="60"></img></a></p><br><br><br><br><br><br>'
--         || '<p align="left"><font size="12" face="arial" color="#8B1A1A"><b>Atencão: </b>Operação não permitida!<br><br>'
--         || '<b>Motivo: </b>"Previsão de Entrega" precisa ser informado antes de faturar em OS Efetiva <br><br>'
--         || '<b>Solucão: </b>Preencha o campo "Previsão de Entrega Antes de Prosseguir! ==> "'||:NEW.DTPREVENT||'.<br><br>'
--         || '<a href="mailto:'
--         || P_EMAIL
--         || '?subject=Erro na trigger TRG_INC_UPD_TGFCAB_DCCO_SER=Email enviada por erro em processo no sistema SankhyaW">'
--         || '<p align="center"><font color="#0000CD"><b><i>Clique aqui</i></b></font> para enviar e-mail para o TI</p></a></font></p><br><br>'
--         || '<p align="center"><font size="10" color="#008B45"><b>Informacães para o implantador e/ou equipe Sankhya</b></font>');
--   END IF;
--

  
  SELECT COUNT(*) INTO P_COUNT
   FROM AD_RELPARMAGRUTOP
   WHERE NURELPARM = 876 
   AND      CODTIPOPER = :NEW.CODTIPOPER
   AND      DESCRICAO IN ('TOP_DIAGNOSTICO');
  
   --PEGA O NR DA OS DE DIAGNOSTICO E REPLICA NO CAMPO "Nr. da OS de Diagnostico"
   IF     (INSERTING OR UPDATING)
      AND P_COUNT > 0 /*:NEW.CODTIPOPER IN (1080, 1081, 1082, 1083, 1084, 1085, 1760, 1797, 
                              1770, 1180, 1181, 1182, 1183, 1184, 1185 -- NOROESTE
                              --,1760
                              )*/
   THEN
       -- AO TENTAR ALTERAR A EMPRESA
       IF UPDATING('CODEMP') AND :NEW.STATUSNOTA = 'L' THEN
          SHOW_RAISE('TGFCAB',3);
       END IF;
       
      :NEW.AD_NUMOSDIAG := :NEW.NUMNOTA;
   END IF;
   
   SELECT COUNT(*) INTO P_COUNT
   FROM AD_RELPARMAGRUTOP
   WHERE NURELPARM = 876 
   AND      CODTIPOPER = :NEW.CODTIPOPER
   AND      DESCRICAO IN ('TOP_ORCAMENTO_MANUTENCAO','TOP_ORCAMENTO');
  
   --PEGA O NR DA NOTA DE DIAGNOSTICO E REPLICA NO CAMPO "Nr. da OS de Diagnostico"
   IF     (INSERTING OR UPDATING)
      AND P_COUNT > 0 /*:NEW.CODTIPOPER IN (1080, 1081, 1082, 1083, 1084, 1085, 1760, 1797, 
                              1770, 1180, 1181, 1182, 1183, 1184, 1185 -- NOROESTE
                              --,1760
                              )*/
   THEN
      :NEW.AD_NUMOSDIAG := :NEW.NUMNOTA;
   END IF;
   
   SELECT COUNT(*) INTO P_COUNT
   FROM AD_RELPARMAGRUTOP
   WHERE NURELPARM = 876 
   AND      CODTIPOPER = :NEW.CODTIPOPER
   AND      DESCRICAO IN ('TOP_OS','TOP_OS_EXTERNA','TOP_ORCAMENTO');
   
   --FAVOR NÃO INFORMAR AS TOPS 1790 E 1791 NESTE IF ABAIXO SÃO TOPS ESPECIFICAS DO PROCESSO EDI-CUMMINS
   IF     (INSERTING OR UPDATING)
      AND P_COUNT > 0
      /*:NEW.CODTIPOPER IN (1799, 1792, 1793, 1794, 1795, 1796, 1765, 1766, 1767, 1768,
                              1780, 1781, 1782, 
                              1999, 1992, 1993, 1994, 1995, 1996, 1980, 1981, 1982, -- NOROESTE
                              1875, 1876, 1877, 1879 -- NOROESTE
                              --,1766*/
                              
   THEN
      IF :NEW.AD_NUMOSDIAG IS NULL THEN
         SHOW_RAISE('TGFCAB',77);
         --RAISE_APPLICATION_ERROR (-20101,'<br><br><p align="center"><font face="Verdana" size="12">É necessário ter um orçamento antes do lançamento!<br>Faça o lançamento em TOP''s de orçamento!</font></p><br><br>'||'TOP - '||:NEW.CODTIPOPER||' - '||:NEW.NUMNOTA||' - '||:NEW.AD_NUMOSDIAG);
      END IF;
      
      :NEW.NUMNOTA := NVL(:NEW.AD_NUMOSDIAG,0);
   END IF;
   
   -- CRIADO POR: MARCUS VINICIUS
   -- DIA: 08/03/2016
   -- VALIDAR SE PERTENCE A TOP DE EXIGIR FECHAR OS
   SELECT COUNT(*) INTO P_COUNT
   FROM AD_RELPARMAGRUTOP
   WHERE NURELPARM = 655 
   AND      CODTIPOPER = :NEW.CODTIPOPER;

   IF INSERTING AND (P_COUNT > 0 AND :NEW.AD_STATUS_OS <> 'FECHADA') THEN
   
         RAISE_APPLICATION_ERROR (
            -20101,
            '<p align="center"><a href="http://www.sankhya.com.br" target="_blank"><img src="http://www.sankhya.com.br/imagens/logo-sankhya.png" width="250" height="60"></img></a></p><br><br><br><br><br><br>'
            || '<p align="left"><font size="12" face="arial" color="#8B1A1A"><b>Atencão: </b>Faturamento não permitido!!<br><br>'
            || '<b>Motivo: </b>Ordem de Serviço não foi fechada! <br><br>'
            || '<b>Solucão: </b>Efetue o fechamento da OS antes de prosseguir.<br><br>'
            || '<a href="mailto:'
            || P_EMAIL
            || '?subject=Erro na trigger TRG_INC_UPD_TGFCAB_DCCO_SER=Email enviada por erro em processo no sistema SankhyaW">'
            || '<p align="center"><font color="#0000CD"><b><i>Clique aqui</i></b></font> para enviar e-mail para o TI</p></a></font></p><br><br>'
            || '<p align="center"><font size="10" color="#008B45"><b>Informacães para o implantador e/ou equipe Sankhya</b></font>');

   
   END IF;


   --   IF :OLD.AD_STATUSORCA = 'APROVADO' AND :NEW.AD_STATUSORCA = 'AGUARDANDO'
   --   THEN
   --      P_EMAIL := 'gustavo.pacheco@dcco.com.br';
   --
   --      RAISE_APPLICATION_ERROR (
   --         -20101,
   --         '<p align="center"><a href="http://www.sankhya.com.br" target="_blank"><img src="http://www.sankhya.com.br/imagens/logo-sankhya.png" width="250" height="60"></img></a></p><br><br><br><br><br><br>'
   --         || '<p align="left"><font size="12" face="arial" color="#8B1A1A"><b>Atencão: </b>Orcamento ja aprovado!!<br><br>'
   --         || '<b>Motivo: </b>Orcamento ja Aprovado não pode ser alterado! <br><br>'
   --         || '<b>Solucão: </b>Alterar itens na OS.<br><br>'
   --         || '<a href="mailto:'
   --         || P_EMAIL
   --         || '?subject=Erro na trigger TRG_INC_UPD_TGFCAB_DCCO_SER=Email enviada por erro em processo no sistema SankhyaW">'
   --         || '<p align="center"><font color="#0000CD"><b><i>Clique aqui</i></b></font> para enviar e-mail para o TI</p></a></font></p><br><br>'
   --         || '<p align="center"><font size="10" color="#008B45"><b>Informacães para o implantador e/ou equipe Sankhya</b></font>');
   --   END IF;
   
   SELECT COUNT(*) INTO P_COUNT
   FROM AD_RELPARMAGRUTOP
   WHERE NURELPARM = 876 
   AND      DESCRICAO = 'TOP_VALID_MECANICO'
   AND      CODTIPOPER = :NEW.CODTIPOPER;
   
   -- TRATATIVAS PARA CONFIRMAcãO DE OS
   IF     P_COUNT > 0
      AND :NEW.STATUSNOTA = 'L'
      AND :OLD.STATUSNOTA <> 'L'
   THEN
      -- Verifica se possui mecanico
      SELECT COUNT (*)
        INTO P_QTDMECANICO
        FROM TGFCCM CCM
       WHERE CCM.NUNOTA = :NEW.NUNOTA;

      -- Verifica se Possui servico
      SELECT COUNT (*)
        INTO P_TEMSERVICO
        FROM TGFITE ITE, TGFPRO PRO
       WHERE     ITE.NUNOTA = :NEW.NUNOTA
             AND ITE.CODPROD = PRO.CODPROD
             AND PRO.USOPROD = 'S';

      IF P_QTDMECANICO = 0 AND P_TEMSERVICO > 0
      THEN
         RAISE_APPLICATION_ERROR (
            -20101,
               '<p align="center"><a href="http://www.sankhya.com.br" target="_blank"><img src="http://www.sankhya.com.br/imagens/logo-sankhya.png" width="250" height="60"></img></a></p><br><br><br><br><br><br>'
            || '<p align="left"><font size="12" face="arial" color="#8B1A1A"><b>Atencão: </b>Confirmacão de OS não permitida!<br><br>'
            || '<b>Motivo: </b>não foram informados os Tecnicos na Guia "Mecanicos" desta OS. <br><br>'
            || '<b>Solucão: </b>Informe os os Mecanicos alocados nesta OS antes de confirmar!.<br><br>'
            || '<a href="mailto:'
            || P_EMAIL
            || '?subject=Erro na trigger TRG_INC_UPD_TGFCAB_DCCO_SER=Email enviada por erro em processo no sistema SankhyaW">'
            || '<p align="center"><font color="#0000CD"><b><i>Clique aqui</i></b></font> para enviar e-mail para o TI</p></a></font></p><br><br>'
            || '<p align="center"><font size="10" color="#008B45"><b>Informacães para o implantador e/ou equipe Sankhya</b></font>');
      END IF;
   END IF;

   /*
   Autor: Wanderlan
   Data: 08/07/2013
   Objetivo: não permitir que vendedores que não sejam do tipo = vendedor sejam utilizados no cabecalho
   */
   
   SELECT COUNT(*) INTO V_COUNT
   FROM AD_RELPARMAGRUTOP
   WHERE CODTIPOPER = :NEW.CODTIPOPER
   AND      NURELPARM = 40 AND DESCRICAO = 'TRG_INC_UPD_TGFCAB_DCCO_SER-L487';
   
   IF V_COUNT > 0--:NEW.CODTIPOPER IN (1799,1999)
   THEN
      -- Verificar se o vendedor informado na TGFCAB e do tipo = 'vendedor
      SELECT VEN.TIPVEND
        INTO P_TIPVEND
        FROM TGFVEN VEN
       WHERE VEN.CODVEND = :NEW.CODVEND;

      IF P_TIPVEND NOT IN ('V','S')
      THEN
         RAISE_APPLICATION_ERROR (
            -20101,
               '<p align="center"><a href="http://www.sankhya.com.br" target="_blank"><img src="http://www.sankhya.com.br/imagens/logo-sankhya.png" width="250" height="60"></img></a></p><br><br><br><br><br><br>'
            || '<p align="left"><font size="12" face="arial" color="#8B1A1A"><b>Atencão: </b>Vendedor invalido.<br><br>'
            || '<b>Motivo: </b>O Vendedor informado não e do Tipo = "Vendedor" ! '
            || '.<br><br>'
            || '<b>Solucão: </b>Selecione um vendedor do Tipo = Vendedor.<br><br>'
            || '<a href="mailto:'
            || P_EMAIL
            || '?subject=Erro na trigger TRG_INC_UPD_TGFCAB_DCCO_SER=Email enviada por erro em processo no sistema SankhyaW">'
            || '<p align="center"><font color="#0000CD"><b><i>Clique aqui</i></b></font> para enviar e-mail para o TI</p></a></font></p><br><br>'
            || '<p align="center"><font size="10" color="#008B45"><b>Informacães para o implantador e/ou equipe Sankhya</b></font>');
      END IF;
   END IF;

   --[PROCESSOS DE O.S. DCCO]
   --[CONSULTOR WANDERLAN]
   --[FINALIZANDO]

   ------------------------------------------------------------------------------------------------------------------

   --[PROCESSOS DE O.S. RENTAL]
   --[CONSULTOR GLEISTON]
   --[INICIANDO]

   --16/07/2013

   P_EMAIL := 'ti@dcco.com.br';

   SELECT COUNT(*) INTO P_COUNT
   FROM AD_RELPARMAGRUTOP
   WHERE NURELPARM = 876 
   AND      DESCRICAO = 'TOP_STATUS_ORCAMENTO'
   AND      CODTIPOPER = :NEW.CODTIPOPER;
   
   IF P_COUNT > 0
   THEN
      -- Seta o Status do orcamento para aguardando a validacão do cliente
      IF :NEW.AD_STATUSORCA IS NULL
      THEN
         :NEW.AD_STATUSORCA := 'AGUARDANDO';
      END IF;

      -- Busca a quantidade de dias para vencimento do orcamento, conforme parametro abaixo.
      SELECT INTEIRO
        INTO P_PRAZOVENC
        FROM TSIPAR PAR
       WHERE CHAVE LIKE 'PRAZOVENCORCAME';

      :NEW.DTVAL := SYSDATE + P_PRAZOVENC;

      -- Verificar se o vendedor informado na TGFCAB e do tipo = 'vendedor

      SELECT VEN.TIPVEND
        INTO P_TIPVEND
        FROM TGFVEN VEN
       WHERE VEN.CODVEND = :NEW.CODVEND;

      IF P_TIPVEND NOT IN ('V','S','G')
      THEN
         SHOW_RAISE('TGFCAB',76,VETOR('CODVEND'),VETOR(:NEW.CODVEND));
         /*RAISE_APPLICATION_ERROR (
            -20101,
               '<p align="center"><a href="http://www.sankhya.com.br" target="_blank"><img src="http://www.sankhya.com.br/imagens/logo-sankhya.png" width="250" height="60"></img></a></p><br><br><br><br><br><br>'
            || '<p align="left"><font size="12" face="arial" color="#8B1A1A"><b>Atencão: </b>Vendedor invalido.<br><br>'
            || '<b>Motivo: </b>O Vendedor informado não e do Tipo = "Vendedor" ! '
            || '.<br><br>'
            || '<b>Solucão: </b>Selecione um vendedor do Tipo = Vendedor.<br><br>'
            || '<a href="mailto:'
            || P_EMAIL
            || '?subject=Erro na trigger TRG_INC_UPD_TGFCAB_DCCO_SER=Email enviada por erro em processo no sistema SankhyaW">'
            || '<p align="center"><font color="#0000CD"><b><i>Clique aqui</i></b></font> para enviar e-mail para o TI</p></a></font></p><br><br>'
            || '<p align="center"><font size="10" color="#008B45"><b>Informacães para o implantador e/ou equipe Sankhya</b></font>');*/
      END IF;
   END IF;
   
   SELECT COUNT(*) INTO P_COUNT
   FROM AD_RELPARMAGRUTOP
   WHERE NURELPARM = 876 
   AND      DESCRICAO = 'TOP_STATUS_ORC_APROVADO'
   AND      CODTIPOPER = :NEW.CODTIPOPER;
   
   --caso esteja faturando o orcamento e o status não esteja aprovado, sera emitida mensagem de erro.
   IF P_COUNT > 0 
      AND :NEW.AD_STATUSORCA <> 'APROVADO'
      AND :OLD.AD_STATUSORCA <> 'APROVADO'
   THEN
      RAISE_APPLICATION_ERROR (
         -20101,
            '<p align="center"><a href="http://www.sankhya.com.br" target="_blank"><img src="http://www.sankhya.com.br/imagens/logo-sankhya.png" width="250" height="60"></img></a></p><br><br><br><br><br><br>'
         || '<p align="left"><font size="12" face="arial" color="#8B1A1A"><b>Atencão: </b>Orcamento ja aprovado!!<br><br>'
         || '<b>Motivo: </b>Orcamento ja Aprovado não pode ser alterado! <br><br>'
         || '<b>Solucão: </b>Alterar itens na OS.<br><br>'
         || '<a href="mailto:'
         || P_EMAIL
         || '?subject=Erro na trigger TRG_INC_UPD_TGFCAB_DCCO_SER=Email enviada por erro em processo no sistema SankhyaW">'
         || '<p align="center"><font color="#0000CD"><b><i>Clique aqui</i></b></font> para enviar e-mail para o TI</p></a></font></p><br><br>'
         || '<p align="center"><font size="10" color="#008B45"><b>Informacães para o implantador e/ou equipe Sankhya</b></font>');
   END IF;
   
   SELECT COUNT(*) INTO P_COUNT
   FROM AD_RELPARMAGRUTOP
   WHERE NURELPARM = 876 
   AND      DESCRICAO = 'TOP_STATUS_ORC_APROVADO'
   AND      CODTIPOPER = :NEW.CODTIPOPER;
   
   --não permitir alterar o status do orcamento de aprovado para aguardando
   IF :OLD.AD_STATUSORCA = 'APROVADO' AND :NEW.AD_STATUSORCA = 'AGUARDANDO'  and stp_get_codusulogado <> 786 /*AND :NEW.CODTIPOPER <> 1765*/
   THEN
      RAISE_APPLICATION_ERROR (
         -20101,
            '<p align="center"><a href="http://www.sankhya.com.br" target="_blank"><img src="http://www.sankhya.com.br/imagens/logo-sankhya.png" width="250" height="60"></img></a></p><br><br><br><br><br><br>'
         || '<p align="left"><font size="12" face="arial" color="#8B1A1A"><b>Atencão: </b>Orcamento ja aprovado!!<br><br>'
         || '<b>Motivo: </b>Usuario não possui permiss?o para alterar um Orcamento ja aprovado pelo cliente! <br><br>'
         || '<b>Solucão: </b>Verificar controle de acesso.<br><br>'
         || '<a href="mailto:'
         || P_EMAIL
         || '?subject=Erro na trigger TRG_INC_UPD_TGFCAB_DCCO_SER=Email enviada por erro em processo no sistema SankhyaW">'
         || '<p align="center"><font color="#0000CD"><b><i>Clique aqui</i></b></font> para enviar e-mail para o TI</p></a></font></p><br><br>'
         || '<p align="center"><font size="10" color="#008B45"><b>Informacães para o implantador e/ou equipe Sankhya</b></font>');
   END IF;
   
   SELECT COUNT(*) INTO P_COUNT
   FROM AD_RELPARMAGRUTOP
   WHERE NURELPARM = 876 
   AND      DESCRICAO = 'TOP_STATUS_ORC_APROVADO'
   AND      CODTIPOPER = :NEW.CODTIPOPER;
   
   -- TRATATIVAS PARA CONFIRMAcãO DE OS
   IF     P_COUNT > 0 
      AND :NEW.STATUSNOTA = 'L'
      AND :OLD.STATUSNOTA <> 'L'
   THEN
      -- Verifica se possui mecanico
      SELECT COUNT (*)
        INTO P_QTDMECANICO
        FROM TGFCCM CCM
       WHERE CCM.NUNOTA = :NEW.NUNOTA;

      -- Verifica se Possui servico
      SELECT COUNT (*)
        INTO P_TEMSERVICO
        FROM TGFITE ITE, TGFPRO PRO
       WHERE     ITE.NUNOTA = :NEW.NUNOTA
             AND ITE.CODPROD = PRO.CODPROD
             AND PRO.USOPROD = 'S';

      IF P_QTDMECANICO = 0 AND P_TEMSERVICO > 0
      THEN
         RAISE_APPLICATION_ERROR (
            -20101,
               '<p align="center"><a href="http://www.sankhya.com.br" target="_blank"><img src="http://www.sankhya.com.br/imagens/logo-sankhya.png" width="250" height="60"></img></a></p><br><br><br><br><br><br>'
            || '<p align="left"><font size="12" face="arial" color="#8B1A1A"><b>Atencão: </b>Confirmacão de OS não permitida!<br><br>'
            || '<b>Motivo: </b>não foram informados os Tecnicos na Guia "Mecanicos" desta OS. <br><br>'
            || '<b>Solucão: </b>Informe os os Mecanicos alocados nesta OS antes de confirmar!.<br><br>'
            || '<a href="mailto:'
            || P_EMAIL
            || '?subject=Erro na trigger TRG_INC_UPD_TGFCAB_DCCO_SER=Email enviada por erro em processo no sistema SankhyaW">'
            || '<p align="center"><font color="#0000CD"><b><i>Clique aqui</i></b></font> para enviar e-mail para o TI</p></a></font></p><br><br>'
            || '<p align="center"><font size="10" color="#008B45"><b>Informacães para o implantador e/ou equipe Sankhya</b></font>');
      END IF;
   END IF;
   
   /*
   Objetivo: não permitir que vendedores que não sejam do tipo = vendedor sejam utilizados no cabecalho
   */   
   SELECT COUNT(*) INTO P_COUNT
   FROM AD_RELPARMAGRUTOP
   WHERE NURELPARM = 876 
   AND      DESCRICAO = 'TOP_STATUS_ORC_APROVADO'
   AND      CODTIPOPER = :NEW.CODTIPOPER;

   IF P_COUNT > 0
   THEN
      -- Verificar se o vendedor informado na TGFCAB e do tipo = 'vendedor
      SELECT VEN.TIPVEND
        INTO P_TIPVEND
        FROM TGFVEN VEN
       WHERE VEN.CODVEND = :NEW.CODVEND;

      IF P_TIPVEND <> 'V'
      THEN
         RAISE_APPLICATION_ERROR (
            -20101,
               '<p align="center"><a href="http://www.sankhya.com.br" target="_blank"><img src="http://www.sankhya.com.br/imagens/logo-sankhya.png" width="250" height="60"></img></a></p><br><br><br><br><br><br>'
            || '<p align="left"><font size="12" face="arial" color="#8B1A1A"><b>Atencão: </b>Vendedor invalido.<br><br>'
            || '<b>Motivo: </b>O Vendedor informado não e do Tipo = "Vendedor" ! '
            || '.<br><br>'
            || '<b>Solucão: </b>Selecione um vendedor do Tipo = Vendedor.<br><br>'
            || '<a href="mailto:'
            || P_EMAIL
            || '?subject=Erro na trigger TRG_INC_UPD_TGFCAB_DCCO_SER=Email enviada por erro em processo no sistema SankhyaW">'
            || '<p align="center"><font color="#0000CD"><b><i>Clique aqui</i></b></font> para enviar e-mail para o TI</p></a></font></p><br><br>'
            || '<p align="center"><font size="10" color="#008B45"><b>Informacães para o implantador e/ou equipe Sankhya</b></font>');
      END IF;
   END IF;

   --[PROCESSOS DE O.S. RENTAL]
   --[CONSULTOR GLEISTON]
   --[FINALIZANDO]


   -- Acompanhamento das OSs
   
   SELECT COUNT(*) INTO P_COUNT
   FROM AD_RELPARMAGRUTOP
   WHERE NURELPARM = 876 
   AND      DESCRICAO = 'TOP_ORCAMENTO'
   AND      CODTIPOPER = :NEW.CODTIPOPER;
   
   IF EXISTE.TIPO_OPERACAO(:NEW.CODTIPOPER,876,'TOP_ORCAMENTO') = 'S' /*:NEW.CODTIPOPER IN (1780, 1781, 1782, 1783, 1784, 1785,
        --                  1980, 1981, 1982, 1983, 1984, 1985 -- NOROESTE
                          )*/
   THEN
      :NEW.AD_ACOMPOS := 'AGUARDAPRO';
   END IF;

   IF EXISTE.TIPO_OPERACAO(:NEW.CODTIPOPER,40,'TRG_INC_UPD_TGFCAB_DCCO_SER-L689') = 'S'
   /*:NEW.CODTIPOPER IN (1799, 1792, 1793, 1794, 1795, 1796,
                          1999, 1992, 1993, 1994, 1995, 1996 -- NOROESTE
                          )*/
   THEN
      :NEW.AD_ACOMPOS := 'EXECREPARO';
   END IF;
   
   SELECT COUNT(*) INTO P_COUNT
   FROM AD_RELPARMAGRUTOP
   WHERE NURELPARM = 876 
   AND      DESCRICAO = 'TOP_FATDCOS'
   AND      CODTIPOPER = :NEW.CODTIPOPER;
   
   IF NVL(:NEW.AD_FATDCOS,'N') = 'S' AND P_COUNT > 0 THEN
     
     -- ALTERAR A EMPRESA FISCAL
     SELECT COUNT(*) INTO P_COUNT
     FROM AD_RELPARMAGRUEMP
     WHERE NURELPARM = 876 
     AND      DESCRICAO = 'TOP_FATDCOS'
     AND      CODEMP = :NEW.CODEMP;
    
    IF P_COUNT > 0 THEN
         BEGIN
         
           SELECT CAST(DESCREMP AS NUMBER) INTO P_COUNT
           FROM AD_RELPARMAGRUEMP
           WHERE NURELPARM = 876 
           AND      DESCRICAO = 'TOP_FATDCOS'
           AND      CODEMP = :NEW.CODEMP;
           
        EXCEPTION
        WHEN OTHERS THEN
             SHOW_RAISE('TGFCAB',24);
        END;
        
        --RAISE_APPLICATION_ERROR(-20101,'FATURAMENTO POR OUTRA EMPRESA');
        :NEW.CODEMP := P_COUNT;
   
    END IF;
   
   END IF;
 

/*
Autor: Wanderlan
Data: 12/03/2014
Objetivo: Não permitir faturamento de Notas Fiscais cujo TIPMOV = V se a OS estiver em aberto
*/   

    IF :NEW.TIPMOV = 'V' AND NVL(:NEW.AD_STATUS_OS,'ABERTA') <> 'FECHADA'  THEN
      
    --RAISE_APPLICATION_ERROR(-20101,'TESTES, AGUARDAR  -  '||:NEW.TIPMOV||' NUNICO '||:NEW.NUNOTA);
    
        -- Verifica se existe nota faturada
/*        SELECT COUNT(*) INTO P_TEMNFFAT FROM TGFVAR VAR
        WHERE
        VAR.NUNOTAORIG = :NEW.NUNOTA; */
        
        -- Verifica se é uma TOP de OS
        /*SELECT DISTINCT TOP.GRUPO INTO P_GRUPOTOP FROM TGFTOP TOP
        WHERE
        TOP.CODTIPOPER = :NEW.CODTIPOPER;        
    
    
        IF P_GRUPOTOP = 'O.S.' THEN*/
        IF EXISTE.TIPO_OPERACAO(:NEW.CODTIPOPER,876,'VALIDA_FECHAMENTO_OS') = 'S' THEN
        
         RAISE_APPLICATION_ERROR (
            -20101,
            '<p align="center"><a href="http://www.sankhya.com.br" target="_blank"><img src="http://www.sankhya.com.br/imagens/logo-sankhya.png" width="250" height="60"></img></a></p><br><br><br><br><br><br>'
            || '<p align="left"><font size="12" face="arial" color="#8B1A1A"><b>Atencão: </b>Faturamento não permitido!!<br><br>'
            || '<b>Motivo: </b>Ordem de Serviço não foi fechada! <br><br>'
            || '<b>Solucão: </b>Efetue o fechamento da OS antes de prosseguir.<br><br><b><i>Obs.: Se o lançamento de origem for uma OS, não poderá em hipótese alguma permitir este faturamento sem antes Fechar a OS! Pois poderá gerar problemas com a comissão dos Técnicos</b></i><br><br>'
            || '<a href="mailto:'
            || P_EMAIL
            || '?subject=Erro na trigger TRG_INC_UPD_TGFCAB_DCCO_SER=Email enviada por erro em processo no sistema SankhyaW">'
            || '<p align="center"><font color="#0000CD"><b><i>Clique aqui</i></b></font> para enviar e-mail para o TI</p></a></font></p><br><br>'
            || '<p align="center"><font size="10" color="#008B45"><b>Informacães para o implantador e/ou equipe Sankhya</b></font>');
        
        END IF;
    
    END IF;



/*
Autor: Wanderlan
Data: 12/03/2014
Objetivo: Não permitir REABRIR uma OS caso exista algum faturamento já registrado
*/   

    IF UPDATING('AD_STATUS_OS') AND NVL(:NEW.AD_STATUS_OS, 'ABERTA') = 'ABERTA' AND NVL(:OLD.AD_STATUS_OS,'ABERTA') <> 'ABERTA' THEN
    
        -- Verifica se existe nota faturada
        /*SELECT COUNT(*) INTO P_TEMNFFAT FROM TGFVAR VAR
        WHERE
        VAR.NUNOTAORIG = :NEW.NUNOTA; */
        
        SELECT COUNT(DISTINCT I.SEQUENCIA) INTO P_TEMNFFAT FROM TGFITE I, TGFVAR V 
        WHERE I.NUNOTA = :NEW.NUNOTA AND 
              V.NUNOTAORIG = I.NUNOTA AND 
              I.SEQUENCIA = V.SEQUENCIAORIG AND 
              V.NUNOTA != V.NUNOTAORIG AND
              I.USOPROD != 'S' AND
              I.PENDENTE = 'N'; -- ALTERADO POR: MARCUS VINICIUS -- 08/10/2014 -- PERMITE ALTERAR STATUS SE HOUVER ITENS COM PENDÊNCIAS
        
        SELECT COUNT(*) INTO V_COUNT FROM TGFITE I
        WHERE I.NUNOTA = :NEW.NUNOTA AND 
              I.USOPROD != 'S';
        
        -- A OS TEM CONTROLE DE VALIDADE
        -- COMENTADO POR: MARCUS VINICIUS OLIVEIRA SILVA
        -- EM: 21/01/2019 AS 12:32
        -- Verifica se é uma TOP de OS
        /*SELECT DISTINCT TOP.GRUPO INTO P_GRUPOTOP FROM TGFTOP TOP
        WHERE
        TOP.CODTIPOPER = :NEW.CODTIPOPER;
        
       IF P_TEMNFFAT >= V_COUNT AND EXISTE.TIPO_OPERACAO(:NEW.CODTIPOPER,876,'VALIDA_FECHAMENTO_OS') = 'S' AND V_COUNT > 0 THEN

         SHOW_RAISE('TGFCAB',8,VETOR('NUNOTA'),VETOR(:NEW.NUNOTA));
\*         RAISE_APPLICATION_ERROR (
            -20101,
            '<p align="center"><a href="http://www.sankhya.com.br" target="_blank"><img src="http://www.sankhya.com.br/imagens/logo-sankhya.png" width="250" height="60"></img></a></p><br><br><br><br><br><br>'
            || '<p align="left"><font size="12" face="arial" color="#8B1A1A"><b>Atencão: </b>Operação não permitida!!<br><br>'
            || '<b>Motivo: </b>Não é permitido abrir novamente uma OS quando a mesma já possui algum faturamento! <br><br>'
            || '<b>Solucão: </b>Caso seja necessário, deverá ser lançado uma nova OS ou então efetuar o cancelamento da NFSe (Caso ainda seja possível)<br><br>'
            || '<a href="mailto:'
            || P_EMAIL
            || '?subject=Erro na trigger TRG_INC_UPD_TGFCAB_DCCO_SER=Email enviada por erro em processo no sistema SankhyaW">'
            || '<p align="center"><font color="#0000CD"><b><i>Clique aqui</i></b></font> para enviar e-mail para o TI</p></a></font></p><br><br>'
            || '<p align="center"><font size="10" color="#008B45"><b>Informacães para o implantador e/ou equipe Sankhya</b></font>');*\
    
        
        
        END IF;*/
    
    
    END IF;
  
  ELSE
      IF :NEW.TIPMOV != 'V' THEN
            :NEW.AD_NUMOSDIAG := :NEW.NUMNOTA;
      END IF;
  END IF;
  
  
  
-- CRIADO POR: DANIEL BATISTA MACHADO
-- DATA: 01/12/2021 AS 09:00
-- MOTIVO: CRIADO PARA ALIMENTAR MARCA E MODELO DO MOTOR NAS OS PARA CALCULAR TEMPO PADRÃO

    IF :NEW.AD_SERIEMOTOR IS NOT NULL THEN

        SELECT MARCASCOD, MODELOCOD, CODAPLI
          INTO P1_MARCASCOD, P1_MODELOCOD, P1_CODAPLI
          FROM AD_CADMOTGER
         WHERE SERIEMOTOR = :NEW.AD_SERIEMOTOR;

        :NEW.AD_MARCASCOD := P1_MARCASCOD;
        :NEW.AD_MODELOCOD := P1_MODELOCOD;
        :NEW.AD_CODAPLI := P1_CODAPLI;
    END IF;

   
END;
/