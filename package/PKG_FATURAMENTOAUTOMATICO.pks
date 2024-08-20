/*******************************************************************************
* @author: Danilo Fernando <danilo.bossanova@hotmail.com>
* @since: 20/08/2024 11:13
* @description: Package com funcionalidades ligadas ao faturamento automatico
********************************************************************************/
CREATE OR REPLACE PACKAGE SANKHYA.PKG_FATURAMENTOAUTOMATICO AS

    FUNCTION INSERE_LOGFATAUTO(p_nunota   IN NUMBER,
                               p_numnota  IN NUMBER,
                               p_log      IN CLOB,
                               p_dhalter  IN DATE) RETURN BOOLEAN;
                               
                               
                               
                                 
END PKG_FATURAMENTOAUTOMATICO;
/





CREATE OR REPLACE PACKAGE BODY SANKHYA.PKG_FATURAMENTOAUTOMATICO AS

    /* Insere registro no log de faturamento */
    FUNCTION INSERE_LOGFATAUTO(p_nunota   IN NUMBER,
                               p_numnota  IN NUMBER,
                               p_log      IN CLOB,
                               p_dhalter  IN DATE) RETURN BOOLEAN IS
    BEGIN
    
        INSERT INTO SANKHYA.TGWLOGFATAUTO (NUNOTA, NUMNOTA, LOG, DHALTER)
        VALUES (p_nunota, p_numnota, p_log, p_dhalter);
        
        COMMIT;
        
        -- Retornar TRUE indicando sucesso
        RETURN TRUE;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RETURN FALSE; -- Retornar FALSE indicando falha
    
    END INSERE_LOGFATAUTO;
    
    /**/
    
    

END PKG_FATURAMENTOAUTOMATICO;
/
