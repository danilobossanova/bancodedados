   /*
   Objetivo: SEQUENCIA DE PREENCHIMENTO DAS TABELAS PELO WMS QUANDO DO RECEBIMENTO
   
   */

/* PROCESSO COMPLETO DE RECEBIMENTO DENTRO DO BANCO */

SELECT * FROM TGWSEP WHERE NUSEPARACAO =  
/
SELECT * FROM TGWCON WHERE NUCONFERENCIA = 29796
/
SELECT * FROM TGWCOI WHERE NUCONFERENCIA = 29796
/
SELECT * FROM TGWTAR WHERE NUTAREFA = 35351
/
SELECT * FROM TGWITT WHERE NUTAREFA = 35351
/
SELECT * FROM TSIUSU WHERE CODUSU = 1083 -- 
/

/* EDIT DAS CONSULTAS */
EDIT TGWREC WHERE NURECEBIMENTO = 4418 --
/
EDIT TGWCON WHERE NUCONFERENCIA = 29796
/
EDIT TGWCOI WHERE NUCONFERENCIA = 29796
/
EDIT TGWTAR WHERE NUTAREFA = 34856
/
EDIT TGWITT WHERE NUTAREFA = 34856
/
EDIT TSIUSU WHERE CODUSU = 1083 -- ANTONIOO