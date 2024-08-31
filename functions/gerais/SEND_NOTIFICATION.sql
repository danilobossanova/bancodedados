CREATE OR REPLACE PROCEDURE SANKHYA.SEND_NOTIFICATION (
    p_destinatario_usuario NUMBER,  -- Usu�rio destinat�rio (se aplic�vel)
    p_destinatario_grupo NUMBER,   -- Grupo destinat�rio (se aplic�vel)
    p_assunto VARCHAR2,            -- Assunto da mensagem
    p_mensagem VARCHAR2,           -- Conte�do da mensagem
    p_prioridade NUMBER DEFAULT 3, -- 0: Urgente (tela), 1: Alta, 2: M�dia, 3: Baixa, Negativo: M�ltiplas notifica��es
    p_remetente NUMBER DEFAULT STP_GET_CODUSULOGADO -- Usu�rio remetente (padr�o: usu�rio logado)
) AS

    v_proximo_numero_aviso NUMBER;
    v_existe_registro NUMBER;
    v_prioridade_atual NUMBER;
    v_remetente_nome VARCHAR2(4000);
    
     -- Vari�veis locais para substituir os par�metros de entrada
    v_destinatario_grupo NUMBER;
    v_prioridade NUMBER;
    
    /***************************************************************************
     * Procedure : SEND_NOTIFICATION
     * Autor     : Danilo Fernando <danilo.bossanova@hotmail.com>
     * Data      : 31/08/2024 09:09:17
     * Objetivo  : Esta procedure refina a implementa��o anterior de SEND_AVISO2.
     *             Ela permite o envio de at� duas notifica��es quando um valor
     *             de prioridade negativo � passado. A primeira notifica��o ter�
     *             prioridade 0 (urgente) e a segunda refletir� o valor absoluto 
     *             da prioridade negativa, limitado a 3. Isso garante a entrega
     *             eficiente das notifica��es com uma gest�o clara das prioridades.
     * 
     * Par�metros:
     *   - p_destinatario_usuario (NUMBER): ID do usu�rio destinat�rio (opcional).
     *   - p_destinatario_grupo (NUMBER): ID do grupo destinat�rio (opcional).
     *   - p_assunto (VARCHAR2): Assunto da notifica��o (obrigat�rio).
     *   - p_mensagem (VARCHAR2): Conte�do da notifica��o (obrigat�rio).
     *   - p_prioridade (NUMBER, padr�o 3): N�vel de prioridade da notifica��o.
     *     0: Urgente, 1: Alta, 2: M�dia, 3: Baixa. 
     *     Se negativo, gera duas notifica��es.
     *   - p_remetente (NUMBER, padr�o usu�rio atual): ID do remetente.
     * 
     * Melhorias:
     *   - Suporte a duas notifica��es com diferentes prioridades quando utilizada prioridade negativa.
     *   - Garante a integridade dos dados validando tanto usu�rios quanto grupos destinat�rios.
     *   - Gerencia a expira��o das notifica��es com base na prioridade.
     *
     * Exemplo de Uso:
     *   EXECUTE SEND_NOTIFICATION(101, NULL, 'Atualiza��o Importante', 'Sistema ficar� indispon�vel', -2);
     * 
     ***************************************************************************/

    
    

