CREATE OR REPLACE FUNCTION FC_VALOR_OPCAO(P_NOMETAB VARCHAR2, P_NOMECAMPO VARCHAR2, P_VALOR VARCHAR2) RETURN VARCHAR2
IS
  P_OPCAO VARCHAR2(32767);
  P_NUCAMPO NUMBER;
BEGIN
  SELECT NUCAMPO INTO P_NUCAMPO
  FROM TDDCAM
  WHERE NOMETAB = P_NOMETAB AND NOMECAMPO = P_NOMECAMPO;

  SELECT OPCAO INTO P_OPCAO
  FROM TDDOPC
  WHERE NUCAMPO = P_NUCAMPO AND VALOR = NVL(P_VALOR, 'null');

  RETURN P_OPCAO;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN NULL;
  WHEN OTHERS THEN
    RETURN P_VALOR;
END;
