------------------------------------------------
-- CS1555/2055 Project 2 Operations
-- Procedures that implement all 15 requested
-- data operations.
--
-- Authors: Hala Nubani, Ethan Wells, Ben Kiddie
------------------------------------------------

CREATE OR REPLACE PROCEDURE addForest(n varchar(30), a integer, al real, xmin real,
                                        xmax real, ymin real, ymax real) AS
    $$
    DECLARE
        no integer;
    BEGIN
        -- Determine current max forest number
        no := (SELECT COALESCE(MAX(forest_no), 0) FROM FOREST) + 1;
        INSERT INTO FOREST
        VALUES (no, n, a, al, xmin, xmax, ymin, ymax);
    END;
    $$ LANGUAGE plpgsql;

CALL addForest('Test 2', 513655, 0, 0, 20, 0, 20);