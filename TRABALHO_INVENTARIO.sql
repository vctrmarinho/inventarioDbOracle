/*
	O script abaixo tem por objetivo realizar um inventario dos itens do usuarios em uma base de dados Oracle.
	Na prática, é uma tentativa de traduzir o script da função getddl nativa do Oracle.
*/

CREATE OR REPLACE PROCEDURE PR_INVENTARIO 
AS
    V_CODIGO VARCHAR2(10000) := '';    
    V_TP VARCHAR2(5000) := '';
    v_TAMANHO_TABELA NUMBER := 0; 
    
    CURSOR CR_USR_OBJS IS 
        SELECT OBJECT_NAME, OBJECT_TYPE, CREATED FROM USER_OBJECTS
        ORDER BY OBJECT_NAME;
    
    CURSOR CR_DADOS_TAB IS 
        SELECT UT.TABLE_NAME, UT.NUM_ROWS, US.BYTES FROM USER_TABLES UT
        INNER JOIN USER_SEGMENTS US 
        ON UT.TABLE_NAME = US.SEGMENT_NAME;

    CURSOR CR_DADOS_COLUNA IS 
        SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, DATA_LENGTH FROM USER_TAB_COLUMNS;
        
    CURSOR CR_CODES IS
        SELECT NAME, TEXT FROM USER_SOURCE;

    CURSOR CR_DADOS_SEQ IS
        SELECT SEQUENCE_NAME, MIN_VALUE, INCREMENT_BY FROM USER_SEQUENCES;
        
    CURSOR CR_DADOS_INDEX IS 
        SELECT INDEX_NAME, TABLE_NAME FROM USER_INDEXES;
    
BEGIN
    
    FOR OBJ IN CR_USR_OBJS LOOP
        V_TP := '';
        V_CODIGO := '';
        IF OBJ.OBJECT_TYPE = 'TABLE'
            THEN 
                V_CODIGO := 'CREATE TABLE ' || OBJ.OBJECT_NAME || '( ' || CHR(10);
                
                FOR X IN (SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, DATA_LENGTH FROM USER_TAB_COLUMNS WHERE TABLE_NAME = OBJ.OBJECT_NAME) LOOP
                
                    IF X.DATA_TYPE = 'VARCHAR2' 
                        THEN
                            V_TP := V_TP || X.COLUMN_NAME || ' ' || X.DATA_TYPE || '(' || X.DATA_LENGTH || '), ';
                    ELSE
                        V_TP := V_TP || X.COLUMN_NAME || ' ' || X.DATA_TYPE || ', ';                       
                    END IF;                     
                END LOOP;                              
            V_TP := SUBSTR(V_TP, 1, LENGTH(V_TP) - 2);
            V_CODIGO := V_CODIGO || ' ' || V_TP || ')';
            
        ELSIF OBJ.OBJECT_TYPE = 'INDEX'
            THEN
                FOR I IN CR_DADOS_INDEX LOOP 
                    IF I.INDEX_NAME = OBJ.OBJECT_NAME 
                        THEN
                        V_CODIGO := 'CREATE INDEX ' || I.INDEX_NAME || ' ON ' || I.TABLE_NAME || ';';
                    END IF;
                END LOOP;    
                
        ELSIF OBJ.OBJECT_TYPE = 'SEQUENCE'
            THEN
                FOR S IN CR_DADOS_SEQ LOOP 
                    IF S.SEQUENCE_NAME = OBJ.OBJECT_NAME 
                        THEN
                        V_CODIGO := 'CREATE SEQUENCE ' || S.SEQUENCE_NAME || ' START WITH '  || S.MIN_VALUE || ' INCREMENT BY ' || S.INCREMENT_BY || ';';
                    END IF;
                END LOOP;    
        
        ELSE 
            V_CODIGO := 'CREATE OR REPLACE ';
            FOR L IN CR_CODES LOOP
                IF L.NAME = OBJ.OBJECT_NAME
                    THEN
                    V_CODIGO := V_CODIGO || L.TEXT || CHR(10);
                END IF;
            END LOOP;
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('OBJETO: ' || OBJ.OBJECT_NAME || '  ' || 'DATA DE CRIACAO: ' || OBJ.CREATED || '   ' || 'TIPO DE OBJETO: ' || OBJ.OBJECT_TYPE);
       
        IF OBJ.OBJECT_TYPE = 'TABLE'
            THEN
                FOR T IN CR_DADOS_TAB LOOP
                    IF T.TABLE_NAME = OBJ.OBJECT_NAME
                        THEN
                        V_TAMANHO_TABELA := T.BYTES / 1024 / 1024;
                            DBMS_OUTPUT.PUT_LINE('REGISTROS: ' || T.NUM_ROWS);
                            IF V_TAMANHO_TABELA < 1
                                THEN
                                DBMS_OUTPUT.PUT_LINE('TAMANHO: ' || '0' || V_TAMANHO_TABELA || ' MB'); 
                            ELSE 
                                DBMS_OUTPUT.PUT_LINE('TAMANHO: ' || V_TAMANHO_TABELA || ' MB');
                            END IF;
                    END IF;
                END LOOP;        
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('DDL:' || CHR(10) || V_CODIGO);
        DBMS_OUTPUT.PUT_LINE('');
            
    END LOOP;
END;
/