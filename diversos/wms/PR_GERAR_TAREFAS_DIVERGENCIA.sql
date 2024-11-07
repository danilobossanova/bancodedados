CREATE OR REPLACE PROCEDURE PR_GERAR_TAREFAS_DIVERGENCIA (
    P_NUIVT IN NUMBER
) AS
    V_NOVA_TAREFA NUMBER;
    V_RESPOSTA VARCHAR2(4000);
    V_RESPOSTA_ITT VARCHAR2(4000);
    
    /*************************************************************************
    * @author: Danilo Bossanova <danilo.bossanova@hotmail.com>
    * @since : 07/11/2024 11:16
    * @description: Gera tarefas de contagem para produtos que est�o em divergencia.
    *  Essa divergencia � verificada apenas ap�s a primeira contagem. Nao gera tarefa
    *  para itens que est�o com tarefas de contagem abertas. 
    * @parametro: p_NUIVT - Numero do Inventario. 
    **************************************************************************/
    
BEGIN
    -- Para cada pr�dio com diverg�ncia
    FOR r_predio IN (
        SELECT 
            END_RUA_PREDIO,
            COUNT(*) AS QTD_PRODUTOS
        FROM VW_WMSINVT_DIVERGENCIAS div
        WHERE div.NUIVT = P_NUIVT
        -- Verifica se n�o existem tarefas abertas para os produtos deste pr�dio
        AND NOT EXISTS (
            SELECT 1 
            FROM TGWTAR tar
            JOIN TGWITT itt ON tar.NUTAREFA = itt.NUTAREFA
            WHERE tar.CODTAREFA = 6
            AND tar.NUIVT = div.NUIVT
            AND tar.SITUACAO = 'A'
            AND itt.CODPROD = div.CODPROD
            AND itt.CODENDORIGEM = div.CODEND
        )
        GROUP BY END_RUA_PREDIO
        ORDER BY END_RUA_PREDIO
    ) LOOP
        -- 1. Gerar n�mero da nova tarefa
        STP_GERAR_NUTAREFA_DCCO(V_NOVA_TAREFA);
        
        -- 2. Inserir a tarefa
        INSERIR_TGWTAR_DCCO(
            V_NOVA_TAREFA,  -- N�mero da tarefa gerada
            6,              -- CODTAREFA fixo em 6 Codigo da Tarefa de Contagem para Inventario
            'A',            -- SITUACAO inicial 'A' - Aberto
            NULL, NULL, NULL, NULL, NULL,
            0,              
            P_NUIVT,        -- NUIVT do INVENTARIO
            NULL, NULL,
            'N',            
            0,              -- CODUSU do SUP que gerou a tarefa
            V_RESPOSTA      -- Vari�vel para resposta
        );
        
        -- 3. Inserir os itens da tarefa para todos os produtos do pr�dio
        FOR r_produto IN (
            SELECT 
                div.CODPROD,
                div.CODEND
            FROM VW_WMSINVT_DIVERGENCIAS div
            WHERE div.NUIVT = P_NUIVT
            AND div.END_RUA_PREDIO = r_predio.END_RUA_PREDIO
            -- N�o possui tarefa em aberto
            AND NOT EXISTS (
                SELECT 1 
                FROM TGWTAR tar
                JOIN TGWITT itt ON tar.NUTAREFA = itt.NUTAREFA
                WHERE tar.CODTAREFA = 6
                AND tar.NUIVT = div.NUIVT
                AND tar.SITUACAO = 'A'
                AND itt.CODPROD = div.CODPROD
                AND itt.CODENDORIGEM = div.CODEND
            )
        ) LOOP
            -- Inserir item
            INS_TGWITT_INVT_DCCO(
                V_NOVA_TAREFA,    -- N�mero da tarefa
                r_produto.CODPROD,-- C�digo do produto
                r_produto.CODEND, -- C�digo do endere�o
                V_RESPOSTA_ITT    -- Vari�vel para resposta
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