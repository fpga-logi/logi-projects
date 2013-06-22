--***************************************************************************** 
-- 
-- Micron Semiconductor Products, Inc. 
-- 
-- Copyright 1997, Micron Semiconductor Products, Inc. 
-- All rights reserved. 
-- 
--***************************************************************************** 
 
LIBRARY work; 
LIBRARY ieee; 
USE ieee.std_logic_1164.ALL; 
 
PACKAGE mti_pkg IS 
 
    FUNCTION  TO_INTEGER  (input : STD_LOGIC) RETURN INTEGER; 
    FUNCTION  TO_INTEGER  (input : BIT_VECTOR) RETURN INTEGER; 
    FUNCTION  TO_INTEGER (input : STD_LOGIC_VECTOR) RETURN INTEGER; 
    PROCEDURE TO_BITVECTOR  (VARIABLE input : IN INTEGER; VARIABLE output : OUT BIT_VECTOR); 
 
END mti_pkg; 
 
PACKAGE BODY mti_pkg IS 
 
    -- Convert BIT to INTEGER 
    FUNCTION  TO_INTEGER (input : STD_LOGIC) RETURN INTEGER IS 
    VARIABLE result : INTEGER := 0; 
    VARIABLE weight : INTEGER := 1; 
    BEGIN 
        IF input = '1' THEN 
            result := weight; 
        ELSE 
            result := 0;                                            -- if unknowns, default to logic 0 
        END IF; 
        RETURN result; 
    END TO_INTEGER; 
 
    -- Convert BIT_VECTOR to INTEGER 
    FUNCTION  TO_INTEGER (input : BIT_VECTOR) RETURN INTEGER IS 
    VARIABLE result : INTEGER := 0; 
    VARIABLE weight : INTEGER := 1; 
    BEGIN 
        FOR i IN input'LOW TO input'HIGH LOOP 
            IF input(i) = '1' THEN 
                result := result + weight; 
            ELSE 
                result := result + 0;                               -- if unknowns, default to logic 0 
            END IF; 
            weight := weight * 2; 
        END LOOP; 
        RETURN result; 
    END TO_INTEGER; 
 
    -- Convert STD_LOGIC_VECTOR to INTEGER 
    FUNCTION  TO_INTEGER (input : STD_LOGIC_VECTOR) RETURN INTEGER IS 
    VARIABLE result : INTEGER := 0; 
    VARIABLE weight : INTEGER := 1; 
    BEGIN 
        FOR i IN input'LOW TO input'HIGH LOOP 
            IF input(i) = '1' THEN 
                result := result + weight; 
            ELSE 
                result := result + 0;                               -- if unknowns, default to logic 0 
            END IF; 
            weight := weight * 2; 
        END LOOP; 
        RETURN result; 
    END TO_INTEGER; 
 
    -- Conver integer to bit_vector 
    PROCEDURE  TO_BITVECTOR (VARIABLE input : IN INTEGER; VARIABLE output : OUT BIT_VECTOR) IS 
    VARIABLE work,offset,outputlen,j : INTEGER := 0; 
    BEGIN 
        --length of vector 
        IF output'LENGTH > 32 THEN 
            outputlen := 32; 
            offset := output'LENGTH - 32; 
            IF input >= 0 THEN 
                FOR i IN offset-1 DOWNTO 0 LOOP 
                    output(output'HIGH - i) := '0'; 
                END LOOP; 
            ELSE 
                FOR i IN offset-1 DOWNTO 0 LOOP 
                    output(output'HIGH - i) := '1'; 
                END LOOP; 
            END IF; 
        ELSE 
            outputlen := output'LENGTH; 
        END IF; 
        --positive value 
        IF (input >= 0) THEN 
            work := input; 
            j := outputlen - 1; 
            FOR i IN 1 to 32 LOOP 
                IF j >= 0 then 
                    IF (work MOD 2) = 0 THEN  
                        output(output'HIGH-j-offset) := '0'; 
                    ELSE 
                        output(output'HIGH-j-offset) := '1'; 
                    END IF; 
                END IF; 
                work := work / 2; 
                j := j - 1; 
            END LOOP; 
            IF outputlen = 32 THEN 
                output(output'HIGH) := '0'; 
            END IF; 
        --negative value 
        ELSE 
            work := (-input) - 1; 
            j := outputlen - 1; 
            FOR i IN 1 TO 32 LOOP 
                IF j>= 0 THEN 
                    IF (work MOD 2) = 0 THEN  
                        output(output'HIGH-j-offset) := '1'; 
                    ELSE 
                        output(output'HIGH-j-offset) := '0'; 
                    END IF; 
                END IF;     
                work := work / 2; 
                j := j - 1; 
            END LOOP; 
            IF outputlen = 32 THEN 
                output(output'HIGH) := '1'; 
            END IF; 
        END IF; 
    END TO_BITVECTOR; 
 
END mti_pkg;    

 
