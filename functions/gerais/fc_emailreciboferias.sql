CREATE OR REPLACE FUNCTION SANKHYA.EmailReciboFerias(
    NOMEFUNC IN VARCHAR2,
    DTPREVISTA IN DATE,
    DTFIM IN DATE,
    NUMDIASFER IN INTEGER,
    EMAILFUN IN VARCHAR2,
    PERIODO IN INTEGER,
    ORIGEM IN VARCHAR2
)
RETURN BOOLEAN
IS
    C_TITULO VARCHAR2(250) := 'A T E N C A O! Recibo de férias.';
    S_INICIO VARCHAR2(3200) := '<hr>O seu <b>recibo de férias</b> ';
    S_NOME VARCHAR2(250);
    S_MENSAGEM VARCHAR2(3200);
    S_FINAL VARCHAR2(3200);
    S_CC VARCHAR2(250) := ',copiaferias@grupocopar.com.br'; -- Grupo de e-mail para monitoramento do envio do recibo
    S_DESTINATARIO VARCHAR2(250);
    URL_IMAGEM VARCHAR2(200) := 'http://201.28.170.211:8080/assinatura/reciboFerias.jpg';

    /*
        Author: Danilo
    */


BEGIN
    IF EMAILFUN IS NOT NULL THEN
        S_DESTINATARIO := EMAILFUN || S_CC;

        S_NOME := 'Olá <b>' || NOMEFUNC || '</b>! <br><br>';
        S_FINAL := '<br><b>Férias - Período de Gozo</b><br><b>' || DTPREVISTA || '</b> até <b>' || DTFIM || '</b><br>' || NUMDIASFER || ' dias<br><br>';

        S_MENSAGEM := S_NOME || S_INICIO || ', com início em ' || DTPREVISTA || ' estará disponível até ' || TRUNC(TO_DATE(DTPREVISTA) - 2);
        S_MENSAGEM := S_MENSAGEM || ' no Sankhya-W, na tela Holerite.<hr/><br>';
        S_MENSAGEM := S_MENSAGEM || '<hr/><br><img src="' || URL_IMAGEM || '"><br><br>';
        S_MENSAGEM := S_MENSAGEM || '<br><br> Este é o ' || PERIODO || 'º período de férias, sendo ' || NUMDIASFER || ' dias<br><br><br>';
        S_MENSAGEM := S_MENSAGEM || '<hr/><br>';
        S_MENSAGEM := S_MENSAGEM || S_FINAL;
        S_MENSAGEM := S_MENSAGEM || '<hr/><br><br>';
        S_MENSAGEM := S_MENSAGEM || ' Administração de Pessoal<br><br><br><br>';
        S_MENSAGEM := S_MENSAGEM || '<hr><br> ' || ORIGEM;

        EMAIL(S_DESTINATARIO, C_TITULO, S_MENSAGEM);

        RETURN TRUE;
    END IF;

    RETURN FALSE;
END;
/
