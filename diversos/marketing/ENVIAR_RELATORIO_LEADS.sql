CREATE OR REPLACE PROCEDURE ENVIAR_RELATORIO_LEADS AS
    v_gerente       VARCHAR2(100);
    v_email_destino VARCHAR2(100);
    v_assunto       VARCHAR2(200);
    v_count         NUMBER;
    v_count_atrasados NUMBER;
    v_relatorio     CLOB;
    v_link_contato  VARCHAR2(400);  -- Para construir o link HTML
BEGIN
    -- Cursor para percorrer os gerentes distintos e seus respectivos emails
    FOR gerente_rec IN (
        SELECT DISTINCT GERENTE, EMAILDESTINO 
        FROM VW_LEADS_AB_COM_INFORMACOES
        WHERE EMAILDESTINO IS NOT NULL
    ) LOOP
        -- Tratamento de exce��o para o email e dados inv�lidos
        BEGIN
            v_gerente := gerente_rec.GERENTE;
            v_email_destino := gerente_rec.EMAILDESTINO;

            -- Verifica se o email cont�m um formato inv�lido
            IF NOT REGEXP_LIKE(v_email_destino, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') THEN
                RAISE_APPLICATION_ERROR(-20001, 'Email inv�lido para o gerente ' || v_gerente || ': ' || v_email_destino);
            END IF;

            v_relatorio := ''; -- Limpa o relat�rio para o pr�ximo gerente

            -- Adiciona cabe�alho do relat�rio para cada gerente
            v_relatorio := v_relatorio || '----------------------------------------' || CHR(10);
            v_relatorio := v_relatorio || 'Gerente: ' || v_gerente || CHR(10);
            v_relatorio := v_relatorio || '----------------------------------------' || CHR(10);
            v_relatorio := v_relatorio || RPAD('Data Cria��o', 15) || ' | ' 
                                           || RPAD('URL do Lead', 40) || ' | ' 
                                           || RPAD('Situa��o', 10) || ' | '
                                           || 'Data Prevista Retorno' || CHR(10);
            v_relatorio := v_relatorio || '----------------------------------------------------------------------------------------' || CHR(10);

            -- Inicializa contadores
            v_count := 0;  -- Contador de leads para o gerente
            v_count_atrasados := 0;  -- Contador de leads atrasados

            -- Consulta os leads do gerente e acumula as informa��es no relat�rio
            FOR lead_rec IN (
                SELECT TO_CHAR(DTCRIACAO, 'DD/MM/YYYY') AS DATA_CRIACAO, 
                       NOME_CONTATO, CIDADE, URL, SITUACAO, 
                       TO_CHAR(DATA_PREVISTA_RETORNO, 'DD/MM/YYYY') AS DATA_PREVISTA_RETORNO
                FROM VW_LEADS_AB_COM_INFORMACOES
                WHERE GERENTE = v_gerente
            ) LOOP
                -- Constr�i o link HTML com o nome do contato e cidade
                v_link_contato := '<a href="' || lead_rec.URL || '">' || lead_rec.NOME_CONTATO || ' - ' || lead_rec.CIDADE || '</a>';

                -- Acumula as informa��es do lead no relat�rio, incluindo o link HTML
                v_relatorio := v_relatorio || RPAD(lead_rec.DATA_CRIACAO, 15) || ' | ' 
                                               || RPAD(v_link_contato, 40) || ' | ' 
                                               || RPAD(lead_rec.SITUACAO, 10) || ' | '
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

        EXCEPTION
            WHEN OTHERS THEN
                -- Se houver algum erro ao processar esse gerente, exibe a mensagem de erro
                DBMS_OUTPUT.PUT_LINE('Erro ao processar o gerente ' || v_gerente || ': ' || SQLERRM);
        END;
    END LOOP;
END;
/
