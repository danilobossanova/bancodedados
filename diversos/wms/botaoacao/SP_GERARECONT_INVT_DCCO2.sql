CREATE OR REPLACE PROCEDURE SANKHYA."SP_GERARECONT_INVT_DCCO2" (
       P_CODUSU NUMBER,        -- Código do usuário logado
       P_IDSESSAO VARCHAR2,    -- Identificador da execução. Serve para buscar informações dos parâmetros/campos da execução.
       P_QTDLINHAS NUMBER,     -- Informa a quantidade de registros selecionados no momento da execução.
       P_MENSAGEM OUT VARCHAR2 -- Caso seja passada uma mensagem aqui, ela será exibida como uma informação ao usuário.
) AS
       
       -- Declaração de variáveis para campos dos registros
       FIELD_NUIVT NUMBER;
       FIELD_SEQUENCIA NUMBER;
       FIELD_CODPROD NUMBER;
       FIELD_CODEND NUMBER;
       
       -- Variáveis para controle de tarefas e respostas
       V_NUTAREFA NUMBER;
       V_RESPOSTA VARCHAR2(400);
       V_RESPOSTA_ITT VARCHAR2(400);
       V_RESPOSTA_UXT VARCHAR2(400);
       
       -- Variáveis auxiliares para construção de mensagens
       AUX_PRODUTOS_CTG_ABERTAS CLOB := NULL;
       AUX_PRODUTOS_ADICIONADOS CLOB := NULL;
       AUX_PRODUTOS_CONF_OK CLOB := NULL;
       ERRO_ITT CLOB := NULL;
       
       
       
BEGIN

      
       FOR I IN 1..P_QTDLINHAS -- Este loop permite obter o valor de campos dos registros envolvidos na execução.
       LOOP                    -- A variável "I" representa o registro corrente.
          
           -- Obtenção dos campos do registro corrente
           FIELD_NUIVT := ACT_INT_FIELD(P_IDSESSAO, I, 'NUIVT');
           FIELD_SEQUENCIA := ACT_INT_FIELD(P_IDSESSAO, I, 'SEQUENCIA');
           FIELD_CODPROD := ACT_INT_FIELD(P_IDSESSAO, I, 'CODPROD');
           FIELD_CODEND := ACT_INT_FIELD(P_IDSESSAO, I, 'CODEND');


           -- Verificação se o produto possui tarefas de contagem em aberto
           IF FN_CONTAGEM_ABERTAS_DCCO(FIELD_NUIVT, FIELD_CODPROD, FIELD_CODEND) > 0 THEN
               AUX_PRODUTOS_CTG_ABERTAS := AUX_PRODUTOS_CTG_ABERTAS || '<br><b>Código:</b>' || FIELD_CODPROD;
           ELSE
               -- Verificação se a conferência do produto já está ok
               IF FN_CONFERENCIA_OK_DCCO(FIELD_NUIVT, FIELD_CODPROD, FIELD_CODEND) = 1 THEN
                   AUX_PRODUTOS_CONF_OK := AUX_PRODUTOS_CONF_OK || '<br><b>Código:</b>' || FIELD_CODPROD;
               ELSE
                   -- Geração de nova tarefa e inserção de registros relacionados
                   STP_GERAR_NUTAREFA_DCCO(V_NUTAREFA);
                   -- Inserção da tarefa de contagem
                   INSERIR_TGWTAR_DCCO(V_NUTAREFA, 6, 'A', NULL, NULL, NULL, NULL, NULL, P_CODUSU, FIELD_NUIVT, NULL, NULL, 'N', 0, V_RESPOSTA);
                   -- Registro do produto na tarefa de contagem
                   INS_TGWITT_INVT_DCCO(V_NUTAREFA, FIELD_CODPROD, FIELD_CODEND, V_RESPOSTA_ITT);
                   
                   ERRO_ITT := ERRO_ITT || '<br>' || V_RESPOSTA_ITT;
                   
                   -- Definição de inventariante e registro na tarefa
                   DefiniInventariante_DCCO(FIELD_NUIVT, FIELD_CODPROD, V_NUTAREFA, P_CODUSU, V_RESPOSTA_UXT);
                   
                   -- Registro dos produtos para exibir ao usuário
                   AUX_PRODUTOS_ADICIONADOS := AUX_PRODUTOS_ADICIONADOS || '<br><br>Código: ' || FIELD_CODPROD || ' <b>NU TAREFA:</b> ' || V_NUTAREFA;
                   
               END IF;
           END IF; 

       END LOOP;


       -- Construção da mensagem final de retorno
       IF AUX_PRODUTOS_CTG_ABERTAS IS NOT NULL THEN
           P_MENSAGEM := 'Os produtos abaixo já possuem tarefas de recontagem em aberto para este inventário:<br>';
           P_MENSAGEM := P_MENSAGEM || AUX_PRODUTOS_CTG_ABERTAS;
           P_MENSAGEM := P_MENSAGEM || '<br><br><b>Não foram geradas novas tarefas de recontagem para esses itens.</b>';
       END IF; 


        IF AUX_PRODUTOS_CONF_OK IS NOT NULL THEN
           P_MENSAGEM := P_MENSAGEM || '<br><br><b>Produtos com conferência OK</b>:<br>';
           P_MENSAGEM := P_MENSAGEM || AUX_PRODUTOS_CONF_OK;
        END IF;
        
        
        IF AUX_PRODUTOS_ADICIONADOS IS NOT NULL THEN
           P_MENSAGEM := P_MENSAGEM || '<br><br><b>Tarefa de recontagem gerada para os produtos abaixo:</b><br>';
           P_MENSAGEM := P_MENSAGEM || AUX_PRODUTOS_ADICIONADOS;
       END IF;


       IF ERRO_ITT IS NOT NULL THEN
           P_MENSAGEM := P_MENSAGEM || '<br>' || ERRO_ITT;
       END IF;

END;

/