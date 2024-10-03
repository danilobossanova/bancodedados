CREATE OR REPLACE PACKAGE BODY SANKHYA.PKG_API_DCCO
IS 
  /*
   * Author: Flávio Lourenço da Silva
   * Date: 10/06/2024
   * Process: Enviar e receber requisições http
   */

FUNCTION FC_SEND_REQ_HTTP(P_URL VARCHAR2, P_METHOD VARCHAR2, P_CONTENT IN CLOB, P_JSESSIONID VARCHAR2 DEFAULT NULL, P_RETURN OUT CLOB) RETURN BINARY_INTEGER
IS
  /*
   * Author: Flávio Lourenço da Silva
   * Date: 10/06/2024
   * Process: Envia a requisição para o controlador HHTP 
  */
   V_REQUEST  utl_http.req;
   V_RESPONSE utl_http.resp;
   V_STATUS   binary_integer;

BEGIN
   -- Abre uma nova solicitação HTTP
   V_REQUEST := UTL_HTTP.BEGIN_REQUEST(P_URL, P_METHOD, 'HTTP/1.1');
   UTL_HTTP.SET_HEADER(V_REQUEST, 'User-Agent','Mozilla/4.0');
   UTL_HTTP.SET_HEADER(V_REQUEST, 'Content-Type','application/json');
   UTL_HTTP.SET_HEADER(V_REQUEST, 'Accept','*/*');
-- UTL_HTTP.SET_AUTHENTICATION(V_REQUEST, '','', 'Basic');
   
   -- Argumentos
   IF P_CONTENT IS NOT NULL THEN
    UTL_HTTP.SET_HEADER(V_REQUEST, 'Content-Length', LENGTH(P_CONTENT));
   END IF;
   
   -- Vindo do login ERP
   IF P_JSESSIONID IS NOT NULL THEN
    UTL_HTTP.SET_HEADER(V_REQUEST, 'Cookie', 'JSESSIONID=' || P_JSESSIONID);
   END IF;

   -- Define o corpo da solicitação HTTP com o conteúdo de entrada
   IF P_CONTENT IS NOT NULL THEN 
    UTL_HTTP.WRITE_TEXT(V_REQUEST, P_CONTENT);
   END IF;

   -- Envia a solicitação HTTP e obtém a resposta
   V_RESPONSE := UTL_HTTP.GET_RESPONSE(V_REQUEST);

   -- Lê a resposta da solicitação HTTP e armazena no parâmetro de saída
   UTL_HTTP.READ_TEXT(V_RESPONSE, P_RETURN);

   -- Obtém o código de status HTTP da resposta
   V_STATUS := V_RESPONSE.STATUS_CODE;

   -- Limpa a resposta da solicitação HTTP atual
   UTL_HTTP.END_RESPONSE(V_RESPONSE);
   --  UTL_HTTP.CLEAR_RESPONSE(V_RESPONSE);

   -- Retorna o código de status HTTP
   RETURN(V_STATUS);

EXCEPTION
   -- trata as exceções do pacote utl_http
   WHEN UTL_HTTP.TOO_MANY_REQUESTS THEN
      RAISE_APPLICATION_ERROR(-20001, 'Muitas solicitações HTTP abertas');
   WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20002, 'Erro ao enviar a requisição HTTP: ' || SQLERRM);
END;

FUNCTION FC_LOGIN_SNK RETURN VARCHAR2
IS
  /*
   * Author: Flávio Lourenço da Silva
   * Date: 18/06/2024
   * Process: Retorna o SessionID do login com o ERP Sankhya 
  */
  P_URL         varchar2(1000);
  P_JSESSIONID  varchar2(2000);
  P_STATUS      integer;
  P_RETURN      clob;
  P_CONTENT     clob;

BEGIN
  P_URL := PKG_API_DCCO.URL_SNK || '/mge/service.sbr?serviceName=MobileLoginSP.login&outputType=json';
  P_CONTENT := '{
     "serviceName": "MobileLoginSP.login",
        "requestBody": {
             "NOMUSU": {
                 "$": "USER_HTTP"
             },
             "INTERNO":{
                "$":"dc6G>B860>$P"
             },
            "KEEPCONNECTED": {
                "$": "S"
            }
        }
    }';
  P_STATUS := PKG_API_DCCO.FC_SEND_REQ_HTTP(P_URL, 'POST', P_CONTENT, NULL, P_RETURN);

  IF P_STATUS BETWEEN 200 AND 299 THEN
    SELECT jsessionid
      INTO P_JSESSIONID
      FROM JSON_TABLE (
             P_RETURN,
             '$'
             COLUMNS (
               NESTED PATH '$.responseBody.jsessionid'
                 COLUMNS (jsessionid VARCHAR2 PATH '$.*')));
  
  
    RETURN P_JSESSIONID;
  ELSE
    RETURN 'Erro ao enviar a requisição HTTP Login Status: ' || P_STATUS;
  END IF;   
