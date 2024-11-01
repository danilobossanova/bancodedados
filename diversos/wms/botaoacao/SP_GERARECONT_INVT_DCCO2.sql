CREATE OR REPLACE PROCEDURE SANKHYA."SP_GERARECONT_INVT_DCCO2" (
       P_CODUSU NUMBER,        -- Código do usuário logado
       P_IDSESSAO VARCHAR2,    -- Identificador da execução. Serve para buscar informações dos parâmetros/campos da execução.
       P_QTDLINHAS NUMBER,     -- Informa a quantidade de registros selecionados no momento da execução.
       P_MENSAGEM OUT VARCHAR2 -- Caso seja passada uma mensagem aqui, ela será exibida como uma informação ao usuário.
) AS
       
        /* Tipos */
    TYPE t_reg_produto IS RECORD (
        nu_ivt      NUMBER,
        sequencia   NUMBER,
        cod_prod    NUMBER,
        cod_end     NUMBER
    );
    
    /* Cursor para processar produtos */
    CURSOR c_produtos IS 
        WITH produtos AS (
            SELECT LEVEL AS indice
            FROM DUAL 
            CONNECT BY LEVEL <= p_qtd_linhas
        )
        SELECT 
            ACT_INT_FIELD(p_id_sessao, indice, 'NUIVT') AS nu_ivt,
            ACT_INT_FIELD(p_id_sessao, indice, 'SEQUENCIA') AS sequencia,
            ACT_INT_FIELD(p_id_sessao, indice, 'CODPROD') AS cod_prod,
            ACT_INT_FIELD(p_id_sessao, indice, 'CODEND') AS cod_end
        FROM produtos;
    
    /* Variáveis */
    v_reg_produto        t_reg_produto;
    v_num_tarefa        NUMBER;
    
    v_resposta_itt      VARCHAR2(400);
    v_resposta_uxt      VARCHAR2(400);
    
    v_produtos_abertos  VARCHAR2(32000);
    v_produtos_conf_ok  VARCHAR2(32000);
    v_produtos_add      VARCHAR2(32000);
    
    /* Constantes */
    c_quebra_linha      CONSTANT VARCHAR2(10) := '<br>';
    c_tipo_tarefa      CONSTANT NUMBER := 6;
    c_status_ativo     CONSTANT VARCHAR2(1) := 'A';
    c_flag_nao         CONSTANT VARCHAR2(1) := 'N';
       
       
       
BEGIN

        /* Inicialização das variáveis de mensagem */
        v_produtos_abertos := NULL;
        v_produtos_conf_ok := NULL;
        v_produtos_add     := NULL; 
      
       /* Processamento de cada produto */
        FOR r_produto IN c_produtos LOOP                   -- A variável "I" representa o registro corrente.
          
           -- Obtenção dos campos do registro corrente
           /*FIELD_NUIVT := ACT_INT_FIELD(P_IDSESSAO, I, 'NUIVT');
           FIELD_SEQUENCIA := ACT_INT_FIELD(P_IDSESSAO, I, 'SEQUENCIA');
           FIELD_CODPROD := ACT_INT_FIELD(P_IDSESSAO, I, 'CODPROD');
           FIELD_CODEND := ACT_INT_FIELD(P_IDSESSAO, I, 'CODEND');*/


        /* Verifica se existem tarefas de contagem em aberto */
        IF FN_CONTAGEM_ABERTAS_DCCO(r_produto.nu_ivt, r_produto.cod_prod, r_produto.cod_end) > 0 THEN
            v_produtos_abertos := v_produtos_abertos || 
                                c_quebra_linha || 
                                '<b>Código:</b>' || 
                                r_produto.cod_prod;
                                
        /* Verifica se a conferência do produto está OK */
        ELSIF FN_CONFERENCIA_OK_DCCO(r_produto.nu_ivt, r_produto.cod_prod, r_produto.cod_end) = 1 THEN
            v_produtos_conf_ok := v_produtos_conf_ok || 
                                c_quebra_linha || 
                                '<b>Código:</b>' || 
                                r_produto.cod_prod;
                                
        /* Gera nova tarefa caso não existam pendências */
        ELSE
            /* Gera número da tarefa */
            STP_GERAR_NUTAREFA_DCCO(v_num_tarefa);
            
            /* Insere tarefa de contagem */
            INSERIR_TGWTAR_DCCO(
                p_nutarefa  => v_num_tarefa,
                p_codtarefa => c_tipo_tarefa,
                p_status    => c_status_ativo,
                p_codusu    => p_cod_usuario,
                p_nuivt     => r_produto.nu_ivt,
                p_pendente  => c_flag_nao,
                p_resposta  => v_resposta_itt
            );
            
            /* Insere produto na tarefa de contagem */
            INS_TGWITT_INVT_DCCO(
                p_nutarefa => v_num_tarefa,
                p_codprod  => r_produto.cod_prod,
                p_codend   => r_produto.cod_end,
                p_resposta => v_resposta_itt
            );
            
            /* Define o inventariante responsável */
            DefiniInventariante_DCCO(
                p_nuivt    => r_produto.nu_ivt,
                p_codprod  => r_produto.cod_prod,
                p_nutarefa => v_num_tarefa,
                p_codusu   => p_cod_usuario,
                p_resposta => v_resposta_uxt
            );
            
            /* Registra produtos adicionados */
            v_produtos_add := v_produtos_add || 
                            c_quebra_linha || 
                            c_quebra_linha || 
                            'Código: ' || 
                            r_produto.cod_prod || 
                            ' <b>Nº TAREFA:</b> ' || 
                            v_num_tarefa;
        END IF; 

       END LOOP;


       /* Monta mensagem de retorno */
        p_mensagem := NULL;
    
    /* Adiciona mensagem de tarefas em aberto */
    IF v_produtos_abertos IS NOT NULL THEN
        p_mensagem := 'Os produtos abaixo já possuem tarefas de recontagem em aberto para este inventário:' || 
                     v_produtos_abertos ||
                     c_quebra_linha ||
                     c_quebra_linha ||
                     '<b>Não foram geradas novas tarefas de recontagem para esses itens.</b>';
    END IF;
    
    /* Adiciona mensagem de produtos conferidos */
    IF v_produtos_conf_ok IS NOT NULL THEN
        p_mensagem := p_mensagem || 
                     c_quebra_linha ||
                     c_quebra_linha ||
                     '<b>Produtos com conferência OK</b>:' ||
                     v_produtos_conf_ok;
    END IF;
    
    /* Adiciona mensagem de novas tarefas */
    IF v_produtos_add IS NOT NULL THEN
        p_mensagem := p_mensagem || 
                     c_quebra_linha ||
                     c_quebra_linha ||
                     '<b>Tarefa de recontagem gerada para os produtos abaixo:</b>' ||
                     v_produtos_add;
    END IF;

END;

/