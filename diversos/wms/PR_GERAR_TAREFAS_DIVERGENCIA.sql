CREATE OR REPLACE PROCEDURE PR_GERAR_TAREFAS_DIVERGENCIA (
    P_NUIVT IN NUMBER
) AS
    V_NOVA_TAREFA NUMBER;
    V_RESPOSTA VARCHAR2(4000);
    V_RESPOSTA_ITT VARCHAR2(4000);
    
    /*************************************************************************
    * @author: Danilo Bossanova <danilo.bossanova@hotmail.com>
    * @since : 07/11/2024 11:16
    * @description: Gera tarefas de contagem para produtos que estão em divergencia.
    *  Essa divergencia é verificada apenas após a primeira contagem. Nao gera tarefa
    *  para itens que estão com tarefas de contagem abertas. 
    * @parametro: p_NUIVT - Numero do Inventario. 
    **************************************************************************/
    
    
BEGIN
    -- Para cada prédio com divergência
    FOR r_predio IN (
        WITH DadosAgrupados AS (
            SELECT 
                END_RUA_PREDIO,
                MIN(END_RUA) AS END_RUA,
                MIN(END_PREDIO) AS END_PREDIO,
                MIN(NUIVT) AS NUIVT,
                MIN(CODEMP) AS CODEMP,
                COUNT(*) AS QTD_PRODUTOS
            FROM VW_WMSINVT_DIVERGENCIAS
            WHERE NUIVT = P_NUIVT
            GROUP BY END_RUA_PREDIO
        )
        SELECT * FROM DadosAgrupados
        ORDER BY END_RUA_PREDIO
    ) LOOP
        -- 1. Gerar número da nova tarefa
        STP_GERAR_NUTAREFA_DCCO(V_NOVA_TAREFA);
        
        -- 2. Inserir a tarefa
        INSERIR_TGWTAR_DCCO(
            V_NOVA_TAREFA,  -- Número da tarefa gerada
            6,              -- CODTTAR fixo em 6 Codito da Tarefa de Contagem para Inventario
            'A',            -- STATUS inicial 'A' - Aberto
            NULL, NULL, NULL, NULL, NULL,
            0,              
            r_predio.NUIVT, -- NUIVT do INVENTARIO
            NULL, NULL,
            'N',            
            0,              -- CODUSU do SUP que gerou a tarefa
            V_RESPOSTA      -- Variável para resposta
        );
        
        -- 3. Inserir os itens da tarefa para todos os produtos do prédio que estão com tarefas divergentes
        FOR r_produto IN (
            SELECT 
                CODPROD,
                CODEND
            FROM VW_WMSINVT_DIVERGENCIAS
            WHERE NUIVT = P_NUIVT
            AND END_RUA_PREDIO = r_predio.END_RUA_PREDIO
        ) LOOP
            -- Inserir item
            INS_TGWITT_INVT_DCCO(
                V_NOVA_TAREFA,    -- Número da tarefa
                r_produto.CODPROD,-- Código do produto
                r_produto.CODEND, -- Código do endereço
                V_RESPOSTA_ITT    -- Variável para resposta
            );
        END LOOP;
        
        COMMIT;
        
    END LOOP;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Erro: ' || SQLERRM);
        RAISE;
END;
/