END;

FUNCTION FC_LOGIN_SNK_TESTE RETURN VARCHAR2
IS
  /*
   * Author: Flávio Lourenço da Silva
   * Date: 18/06/2024
   * Process: Retorna o SessionID do login com o ERP Sankhya 
  */
  P_URL         varchar2(1000);
  P_JSESSIONID  varchar2(2000);
  P_STATUS      integer;
  P_RETURN      clob;
  P_CONTENT     clob;

BEGIN

  P_URL := PKG_API_DCCO.URL_SNK_TESTE || '/mge/service.sbr?serviceName=MobileLoginSP.login&outputType=json';
  P_CONTENT := '{
     "serviceName": "MobileLoginSP.login",
        "requestBody": {
             "NOMUSU": {
                 "$": "USER_HTTP"
             },
             "INTERNO":{
                "$":"dc6G>B860>$P"
             },
            "KEEPCONNECTED": {
                "$": "S"
            }
        }
    }';
  P_STATUS := PKG_API_DCCO.FC_SEND_REQ_HTTP(P_URL, 'POST', P_CONTENT, NULL, P_RETURN);

  IF P_STATUS BETWEEN 200 AND 299 THEN
    SELECT jsessionid
      INTO P_JSESSIONID
      FROM JSON_TABLE (
             P_RETURN,
             '$'
             COLUMNS (
               NESTED PATH '$.responseBody.jsessionid'
                 COLUMNS (jsessionid VARCHAR2 PATH '$.*')));
  
    RETURN P_JSESSIONID;
  ELSE
    RETURN 'Erro ao enviar a requisição HTTP Login Status: ' || P_STATUS;
  END IF;   
END;

FUNCTION FC_CONFIRMA_NOTA(P_NUNOTA NUMBER, P_MENSAGEM OUT VARCHAR2) RETURN NUMBER 
IS
  /*
   * Author: Flávio Lourenço da Silva
   * Date: 25/07/2024
   * Process: Confirma a NuNota no ERP Sankhya 
  */
  P_URL         varchar2(1000);
  P_JSESSIONID  varchar2(2000);
  P_STATUS      integer;
  P_RETURN      clob;
  P_CONTENT     clob;

BEGIN

  P_JSESSIONID := PKG_API_DCCO.FC_LOGIN_SNK_TESTE;
  P_URL := PKG_API_DCCO.URL_SNK_TESTE || '/mgecom/service.sbr?serviceName=ServicosNfeSP.confirmarNotas&mgeSession=' || P_JSESSIONID || '&outputType=json';
  P_CONTENT := '{
      "serviceName":"ServicosNfeSP.confirmarNotas",
      "requestBody": {
          "notas": {
              "compensarNotaAutomaticamente":"false",
              "NUNOTA":{
                  "$":"' || P_NUNOTA || '"
              }
          },
          "clientEventList": {
              "clientEvent":[
                  {
                      "$":"br.com.sankhya.actionbutton.clientconfirm"
                  }
              ]
          }
      }
  }';

-- Simplificado  
--  {
--    "serviceName": "ServicosNfeSP.confirmarNotas",
--    "requestBody": {
--        "notas": {
--            "nunota": [{
--                    "$": 4701867
--                }
--            ]
--        }
--    }
--  }
  P_STATUS := PKG_API_DCCO.FC_SEND_REQ_HTTP(P_URL, 'POST', P_CONTENT, P_JSESSIONID, P_RETURN);

  IF P_STATUS BETWEEN 200 AND 299 THEN
    SELECT NVL (statusMessage,' ') statusMessage,
           NVL (status,0) status
      INTO P_MENSAGEM, P_STATUS
      FROM JSON_TABLE (
              P_RETURN,
              '$'
              COLUMNS (
                statusMessage VARCHAR (1000) PATH '$.statusMessage',
                status VARCHAR (1) PATH '$.status'
              )
            );

    IF P_STATUS = 0 THEN
      P_MENSAGEM := 'Verifique a mensagem de retorno: ' || P_MENSAGEM;
    ELSE
      P_MENSAGEM := 'Nota confirmada com sucesso, mensagem: ' || P_MENSAGEM;
    END IF;   
  ELSE
    P_STATUS := 0;
    P_MENSAGEM := 'Erro ao enviar a requisição HTTP Confirma NuNota Status: ' || P_STATUS;
  END IF;
  RETURN P_STATUS;
   
