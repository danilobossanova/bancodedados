CREATE OR REPLACE FUNCTION SANKHYA.FC_ABREVIAR_NOME_DCCO (
    P_NOME IN VARCHAR2,
    P_TAMANHO IN NUMBER
)
RETURN VARCHAR2 
IS
    C_NM_USUARIO VARCHAR2(200) := INITCAP(LTRIM(RTRIM(P_NOME)));
    C_PRIMEIRO_NOME VARCHAR2(200) := NULL;
    C_ULTIMO_NOME VARCHAR2(200) := NULL;
    C_NOME_DO_MEIO VARCHAR2(200) := NULL;
    C_ABREVIACAO VARCHAR2(200) := NULL;
    N_INICIO_DO_NOME_DO_MEIO NUMBER := NULL;
    N_FIM_DO_NOME_DO_MEIO NUMBER := NULL;

    /****************************************************************************
    @Author: Danilo Fernando <danilo.fernando@grupocopar.com.br>
    @Data: 25/09/2021 11:23
    
    Função que abrevia o nome. Usa como referencia a quantidade de caractere
    informado no 2º parametro dessa função.
    Se mesmo após apreviação estourar a quantidade de caracteres, será 
    suprimido a abreviação da equerda.
    
    Função é usada para gerar o nome de apresentação da Assinatura de e-mail
    
    ****************************************************************************/


BEGIN
    IF LENGTH(C_NM_USUARIO) > P_TAMANHO THEN
        C_NM_USUARIO := REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C_NM_USUARIO,'.',''),' ','#'),'#DA#','#'),'#DE#','#'),'#DI#','#'),'#DO#','#'),'#DU#','#'),'#DOS#','#');
    END IF;

    IF LENGTH(C_NM_USUARIO) > P_TAMANHO THEN
        -- Encontrar o primeiro nome
        FOR I_CONTADOR IN 1..LENGTH(C_NM_USUARIO) LOOP
            IF SUBSTR(C_NM_USUARIO, I_CONTADOR, 1) = '#' THEN
                C_PRIMEIRO_NOME := SUBSTR(C_NM_USUARIO, 1, (I_CONTADOR - 1));
                N_INICIO_DO_NOME_DO_MEIO := I_CONTADOR + 1;
                EXIT;
            END IF;
        END LOOP;

        IF INSTR(C_NM_USUARIO, '#') = 0 THEN
            C_PRIMEIRO_NOME := C_NM_USUARIO;
        ELSE
            -- Encontrar o último nome
            FOR I_CONTADOR IN REVERSE 1..LENGTH(C_NM_USUARIO) LOOP
                IF SUBSTR(C_NM_USUARIO, I_CONTADOR, 1) = '#' THEN
                    C_ULTIMO_NOME := SUBSTR(C_NM_USUARIO, I_CONTADOR + 1, LENGTH(C_NM_USUARIO) - I_CONTADOR);
                    N_FIM_DO_NOME_DO_MEIO := I_CONTADOR;
                    IF C_ULTIMO_NOME IN ('JUNIOR', 'JÚNIOR') THEN
                        C_ULTIMO_NOME := 'Jr';
                    ELSIF C_ULTIMO_NOME IN ('FILHO', 'FILHA') THEN
                        C_ULTIMO_NOME := 'Fh';
                    ELSIF C_ULTIMO_NOME IN ('NETO', 'NETA') THEN
                        C_ULTIMO_NOME := 'Nt';
                    ELSIF C_ULTIMO_NOME IN ('SOBRINHO', 'SOBRINHA') THEN
                        C_ULTIMO_NOME := 'Sb';
                    ELSE
                        C_ULTIMO_NOME := C_ULTIMO_NOME;
                    END IF;
                    EXIT;
                END IF;
            END LOOP;

            C_NOME_DO_MEIO := LTRIM(RTRIM(SUBSTR(C_NM_USUARIO, N_INICIO_DO_NOME_DO_MEIO - 1, N_FIM_DO_NOME_DO_MEIO - N_INICIO_DO_NOME_DO_MEIO + 2)));
            C_NM_USUARIO := LTRIM(RTRIM(C_PRIMEIRO_NOME)) || C_NOME_DO_MEIO || LTRIM(RTRIM(C_ULTIMO_NOME));

            -- Abreviação do nome do meio
            WHILE (NVL(LENGTH(C_PRIMEIRO_NOME),0) + NVL(LENGTH(C_ABREVIACAO),0) + NVL(LENGTH(C_NOME_DO_MEIO),0) + NVL(LENGTH(C_ULTIMO_NOME),0)) > P_TAMANHO LOOP
                IF C_NOME_DO_MEIO <> '#' THEN
                    FOR I_CONTADOR IN 1..LENGTH(C_NOME_DO_MEIO) LOOP
                        IF SUBSTR(C_NOME_DO_MEIO, I_CONTADOR + 1, 1) = '#' THEN
                            C_ABREVIACAO := C_ABREVIACAO || SUBSTR(C_NOME_DO_MEIO, 1, 2);
                            C_NOME_DO_MEIO := SUBSTR(C_NOME_DO_MEIO, I_CONTADOR + 1, LENGTH(C_NOME_DO_MEIO) - I_CONTADOR);
                            EXIT;
                        END IF;
                    END LOOP;
                ELSE
                    EXIT;
                END IF;
            END LOOP;
        END IF;

        -- Se o tamanho ainda for maior, suprimir os nomes da direita para a esquerda
        WHILE (P_TAMANHO - LENGTH(C_PRIMEIRO_NOME) - LENGTH(C_ULTIMO_NOME)) < LENGTH(C_ABREVIACAO) + 1 LOOP
            C_ABREVIACAO := SUBSTR(C_ABREVIACAO, 3, LENGTH(C_ABREVIACAO) - 2);
        END LOOP;

        -- Se o tamanho ainda for maior, enviar mensagem de erro
        IF (NVL(LENGTH(C_PRIMEIRO_NOME),0) + NVL(LENGTH(C_ABREVIACAO),0) + NVL(LENGTH(C_NOME_DO_MEIO),0) + NVL(LENGTH(C_ULTIMO_NOME),0)) > P_TAMANHO THEN
            C_NM_USUARIO := C_PRIMEIRO_NOME; -- 'NÃO FOI POSSÍVEL ABREVIAR';
        ELSE
            C_NM_USUARIO := LTRIM(RTRIM(C_PRIMEIRO_NOME)) || C_ABREVIACAO || C_NOME_DO_MEIO || LTRIM(RTRIM(C_ULTIMO_NOME));
        END IF;
    END IF;
    
    RETURN(REPLACE(C_NM_USUARIO, '#', ' '));
END;
