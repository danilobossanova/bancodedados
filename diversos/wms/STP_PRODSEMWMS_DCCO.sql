CREATE OR REPLACE PROCEDURE STP_PRODSEMWMS_DCCO(
 -- p_nuprodsemwms IN NUMBER,
  p_nuivt        IN NUMBER,
  p_codemp       IN NUMBER,
  p_codprod      IN NUMBER,
  p_codend       IN NUMBER,
  p_dhcontagem   IN DATE,
  p_codvol       IN VARCHAR2,
  p_qtdestcontada FLOAT,
  p_qtdestlogica  FLOAT,
  p_codusu       IN NUMBER,
  p_ativa        IN VARCHAR2,
  p_contagem     IN NUMBER,
  p_sequencia    IN NUMBER,
  p_tipo         IN VARCHAR2
)
IS


    l_P_NUPRODSEMWMS NUMBER;

BEGIN
  /****************************************************************************
  * Author: Danilo Fernando <danilo.bossanova@hotmail.com>
  * Data: 14/03/2024 17:19
  * Ao som de: Dan Ferreira - 50 tons
  * Description: Realiza o insert na tabela AD_PRODSEMWMS
  * Essa tabela registra produtos que não são controlados pelo WMS e
  * que foram contados em um determinado inventário.
  *****************************************************************************/
  

    SELECT NVL(MAX(NUPRODSEMWMS), 0) + 1 INTO l_P_NUPRODSEMWMS FROM AD_PRODSEMWMS; 


  INSERT INTO SANKHYA.AD_PRODSEMWMS (
    NUPRODSEMWMS,
    NUIVT,
    CODEMP,
    CODPROD,
    CODEND,
    DHCONTAGEM,
    CODVOL,
    QTDESTCONTADA,
    QTDESTLOGICA,
    CODUSU,
    ATIVA,
    CONTAGEM,
    SEQUENCIA,
    TIPO
  )
  VALUES (
    l_P_NUPRODSEMWMS,
    p_nuivt,
    p_codemp,
    p_codprod,
    p_codend,
    p_dhcontagem,
    p_codvol,
    p_qtdestcontada,
    p_qtdestlogica,
    p_codusu,
    p_ativa,
    p_contagem,
    p_sequencia,
    p_tipo
  );

  COMMIT; 

EXCEPTION
  WHEN OTHERS THEN

    DBMS_OUTPUT.PUT_LINE('Erro ao inserir dados: ' || SQLERRM);
    ROLLBACK; -- Reverte a transação em caso de erro para evitar inconsistências nos dados

END;
/