END;

FUNCTION FC_CONFIRMA_LIST_NOTAS(P_LIST CLOB, P_MENSAGEM OUT VARCHAR2) RETURN NUMBER 
IS
  /*
   * Author: Flávio Lourenço da Silva
   * Date: 25/07/2024
   * Process: Confirma a NuNota no ERP Sankhya 
  */
  P_URL         varchar2(1000);
  P_JSESSIONID  varchar2(2000);
  P_STATUS      integer;
  P_RETURN      clob;
  P_CONTENT     clob;

BEGIN

  /* Exemplo JSON */
  --P_LIST := '{ "$": NUNOTA01}, {"$": NUNOTA02}';

  P_JSESSIONID := PKG_API_DCCO.FC_LOGIN_SNK;
  P_URL := PKG_API_DCCO.URL_SNK || '/mgecom/service.sbr?serviceName=ServicosNfeSP.confirmarNotas&mgeSession=' || P_JSESSIONID || '&outputType=json';
  P_CONTENT := '{
      "serviceName": "ServicosNfeSP.confirmarNotas",
      "requestBody": {
          "notas": {
              "nunota": [' || P_LIST || ']
          }
      }
  }';
  P_STATUS := PKG_API_DCCO.FC_SEND_REQ_HTTP(P_URL, 'POST', P_CONTENT, P_JSESSIONID, P_RETURN);

  IF P_STATUS BETWEEN 200 AND 299 THEN
    SELECT NVL (statusMessage,' ') statusMessage,
           NVL (status,0) status
      INTO P_MENSAGEM, P_STATUS
      FROM JSON_TABLE (
              P_RETURN,
              '$'
              COLUMNS (
                statusMessage VARCHAR (1000) PATH '$.statusMessage',
                status VARCHAR (1) PATH '$.status'
              )
            );

    IF P_STATUS = 0 THEN
      P_MENSAGEM := 'Verifique a mensagem de retorno: ' || P_MENSAGEM;
    ELSE
      P_MENSAGEM := 'Notas confirmadas com sucesso, mensagem: ' || P_MENSAGEM;  
    END IF;   
  ELSE
    P_STATUS := 0;
    P_MENSAGEM := 'Erro ao enviar a requisição HTTP Confirma List NuNota Status: ' || P_STATUS;
  END IF;
  RETURN P_STATUS;
END;

FUNCTION FC_FATURAR_ESTOQUE(P_NUNOTA NUMBER, P_CODTIPOPER NUMBER, P_MENSAGEM OUT VARCHAR2) RETURN NUMBER 
IS
  /*
   * Author: Flávio Lourenço da Silva
   * Date: 29/07/2024
   * Process: Fatura a NuNota no ERP Sankhya pelo Estoque 
  */
  P_URL         varchar2(1000);
  P_JSESSIONID  varchar2(2000);
  P_STATUS      integer;
  P_RETURN      clob;
  P_CONTENT     clob;
  
  P_SERIE       NUMBER;
  P_DTFATUR     DATE;
  P_DTSAIDA     DATE;
  P_HRSAIDA     VARCHAR2(10);

