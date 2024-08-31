CREATE OR REPLACE PROCEDURE SANKHYA.SEND_NOTIFICATION (
    p_destinatario_usuario NUMBER,  -- Usuário destinatário (se aplicável)
    p_destinatario_grupo NUMBER,   -- Grupo destinatário (se aplicável)
    p_assunto VARCHAR2,            -- Assunto da mensagem
    p_mensagem VARCHAR2,           -- Conteúdo da mensagem
    p_prioridade NUMBER DEFAULT 3, -- 0: Urgente (tela), 1: Alta, 2: Média, 3: Baixa, Negativo: Múltiplas notificações
    p_remetente NUMBER DEFAULT STP_GET_CODUSULOGADO -- Usuário remetente (padrão: usuário logado)
) AS

    v_proximo_numero_aviso NUMBER;
    v_existe_registro NUMBER;
    v_prioridade_atual NUMBER;
    v_remetente_nome VARCHAR2(4000);
    
     -- Variáveis locais para substituir os parâmetros de entrada
    v_destinatario_grupo NUMBER;
    v_prioridade NUMBER;
    
    /***************************************************************************
     * Procedure : SEND_NOTIFICATION
     * Autor     : Danilo Fernando <danilo.bossanova@hotmail.com>
     * Data      : 31/08/2024 09:09:17
     * Objetivo  : Esta procedure refina a implementação anterior de SEND_AVISO2.
     *             Ela permite o envio de até duas notificações quando um valor
     *             de prioridade negativo é passado. A primeira notificação terá
     *             prioridade 0 (urgente) e a segunda refletirá o valor absoluto 
     *             da prioridade negativa, limitado a 3. Isso garante a entrega
     *             eficiente das notificações com uma gestão clara das prioridades.
     * 
     * Parâmetros:
     *   - p_destinatario_usuario (NUMBER): ID do usuário destinatário (opcional).
     *   - p_destinatario_grupo (NUMBER): ID do grupo destinatário (opcional).
     *   - p_assunto (VARCHAR2): Assunto da notificação (obrigatório).
     *   - p_mensagem (VARCHAR2): Conteúdo da notificação (obrigatório).
     *   - p_prioridade (NUMBER, padrão 3): Nível de prioridade da notificação.
     *     0: Urgente, 1: Alta, 2: Média, 3: Baixa. 
     *     Se negativo, gera duas notificações.
     *   - p_remetente (NUMBER, padrão usuário atual): ID do remetente.
     * 
     * Melhorias:
     *   - Suporte a duas notificações com diferentes prioridades quando utilizada prioridade negativa.
     *   - Garante a integridade dos dados validando tanto usuários quanto grupos destinatários.
     *   - Gerencia a expiração das notificações com base na prioridade.
     *
     * Exemplo de Uso:
     *   EXECUTE SEND_NOTIFICATION(101, NULL, 'Atualização Importante', 'Sistema ficará indisponível', -2);
     * 
     ***************************************************************************/

    
    

BEGIN

     -- Inicialização das variáveis locais com os valores dos parâmetros
    v_destinatario_grupo := p_destinatario_grupo;
    v_prioridade := p_prioridade;

    -- Validação do Remetente
    SELECT COUNT(*) INTO v_existe_registro FROM TSIUSU WHERE CODUSU = p_remetente;
    IF v_existe_registro = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Remetente inválido.'); 
    END IF;

    -- Obtenção do Nome do Remetente
    SELECT NOMEUSU INTO v_remetente_nome FROM TSIUSU WHERE CODUSU = p_remetente;

    -- Validação do Destinatário (Usuário ou Grupo)
    IF p_destinatario_usuario IS NOT NULL THEN
        SELECT COUNT(*) INTO v_existe_registro FROM TSIUSU WHERE CODUSU = p_destinatario_usuario;
        IF v_existe_registro = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Usuário destinatário inválido.'); 
        END IF;
        v_destinatario_grupo := NULL;  -- Aqui é usada a variável local

    ELSIF v_destinatario_grupo IS NOT NULL THEN
        SELECT COUNT(*) INTO v_existe_registro FROM TSIGRU WHERE CODGRUPO = v_destinatario_grupo;
        IF v_existe_registro = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Grupo destinatário inválido.');
        END IF;

    ELSE
        RAISE_APPLICATION_ERROR(-20004, 'É necessário informar um destinatário (usuário ou grupo).');
    END IF;

    -- Validação do Assunto
    IF p_assunto IS NULL THEN
        RAISE_APPLICATION_ERROR(-20005, 'O assunto da mensagem é obrigatório.');
    END IF;

    -- Lógica para Múltiplas Notificações (Prioridade Negativa)
    IF v_prioridade < 0 THEN
        v_prioridade_atual := 0;

        -- Obtenção do Próximo Número de Aviso (Primeira Notificação com Prioridade 0)
        SELECT NVL(MAX(NUAVISO),0) + 1 INTO v_proximo_numero_aviso FROM TSIAVI;

        -- Inserção da Primeira Notificação com Prioridade 0
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
            SYSDATE - 0.1/24, -- Notificação imediata
            p_remetente,
            NULL,
            SYSDATE + 1/24  -- Expira em 1 hora
        );

        -- Preparando a Segunda Notificação com a Prioridade Ajustada
        v_prioridade_atual := LEAST(ABS(v_prioridade), 3);

        -- Obtenção do Próximo Número de Aviso (Segunda Notificação)
        SELECT NVL(MAX(NUAVISO),0) + 1 INTO v_proximo_numero_aviso FROM TSIAVI;

        -- Inserção da Segunda Notificação com Prioridade Ajustada
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

    -- Lógica para Prioridade Normal (Não Negativa)
    ELSE
        v_prioridade := CASE
            WHEN v_prioridade > 3 THEN 3 
            ELSE v_prioridade
        END;

        -- Obtenção do Próximo Número de Aviso
        SELECT NVL(MAX(NUAVISO),0) + 1 INTO v_proximo_numero_aviso FROM TSIAVI;

        -- Inserção do Aviso
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
