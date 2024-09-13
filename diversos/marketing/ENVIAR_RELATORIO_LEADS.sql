CREATE OR REPLACE PROCEDURE ENVIAR_RELATORIO_LEADS AS
    v_gerente       VARCHAR2(100);
    v_email_destino VARCHAR2(100);
    v_assunto       VARCHAR2(200);
    v_count         NUMBER;
    v_count_atrasados NUMBER;
    v_relatorio     CLOB;
    v_link_contato  CLOB;  -- Para construir o link HTML
    
    v_error_stack VARCHAR2(4000);
    
BEGIN
    -- Cursor para percorrer os gerentes distintos e seus respectivos emails
    FOR gerente_rec IN (
        SELECT DISTINCT GERENTE, EMAILDESTINO 
        FROM VW_LEADS_AB_COM_INFORMACOES
        WHERE EMAILDESTINO IS NOT NULL
    ) LOOP
        -- Tratamento de exceção para o email e dados inválidos
        BEGIN
            v_gerente := gerente_rec.GERENTE;
            v_email_destino := gerente_rec.EMAILDESTINO;

            -- Verifica se o email contém um formato inválido
            IF NOT REGEXP_LIKE(v_email_destino, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') THEN
                DBMS_OUTPUT.PUT_LINE('Email inválido para o gerente ' || v_gerente || ': ' || SQLERRM);
                RAISE_APPLICATION_ERROR(-20001, 'Email inválido para o gerente ' || v_gerente || ': ' || v_email_destino);
            END IF;

            v_relatorio := ''; -- Limpa o relatório para o próximo gerente

            -- Adiciona cabeçalho do relatório para cada gerente
            v_relatorio := v_relatorio || '----------------------------------------' || '<br>';
            v_relatorio := v_relatorio || 'Gerente: ' || v_gerente || '<br>';
            v_relatorio := v_relatorio || '----------------------------------------' || '<br>';
            v_relatorio := v_relatorio || RPAD('Data Criação', 15) || ' | ' || RPAD('URL do Lead', 40) || ' | ' || RPAD('Situação', 10) || ' | ' || 'Data Prevista Retorno <br>';
            v_relatorio := v_relatorio || '----------------------------------------------------------------------------------------<br>';

            -- Inicializa contadores
            v_count := 0;  -- Contador de leads para o gerente
            v_count_atrasados := 0;  -- Contador de leads atrasados

            -- Consulta os leads do gerente e acumula as informações no relatório
            FOR lead_rec IN (
                SELECT DTCRIACAO AS DATA_CRIACAO, 
                       NOME_CONTATO, 
                       CIDADE, 
                       URL, 
                       SITUACAO, 
                       DATA_PREVISTA_RETORNO
                FROM VW_LEADS_AB_COM_INFORMACOES
                WHERE GERENTE = v_gerente
            ) LOOP
                -- Constrói o link HTML com o nome do contato e cidade
                --v_link_contato := '<a href=' || DBMS_ASSERT.ENQUOTE_LITERAL(lead_rec.URL) || '>' || lead_rec.NOME_CONTATO || ' - ' || lead_rec.CIDADE || '</a>';
                v_link_contato := '<a href=' || escape_double_quotes_html(DBMS_ASSERT.ENQUOTE_LITERAL(lead_rec.URL)) || '>' ||  NVL(lead_rec.NOME_CONTATO,'Cliente') ||  '</a>';
                     
                -- Acumula as informações do lead no relatório, incluindo o link HTML
                v_relatorio := v_relatorio || RPAD(lead_rec.DATA_CRIACAO, 15) || ' | ' || RPAD(v_link_contato, 135) || ' | ' || RPAD(lead_rec.SITUACAO, 10) || ' | ' || lead_rec.DATA_PREVISTA_RETORNO || '<br>';

                -- Verifica se o lead está atrasado
                IF lead_rec.SITUACAO = 'ATRASADO' THEN
                    v_count_atrasados := v_count_atrasados + 1;
                END IF;

                -- Incrementa o contador total de leads
                v_count := v_count + 1;
                
                DBMS_OUTPUT.PUT_LINE('Link de Relatorio: ' || v_relatorio );
                
                
            END LOOP;

            -- Mensagem se não houver leads para o gerente
            IF v_count = 0 THEN
                v_relatorio := v_relatorio || 'Nenhum lead aberto encontrado para este gerente.' || '<br>';
            ELSE
                -- Adiciona o total de leads atrasados ao relatório
                v_relatorio := v_relatorio || '----------------------------------------' || '<br>';
                v_relatorio := v_relatorio || 'Total de leads atrasados: ' || v_count_atrasados || '<br>';
                v_relatorio := v_relatorio || '----------------------------------------' || '<br>';
            END IF;

            -- Define o assunto do email
            v_assunto := 'Relatório de Leads Abertos - ' || v_gerente;

            -- Verifica se existem leads atrasados
            IF v_count_atrasados > 0 THEN
                -- Envia a notificação
                SEND_NOTIFICATION(
                    p_destinatario_usuario => 68,  -- Usuário destinatário
                    p_destinatario_grupo => NULL,  -- Grupo destinatário
                    p_assunto => v_assunto,        -- Assunto da notificação
                    p_mensagem => v_relatorio,     -- Conteúdo da notificação
                    p_prioridade => 2              -- Prioridade média
                );
                
                COMMIT;
                
                /*-- Envia o email usando a procedure de email
                SANKHYA.EMAIL(
                    P_EMAIL =>  'danilo.fernando@grupocopar.com.br' /*v_email_destino/,     -- Endereço de email do gerente
                    P_TITULO => v_assunto,          -- Assunto do email
                    P_MSGCLOB => v_relatorio        -- Conteúdo do email (HTML com <br>)
                );
                
                /*COMMIT;*/
                
            ELSE
                -- Caso não existam leads atrasados, envia notificação de "Parabéns"
                SEND_NOTIFICATION(
                    p_destinatario_usuario => 68,  -- Usuário destinatário
                    p_destinatario_grupo => NULL,  -- Grupo destinatário
                    p_assunto => v_assunto,        -- Assunto da notificação
                    p_mensagem => 'Parabéns! Nenhum lead está atrasado!',  -- Mensagem
                    p_prioridade => 2              -- Prioridade média
                );

                /*-- Envia o email de "Parabéns"
                SANKHYA.EMAIL(
                    P_EMAIL =>  'danilo.fernando@grupocopar.com.br', /*v_email_destino,/     -- Endereço de email do gerente
                    P_TITULO => v_assunto,          -- Assunto do email
                    P_MSGCLOB => 'Parabéns! Nenhum lead está atrasado!'  -- Conteúdo do email
                );*/
                
            END IF;

            COMMIT;

        EXCEPTION
            WHEN OTHERS THEN
                -- Captura o erro e exibe a mensagem
                v_error_stack := DBMS_UTILITY.FORMAT_ERROR_STACK;
                DBMS_OUTPUT.PUT_LINE('Erro ao processar o gerente ' || v_gerente || ':');
                DBMS_OUTPUT.PUT_LINE(v_error_stack);
        END;
    END LOOP;
END;
/