BEGIN

  /* Param Fatura */
  --P_CODTIPOPER := 1830; 
  P_DTFATUR    := SYSDATE; 
  P_SERIE      := 1;  
  P_DTSAIDA    := TRUNC(SYSDATE); 
  P_HRSAIDA    := TO_CHAR(SYSDATE, 'HH24:MI:SS');

  P_JSESSIONID := PKG_API_DCCO.FC_LOGIN_SNK;
  P_URL := PKG_API_DCCO.URL_SNK || '/mgecom/service.sbr?serviceName=SelecaoDocumentoSP.faturar&mgeSession=' || P_JSESSIONID || '&outputType=json';
  P_CONTENT := '  {
     "serviceName":"SelecaoDocumentoSP.faturar",
     "requestBody":{
        "notas":{
           "codTipOper":' || P_CODTIPOPER || ',
           "dtFaturamento":"' || P_DTFATUR || '",
           "serie":"' || P_SERIE || '", 
           "dtSaida":"' || P_DTSAIDA || '",
           "hrSaida":"' || P_HRSAIDA || '",
           "tipoFaturamento":"FaturamentoEstoque",
           "dataValidada": true,
           "notasComMoeda":{
           },
           "nota":[
              {
                 "$":' || P_NUNOTA || '
              }
           ],
           "faturarTodosItens":true
        }
     }
  }';


  P_STATUS := PKG_API_DCCO.FC_SEND_REQ_HTTP(P_URL, 'POST', P_CONTENT, P_JSESSIONID, P_RETURN);

   SEND_NOTIFICATION(68, NULL, 'PKG_API_DCCO', P_RETURN , -1);
   COMMIT;
    

  IF P_STATUS BETWEEN 200 AND 299 THEN
    SELECT NVL (statusMessage,' ') statusMessage,
           NVL (status,0) status
      INTO P_MENSAGEM, P_STATUS
      FROM JSON_TABLE (
              P_RETURN,
              '$'
              COLUMNS (
                statusMessage VARCHAR (1000) PATH '$.statusMessage',
                status VARCHAR (1) PATH '$.status'
              )
            );

  --raise_application_error(-20101,'>> ' || P_RETURN || ' Mensagem: '|| P_MENSAGEM);
                
    IF P_STATUS = 0 THEN
      P_MENSAGEM := 'Verifique a mensagem de retorno: ' || P_MENSAGEM;
    ELSE
      P_MENSAGEM := 'Nota faturada com sucesso, mensagem: ' || P_MENSAGEM;  
    END IF;   
  ELSE
    P_STATUS := 0;
    P_MENSAGEM := 'Erro ao enviar a requisição HTTP Fatura Estoque Status: ' || P_STATUS;
  END IF;
  RETURN P_STATUS;
   
END;

FUNCTION FC_LIBERAR_DOCA(P_CODDOCA NUMBER, P_MENSAGEM OUT VARCHAR2) RETURN NUMBER 
IS
  /*
   * Author: Danilo Fernando <danilo.bossanova@hotmail.com>
   * Date: 27/08/2024 12:35
   * Process: Libera a doca
  */
  P_URL           VARCHAR2(1000);
  P_JSESSIONID    VARCHAR2(2000);
  P_STATUS        INTEGER;
  P_RETURN        CLOB;
  P_CONTENT       CLOB;

BEGIN
  -- Realiza o login e obtém o JSESSIONID
  P_JSESSIONID := PKG_API_DCCO.FC_LOGIN_SNK;

  -- Define a URL do serviço e o corpo da requisição
  P_URL := PKG_API_DCCO.URL_SNK || '/mgewms/service.sbr?serviceName=ExpedicaoMercadoriaSP.liberarDoca&mgeSession=' || P_JSESSIONID || '&outputType=json';
  P_CONTENT := '{
    "serviceName": "ExpedicaoMercadoriaSP.liberarDoca",
    "requestBody": {
        "parametros": {
            "doca": [
                {
                    "codDoca": ' || P_CODDOCA || '
                }
            ]
        },
        "clientEventList": {
            "clientEvent": [
                {
                    "$": "br.com.sankhya.actionbutton.clientconfirm"
                },
                {
                    "$": "br.com.sankhya.mgewms.existem.etiquetas.geradas"
                }
            ]
        }
    }
  }';

  -- Envia a requisição HTTP
  P_STATUS := PKG_API_DCCO.FC_SEND_REQ_HTTP(P_URL, 'POST', P_CONTENT, P_JSESSIONID, P_RETURN);

  -- Processa a resposta
  IF P_STATUS BETWEEN 200 AND 299 THEN
    SELECT NVL (statusMessage,' ') statusMessage,
           NVL (status,0) status
      INTO P_MENSAGEM, P_STATUS
      FROM JSON_TABLE (
              P_RETURN,
              '$'
              COLUMNS (
                statusMessage VARCHAR (1000) PATH '$.statusMessage',
                status VARCHAR (1) PATH '$.status'
              )
            );

    IF P_STATUS > 0 THEN
      P_MENSAGEM := 'Doca liberada com sucesso: ' || P_MENSAGEM;
    ELSE
      P_MENSAGEM := 'Falha ao liberar a doca, mensagem: ' || P_MENSAGEM;  
    END IF;   
  ELSE
    P_STATUS := 0;
    P_MENSAGEM := 'Erro ao enviar a requisição HTTP para liberar doca. Status: ' || P_STATUS;
  END IF;
  RETURN P_STATUS;
END;





END;
/
