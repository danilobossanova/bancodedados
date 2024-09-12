CREATE OR REPLACE PROCEDURE ENVIAR_RELATORIO_LEADS AS
    v_gerente       VARCHAR2(100);
    v_email_destino VARCHAR2(100);
    v_assunto       VARCHAR2(200);
    v_mensagem      CLOB;
    v_count         NUMBER;
    v_count_atrasados NUMBER;
    v_relatorio     CLOB;
BEGIN
    -- Cursor para percorrer os gerentes distintos e seus respectivos emails
    FOR gerente_rec IN (
        SELECT DISTINCT GERENTE, EMAILDESTINO 
        FROM VW_LEADS_AB_COM_INFORMACOES
        WHERE EMAILDESTINO IS NOT NULL
    ) LOOP
        v_gerente := gerente_rec.GERENTE;
        v_email_destino := gerente_rec.EMAILDESTINO;
        v_relatorio := ''; -- Limpa o relat�rio para o pr�ximo gerente
        
        -- Adiciona cabe�alho do relat�rio para cada gerente
        v_relatorio := v_relatorio || '------------------------------------------------------------------------------------------------------------------------' || CHR(10);
        v_relatorio := v_relatorio || 'Gerente: ' || v_gerente || CHR(10);
        v_relatorio := v_relatorio || '------------------------------------------------------------------------------------------------------------------------' || CHR(10);
        v_relatorio := v_relatorio || 'Data Prevista   | URL do Lead                                                    | Situa��o  | Data Prevista Retorno' || CHR(10);
        v_relatorio := v_relatorio || '------------------------------------------------------------------------------------------------------------------------' || CHR(10);

        -- Inicializa contadores
        v_count := 0;  -- Contador de leads para o gerente
        v_count_atrasados := 0;  -- Contador de leads atrasados

        -- Consulta os leads do gerente e acumula as informa��es no relat�rio
        FOR lead_rec IN (
            SELECT DATA_PREVISTA_RETORNO, '<a href="' || URL || '">' || NOME_CONTATO || ' - ' || CIDADE� ||'</a>' AS LINKCONTATO, SITUACAO
            FROM VW_LEADS_AB_COM_INFORMACOES
            WHERE GERENTE = v_gerente
        ) LOOP
            -- Acumula as informa��es do lead no relat�rio
            v_relatorio := v_relatorio || lead_rec.DATA_PREVISTA_RETORNO || '      | ' 
                                           || SUBSTR(lead_rec.LINKCONTATO, 1, 50) || '...' || ' | ' 
                                           || lead_rec.SITUACAO || '  | '
                                           || lead_rec.DATA_PREVISTA_RETORNO || CHR(10);

            -- Verifica se o lead est� atrasado
            IF lead_rec.SITUACAO = 'ATRASADO' THEN
                v_count_atrasados := v_count_atrasados + 1;
            END IF;

            -- Incrementa o contador total de leads
            v_count := v_count + 1;
        END LOOP;

        -- Mensagem se n�o houver leads para o gerente
        IF v_count = 0 THEN
            v_relatorio := v_relatorio || 'Nenhum lead aberto encontrado para este gerente.' || CHR(10);
        ELSE
            -- Adiciona o total de leads atrasados ao relat�rio
            v_relatorio := v_relatorio || '----------------------------------------' || CHR(10);
            v_relatorio := v_relatorio || 'Total de leads atrasados: ' || v_count_atrasados || CHR(10);
            v_relatorio := v_relatorio || '----------------------------------------' || CHR(10);
        END IF;

        -- Define o assunto do email
        v_assunto := 'Relat�rio de Leads Abertos - ' || v_gerente;

        -- Envia o relat�rio gerado por email
        SEND_NOTIFICATION(
            p_destinatario_usuario => NULL,  -- Usu�rio destinat�rio (n�o especificado)
            p_destinatario_grupo => NULL,    -- Grupo destinat�rio (n�o especificado)
            p_assunto => v_assunto,          -- Assunto do email
            p_mensagem => v_relatorio,       -- Conte�do do email (relat�rio gerado)
            p_prioridade => 2                -- Prioridade m�dia
        );
    END LOOP;
END;
/
