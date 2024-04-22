CREATE OR REPLACE PROCEDURE SANKHYA.SHOW_RAISE(P_TABELA VARCHAR2,P_CODERRO NUMBER, P_KEY VETOR DEFAULT VETOR(), P_VLR VETOR DEFAULT VETOR())
--RETURN VARCHAR2
IS
      P_MSG     VARCHAR2(32000);
      P_TBL     VARCHAR2(32000);      
      P_CER     NUMBER;
      P_K       VETOR;
      P_V       VETOR;
      
      P_EMAILLOG      VARCHAR2(600);
      P_ASSUNTOLOG    VARCHAR2(1200);
      P_PROGRAM       VARCHAR2(4000);
      P_COUNT         NUMBER;
      P_TIPOALERTA    VARCHAR2(100);
      
      P_NOMEUSU       VARCHAR2(3000);
      
      PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

     -- TODOS OS ERROS DEVEM ESTAR LANÇADOS NA TELA (PARÂMETROS DE RELATÓRIOS / REGRAS) COM O NRO ÚNICO: 813
     -- ABA AGRUPAMENTO -> ACHA TABLE RELACIONADA 
     -- ABA REGISTRO DE ERROS -> COLOCA A MENSAGEM

     P_TBL := P_TABELA;
     P_CER := P_CODERRO;
     P_K   := P_KEY;
     P_V   := P_VLR;
     
     
     IF P_TABELA = 'DUAL' AND
         ((P_KEY.COUNT <= 0 AND P_VLR.COUNT > 0) OR
          (P_KEY.COUNT > 0 AND P_VLR.COUNT <= 0) OR
          (P_KEY.COUNT <= 0 AND P_VLR.COUNT <= 0)) THEN
        
        IF P_KEY.COUNT <= 0 AND P_VLR.COUNT > 0  THEN
                RAISE_APPLICATION_ERROR(-20101, 'Mensagem Interna: '||CHR(13)||CHR(13)||CHR(10)||CHR(10)||P_VLR(P_CODERRO)||CHR(13)||CHR(13)||CHR(13));
        ELSIF P_KEY.COUNT > 0 AND P_VLR.COUNT <= 0 THEN
                RAISE_APPLICATION_ERROR(-20101, 'Mensagem Interna: '||CHR(13)||CHR(13)||CHR(10)||CHR(10)||P_KEY(P_CODERRO)||CHR(13)||CHR(13)||CHR(13));
        ELSIF P_KEY.COUNT <= 0 AND P_VLR.COUNT <= 0 THEN
                RAISE_APPLICATION_ERROR(-20101, 'Mensagem Interna: '||CHR(13)||CHR(13)||CHR(10)||CHR(10)||'Erro não especifícado!'||CHR(13)||CHR(13)||CHR(13));
        END IF;        
        
     ELSE
         
         BEGIN
              
              SELECT VARIAVEL_DCCO(813,P_TBL,MSGRRO, P_K, P_V) INTO P_MSG
              FROM AD_RELPARMAGRUDOCERRO O
              WHERE O.NURELPARM = 813
              AND O.DESCRICAO = P_TBL
              AND O.CODERRO = P_CER;
    
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
    
              P_TBL := 'AD_RELPARMAGRUDOCERRO';
              P_CER := 1;
              P_K   := VETOR();
              P_V   := VETOR();
              
              SELECT VARIAVEL_DCCO(813,P_TBL,MSGRRO, P_K, P_V) INTO P_MSG
              FROM AD_RELPARMAGRUDOCERRO O
              WHERE O.NURELPARM = 813
              AND O.DESCRICAO = P_TBL
              AND O.CODERRO = P_CER;
         
         WHEN OTHERS THEN
              
              P_MSG := 'Erro interno!';
         
         END;
         
         ROLLBACK;
         
         -- PEGAR O E-MAIL DE DESTINO QUE DEVERÁ SER ENVIADO
         SELECT NVL(E.EMAIL,'ti@dcco.com.br') INTO P_EMAILLOG
         FROM DUAL
         LEFT JOIN TSIUSU U ON U.CODUSU = STP_GET_CODUSULOGADO 
         LEFT JOIN AD_TSIEMPEMAIL E ON E.TIPOEMAIL = '7' AND E.CODEMP = U.CODEMP;
         
         -- MONTA O ASSUNTO DO E-MAIL
         SELECT 'Erro identificado em: '||NVL(MAX(DESCRTAB),'Tabela não identificada')||' - '||NVL(MAX(NOMETAB),'*') INTO P_ASSUNTOLOG
         FROM DUAL
         LEFT JOIN TDDTAB ON NOMETAB = P_TBL;
         
         -- IDENTIFICA DE ONDE VEM A REQUISIÇÃO DE ERRO
         SELECT PROGRAM INTO P_PROGRAM
         FROM v$session
         WHERE AUDSID = SYS_CONTEXT('USERENV','SESSIONID');
         
         -- VALIDAR SE O USUÁRIO LOGADO PERTENCE A ALGUM USUÁRIO QUE IRÁ IGNORAR O ERRO
         SELECT COUNT(*) INTO P_COUNT
         FROM AD_RELPARMAGRUDOCERROUSU
         WHERE NURELPARM = 813
         AND     CODUSU = STP_GET_CODUSULOGADO
         AND     DESCRICAO = P_TABELA
         AND     CODERRO = P_CODERRO
         AND     (DTLIMITE >= TRUNC(SYSDATE) OR DTLIMITE = '01/01/1900');
         
         -- SE PERTENCER AO USUÁRIO DE EXCEÇÃO
         IF P_COUNT > 0 THEN
            RETURN;
         ELSE
                        
             -- FAZER DISPARO DE E-MAIL SE ESTIVER MARCADO
             FOR F1 IN (SELECT Erro.TOEMAIL, Erro.ASSUNTO, VARIAVEL_DCCO(813,P_TBL,Erro.BODY, P_K, P_V) AS BODY
                              FROM AD_RELPARMAGRUDOCERRO Erro
                              WHERE Erro.NURELPARM = 813
                              AND     Erro.DESCRICAO = P_TABELA
                              AND     Erro.CODERRO = P_CODERRO
                              AND     NVL(Erro.ENVIAEMAIL,'N') = 'S'
                              AND     LENGTH(TRIM(Erro.TOEMAIL)) > 4
                              AND     LENGTH(TRIM(Erro.BODY)) > 1)
             LOOP
                      BEGIN
                        SELECT NOMEUSU INTO P_NOMEUSU
                        FROM TSIUSU
                        WHERE CODUSU = STP_GET_CODUSULOGADO;
                      EXCEPTION
                      WHEN OTHERS THEN
                        P_NOMEUSU := 'SUP';
                      END;
                      
                      EMAIL(F1.TOEMAIL,F1.ASSUNTO,NULL,F1.BODY||'<br>'||'Usuário: '||STP_GET_CODUSULOGADO||' - '||P_NOMEUSU);
                      COMMIT;

             END LOOP;
             
             BEGIN
               SELECT TIPOALERTA INTO P_TIPOALERTA
               FROM AD_RELPARMAGRUDOCERRO
               WHERE NURELPARM = 813
               AND     DESCRICAO = P_TABELA
               AND     CODERRO = P_CODERRO;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              P_TIPOALERTA := NULL;
            END;  
            
             -- DESCONSIDERAR TODOS OS ERROS
             IF VARIAVEIS_DCCO.V_STOP_RAISE THEN
               RETURN;
             END IF;
            
            -- VALIDAR SE EXIBIRÁ O ERRO OU SE APENAS ENVIAR NOTIFICAÇÃO
            IF NVL(P_TIPOALERTA,'N') IN ('E','N') THEN
              
               -- VALIDAR SE ESTÁ NO SANKHYA-W OU OUTRO PROGRAMA
               IF TRIM(P_PROGRAM) = 'JDBC Thin Client' THEN
                 
                  /*RAISE_APPLICATION_ERROR(-20101,
                 '<br><br><b>Atenção!</b><br>'||
                 '--------------------------------------------------------------------<br>'||
                 ''||REPLACE(P_MSG,'<br>',CHR(13))||''||
                 '<br>--------------------------------------------------------------------<br><br>'||
                 '<b>Mensagem documentada em:</b><br>TABELA: &lt;'||P_TBL||'&gt; - ERRO: &lt;'||P_CER||'&gt;<br><br>'||
                 '<a href="mailto:'||P_EMAILLOG||'?subject='||P_ASSUNTOLOG||
                 '&body=Mensagem documentada na TABELA: '||P_TBL||' - ERRO: '||P_CER||
                 ' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - > *** Anexe o print e informe mais detalhes ***" target="_blank">'||
                 '<b>Enviar por e-mail</b>'||
                 '</a><br><br>'||
                 '<a href="../mge/DynaformLauncher.xhtml5?resourceID=br.com.sankhya.menu.adicional.HELPDESK&entityName=HELPDESK&pureDynaform=true#" target="_blank">'||
                 '<b>Abrir ServiceDesk</b></a><br>');*/
               
                 RAISE_APPLICATION_ERROR(-20101,
                 '<br><br><b><font face="Verdana" size="12" color="#4682B4">Atenção!</font></b><br>'||
                 '--------------------------------------------------------------------<br>'||
                 '<font face="Verdana" size="11" color="#FF0000">'||REPLACE(P_MSG,'<br>',CHR(13))||'</font>'||
                 '<br>--------------------------------------------------------------------<br><br>'||
                 '<font face="Verdana" size="10"><b>Mensagem documentada em:</b><br>TABELA: &lt;'||P_TBL||'&gt; - ERRO: &lt;'||P_CER||'&gt;</font><br><br>'||
                 '<a href="mailto:'||P_EMAILLOG||'?subject='||P_ASSUNTOLOG||
                 '&body=Mensagem documentada na TABELA: '||P_TBL||' - ERRO: '||P_CER||
                 ' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - > *** Anexe o print e informe mais detalhes ***" target="_blank">'||
                 '<b><font face="Verdana" size="10" color="#FF0000">Enviar por e-mail</font></b>'||
                 '</a><br><br>'||
                 '<a href="../mge/DynaformLauncher.xhtml5?resourceID=br.com.sankhya.menu.adicional.HELPDESK&entityName=HELPDESK&pureDynaform=true#" target="_blank">'||
                 '<b><font face="Verdana" size="11" color="#006400">Abrir ServiceDesk</font></b></a><br>');
                 
                 RAISE_APPLICATION_ERROR(-20101,'Erro/Aviso'||CHR(13)||CHR(13)||
                   regexp_replace(
                   REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(P_MSG
                   ,'<br>',CHR(13)),'<b>','``'),'</b>','´´'),'<i>','"'),'</i>','"'), '<.*?>')||CHR(13)||CHR(13)||
                   'Mensagem documentada em: '||CHR(13)||'TABELA: ['||P_TBL||'] - ERRO: ['||P_CER||']'||CHR(13)||CHR(13));
                 
               ELSE
               
                   RAISE_APPLICATION_ERROR(-20101,'Erro/Aviso'||CHR(13)||CHR(13)||
                   regexp_replace(
                   REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(P_MSG
                   ,'<br>',CHR(13)),'<b>','``'),'</b>','´´'),'<i>','"'),'</i>','"'), '<.*?>')||CHR(13)||CHR(13)||
                   'Mensagem documentada em: '||CHR(13)||'TABELA: ['||P_TBL||'] - ERRO: ['||P_CER||']'||CHR(13)||CHR(13));
               
               END IF;
           ELSE
               RETURN;
           END IF;
         END IF;
         /*DynaformLauncher.flex?resourceID=br.com.sankhya.menu.adicional.HELPDESK&entityName=HELPDESK&pureDynaform=true#*/
    END IF;

END;
/