BEGIN

     -- Inicializa��o das vari�veis locais com os valores dos par�metros
    v_destinatario_grupo := p_destinatario_grupo;
    v_prioridade := p_prioridade;

    -- Valida��o do Remetente
    SELECT COUNT(*) INTO v_existe_registro FROM TSIUSU WHERE CODUSU = p_remetente;
    IF v_existe_registro = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Remetente inv�lido.'); 
    END IF;

    -- Obten��o do Nome do Remetente
    SELECT NOMEUSU INTO v_remetente_nome FROM TSIUSU WHERE CODUSU = p_remetente;

    -- Valida��o do Destinat�rio (Usu�rio ou Grupo)
    IF p_destinatario_usuario IS NOT NULL THEN
        SELECT COUNT(*) INTO v_existe_registro FROM TSIUSU WHERE CODUSU = p_destinatario_usuario;
        IF v_existe_registro = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Usu�rio destinat�rio inv�lido.'); 
        END IF;
        v_destinatario_grupo := NULL;  -- Aqui � usada a vari�vel local

    ELSIF v_destinatario_grupo IS NOT NULL THEN
        SELECT COUNT(*) INTO v_existe_registro FROM TSIGRU WHERE CODGRUPO = v_destinatario_grupo;
        IF v_existe_registro = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Grupo destinat�rio inv�lido.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20004, '� necess�rio informar um destinat�rio (usu�rio ou grupo).');
    END IF;

    -- Valida��o do Assunto
    IF p_assunto IS NULL THEN
        RAISE_APPLICATION_ERROR(-20005, 'O assunto da mensagem � obrigat�rio.');
    END IF;

    -- L�gica para M�ltiplas Notifica��es (Prioridade Negativa)
    IF v_prioridade < 0 THEN
        v_prioridade_atual := 0;

        -- Obten��o do Pr�ximo N�mero de Aviso (Primeira Notifica��o com Prioridade 0)
        SELECT NVL(MAX(NUAVISO),0) + 1 INTO v_proximo_numero_aviso FROM TSIAVI;

        -- Inser��o da Primeira Notifica��o com Prioridade 0
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
            v_proximo_numero_aviso,
            v_remetente_nome,
            p_assunto,
            SUBSTR(p_mensagem, 1, 2000),
            'PERSONALIZADO',
            v_prioridade_atual,
            p_destinatario_usuario,
            v_destinatario_grupo,
            'P',
            SYSDATE - 0.1/24, -- Notifica��o imediata
            p_remetente,
            NULL,
            SYSDATE + 1/24  -- Expira em 1 hora
        );

        -- Preparando a Segunda Notifica��o com a Prioridade Ajustada
        v_prioridade_atual := LEAST(ABS(v_prioridade), 3);

        -- Obten��o do Pr�ximo N�mero de Aviso (Segunda Notifica��o)
        SELECT NVL(MAX(NUAVISO),0) + 1 INTO v_proximo_numero_aviso FROM TSIAVI;

        -- Inser��o da Segunda Notifica��o com Prioridade Ajustada
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
            v_proximo_numero_aviso,
            v_remetente_nome,
            p_assunto,
            SUBSTR(p_mensagem, 1, 2000),
            'PERSONALIZADO',
            v_prioridade_atual,
            p_destinatario_usuario,
            v_destinatario_grupo,
            'P',
            SYSDATE,
            p_remetente,
            NULL,
            SYSDATE + (CASE v_prioridade_atual WHEN 0 THEN 1/24 ELSE 0 END)  -- Expira conforme a prioridade
        );

    -- L�gica para Prioridade Normal (N�o Negativa)
    ELSE
        v_prioridade := CASE
            WHEN v_prioridade > 3 THEN 3 
            ELSE v_prioridade
        END;

        -- Obten��o do Pr�ximo N�mero de Aviso
        SELECT NVL(MAX(NUAVISO),0) + 1 INTO v_proximo_numero_aviso FROM TSIAVI;

        -- Inser��o do Aviso
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
            v_proximo_numero_aviso,
            v_remetente_nome,
            p_assunto,
            SUBSTR(p_mensagem, 1, 2000), 
            'PERSONALIZADO',
            v_prioridade,
            p_destinatario_usuario,
            v_destinatario_grupo,
            'P',
            SYSDATE - (CASE v_prioridade WHEN 0 THEN 0.1/24 ELSE 0 END),
            p_remetente,
            NULL,
            SYSDATE + (CASE v_prioridade WHEN 0 THEN 1/24 ELSE 0 END) 
        );
    END IF;

END;
/
