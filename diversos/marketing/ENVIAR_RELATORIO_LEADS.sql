CREATE OR REPLACE PROCEDURE ENVIAR_RELATORIO_LEADS AS
    v_gerente       VARCHAR2(100);
    v_email_destino VARCHAR2(100);
    v_assunto       VARCHAR2(200);
    v_count         NUMBER;
    v_count_atrasados NUMBER;
    v_relatorio     CLOB;
    v_link_contato  VARCHAR2(1000);  -- Aumentado para acomodar URLs longas e formatação HTML
    
    v_error_stack VARCHAR2(4000);
    v_introducao    CLOB;
    
BEGIN
    FOR gerente_rec IN (
        SELECT DISTINCT GERENTE, EMAILDESTINO 
        FROM VW_LEADS_AB_COM_INFORMACOES
        WHERE EMAILDESTINO IS NOT NULL
    ) LOOP
        BEGIN
            v_gerente := gerente_rec.GERENTE;
            v_email_destino := gerente_rec.EMAILDESTINO;

            IF NOT REGEXP_LIKE(v_email_destino, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') THEN
                RAISE_APPLICATION_ERROR(-20001, 'Email inválido para o gerente ' || v_gerente || ': ' || v_email_destino);
            END IF;
            
            
            -- Introdução do relatório
            v_introducao := '<p>Prezado(a) ' || v_gerente || ',</p>' ||
                            '<p>Segue abaixo o relatório diário de leads abertos sob sua responsabilidade. ' ||
                            'Este relatório visa mantê-lo(a) informado(a) sobre o status atual dos leads, ' ||
                            'destacando aqueles que necessitam de atenção imediata.</p>' ||
                            '<p>Por favor, revise os leads listados e tome as ações necessárias, ' ||
                            'especialmente para aqueles marcados como ATRASADOS.</p>';

            v_relatorio := v_introducao;

            v_relatorio := '';
            v_relatorio := v_relatorio || '<table style="border-collapse: collapse; width: 100%;">';
            v_relatorio := v_relatorio || '<tr><th colspan="4" style="text-align: left; padding: 8px; background-color: #f2f2f2;">Gerente: ' || v_gerente || '</th></tr>';
            v_relatorio := v_relatorio || '<tr>';
            v_relatorio := v_relatorio || '<th style="border: 1px solid #ddd; padding: 8px;">Data Criação</th>';
            v_relatorio := v_relatorio || '<th style="border: 1px solid #ddd; padding: 8px;">Nome do Contato</th>';
            v_relatorio := v_relatorio || '<th style="border: 1px solid #ddd; padding: 8px;">Situação</th>';
            v_relatorio := v_relatorio || '<th style="border: 1px solid #ddd; padding: 8px;">Data Prevista Retorno</th>';
            v_relatorio := v_relatorio || '</tr>';

            v_count := 0;
            v_count_atrasados := 0;

            FOR lead_rec IN (
                SELECT DTCRIACAO AS DATA_CRIACAO, 
                       NVL(NOME_CONTATO, 'Cliente') AS NOME_CONTATO, 
                       URL, 
                       SITUACAO, 
                       DATA_PREVISTA_RETORNO
                FROM VW_LEADS_AB_COM_INFORMACOES
                WHERE GERENTE = v_gerente
                ORDER BY DTCRIACAO DESC
                
            ) LOOP
                v_link_contato := '<a href="' || escape_double_quotes_html(lead_rec.URL) || '">' || SUBSTR(lead_rec.NOME_CONTATO, 1, 40) || '</a>';
                
                v_relatorio := v_relatorio || '<tr>';
                v_relatorio := v_relatorio || '<td style="border: 1px solid #ddd; padding: 8px;">' || lead_rec.DATA_CRIACAO || '</td>';
                v_relatorio := v_relatorio || '<td style="border: 1px solid #ddd; padding: 8px;">' || v_link_contato || '</td>';
                v_relatorio := v_relatorio || '<td style="border: 1px solid #ddd; padding: 8px;">' || lead_rec.SITUACAO || '</td>';
                v_relatorio := v_relatorio || '<td style="border: 1px solid #ddd; padding: 8px;">' || lead_rec.DATA_PREVISTA_RETORNO || '</td>';
                v_relatorio := v_relatorio || '</tr>';

                IF lead_rec.SITUACAO = 'ATRASADO' THEN
                    v_count_atrasados := v_count_atrasados + 1;
                END IF;

                v_count := v_count + 1;
            END LOOP;

            IF v_count = 0 THEN
                v_relatorio := v_relatorio || '<tr><td colspan="4" style="border: 1px solid #ddd; padding: 8px;">Nenhum lead aberto encontrado para este gerente.</td></tr>';
            END IF;

            v_relatorio := v_relatorio || '</table>';
            v_relatorio := v_relatorio || '<p>Total de leads: ' || v_count || '</p>';
            v_relatorio := v_relatorio || '<p>Total de leads atrasados: ' || v_count_atrasados || '</p>';

            v_assunto := 'Relatório de Leads Abertos - ' || v_gerente;

            SEND_NOTIFICATION(p_destinatario_usuario => 68,p_destinatario_grupo => NULL,p_assunto => v_assunto,p_mensagem => v_relatorio,p_prioridade => 2);
            SEND_NOTIFICATION(p_destinatario_usuario => 1058,p_destinatario_grupo => NULL,p_assunto => v_assunto,p_mensagem => v_relatorio,p_prioridade => 2);
            SEND_NOTIFICATION(p_destinatario_usuario => 1087,p_destinatario_grupo => NULL,p_assunto => v_assunto,p_mensagem => v_relatorio,p_prioridade => 2);
            --SEND_NOTIFICATION(p_destinatario_usuario => 50576,p_destinatario_grupo => NULL,p_assunto => v_assunto,p_mensagem => v_relatorio,p_prioridade => 2);

            COMMIT;
            
            SANKHYA.EMAIL(P_EMAIL => 'danilo.fernando@grupocopar.com.br',  P_TITULO => v_assunto, P_MSGCLOB => v_relatorio);
            
            COMMIT;

        EXCEPTION
            WHEN OTHERS THEN
                v_error_stack := DBMS_UTILITY.FORMAT_ERROR_STACK;
                DBMS_OUTPUT.PUT_LINE('Erro ao processar o gerente ' || v_gerente || ': ' || v_error_stack);
        END;
    END LOOP;
END;
/