CREATE OR REPLACE PROCEDURE SANKHYA.STP_ATUALIZA_VOL_ETQ_DCCO(P_NUNOTA NUMBER) AS

    -- Conta a quantidade de etiquetas na TGWREV para a NUNOTA informada.
    V_QTDVOL NUMBER;
    -- Variáveis para checar se a TOP utiliza WMS
    v_codtipoper TGFCAB.CODTIPOPER%TYPE;
    v_dhtipoper  TGFCAB.DHTIPOPER%TYPE;
    v_iswms      VARCHAR2(3);

BEGIN
    /*
    ---------------------------------------------------------------------------
    PROCEDURE: STP_ATUALIZA_VOL_ETQ_DCCO
    AUTOR ORIGINAL: Guilherme Hahn (implantação do WMS)
    AUTOR ATUAL: Danilo Fernando
    DATA DA ALTERAÇÃO: 13/03/2025 09:51
    ---------------------------------------------------------------------------
    DESCRIÇÃO:
        - Esta procedure foi baseada na antiga STP_GRAVAVOLPEDWMS_DCCO.
        - O objetivo é calcular automaticamente a quantidade de etiquetas (volumes)
          associadas a uma NUNOTA na tabela TGWREV.
        - Essa nova versão é utilizada em relatórios formatados para impressão de
          Etiqueta de Volumes.
    
    MELHORIAS EM RELAÇÃO À VERSÃO ANTERIOR:
        - Removido o parâmetro P_QTDVOL. Agora, a contagem de volumes é automática.
        - A quantidade de volumes (QTDVOL) é baseada no número de registros em TGWREV.
        - Se não houver etiquetas registradas, assume-se pelo menos 1 volume.
        - Removido o COMMIT interno, pois a transação deve ser controlada externamente.
        
     ---------------------------------------------------------------------------
    AJUSTE:
        - Agora, verificamos se a TOP (CODTIPOPER/DHTIPOPER) está habilitada para WMS
          via PKG_WMS_DCCO.prc_check_top_wms. Se estiver (p_iswms = 'SIM'), executamos a
          lógica de atualização de volumes; caso contrário, não fazemos nada.
    ---------------------------------------------------------------------------    

    EXEMPLO DA PROCEDURE ANTERIOR (ANTES DOS AJUSTES):
    
        CREATE OR REPLACE PROCEDURE SANKHYA.STP_GRAVAVOLPEDWMS_DCCO(P_NUNOTA NUMBER, P_QTDVOL NUMBER) AS
        BEGIN
            UPDATE TGFCAB CAB
               SET CAB.QTDVOL = P_QTDVOL,
                   CAB.AD_QTDVOL = P_QTDVOL
             WHERE CAB.NUNOTA = P_NUNOTA
               AND NVL(CAB.QTDVOL,0) <> P_QTDVOL;
            
            COMMIT;
        END;
    
    ---------------------------------------------------------------------------
    */


    

    ---------------------------------------------------------------------------
    -- 1) Verificar se a TOP utiliza WMS
    ---------------------------------------------------------------------------
    PKG_WMS_DCCO.prc_check_top_wms(
        p_nunota     => P_NUNOTA,
        p_codtipoper => v_codtipoper,
        p_dhtipoper  => v_dhtipoper,
        p_iswms      => v_iswms
    ); 
    
     PKG_WMS_DCCO.STP_CAL_VOLUNOTA_DCCO(v_nunota1, V_QTDVOL);
    
    
    /*SELECT NVL(COUNT(*), 1) INTO V_QTDVOL
    FROM TGWREV
    WHERE NUNOTA = P_NUNOTA;*/

    ---------------------------------------------------------------------------
    -- 2) Se a TOP estiver habilitada para WMS, calcular e atualizar volumes
    ---------------------------------------------------------------------------
    IF v_iswms = 'SIM' THEN
    
        -- Conta a quantidade de etiquetas para a NUNOTA (Todas as separações do pedido)
        
        SELECT NVL(COUNT(*), 1)
          INTO v_qtdvol
          FROM TGWREV
         WHERE NUNOTA = P_NUNOTA;

        -- Atualiza a CAB
        UPDATE TGFCAB CAB
           SET CAB.QTDVOL    = v_qtdvol,
               CAB.AD_QTDVOL = v_qtdvol
         WHERE CAB.NUNOTA = P_NUNOTA
           AND NVL(CAB.QTDVOL, 0) <> v_qtdvol;
           
        COMMIT;   
           
        
    
    END IF;
    
    
END;
/