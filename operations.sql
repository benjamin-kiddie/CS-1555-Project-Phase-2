------------------------------------------------
-- CS1555/2055 Project 2 Operations
-- Procedures that implement all 15 requested
-- data operations.
--
-- Authors: Hala Nubani, Ethan Wells, Ben Kiddie
------------------------------------------------

SET SCHEMA 'arbor_db';

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

CREATE OR REPLACE PROCEDURE addTreeSpecies(gen varchar(30), epi varchar(30), temp real, height real, raunkiaer raunkiaer_life_form) AS
    $$
    BEGIN
        INSERT INTO TREE_SPECIES
        VALUES (gen, epi, temp, height, raunkiaer);
    END;
    $$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE addSpeciesToForest(no integer, gen varchar(30), epi varchar(30)) AS
    $$
    BEGIN
        INSERT INTO FOUND_IN
        VALUES (no, gen, epi);
    END;
    $$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE newWorker(ssn char(9), f varchar(30), l varchar(30), mi char(1), r rank, abb char(2)) AS
    $$
    BEGIN
        INSERT INTO WORKER
        VALUES (ssn, f, l, mi, r);
        INSERT INTO EMPLOYED
        VALUES (abb, ssn);
    END;
    $$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE employWorkerToState(ssn char(9), abb char(2)) AS
    $$
    BEGIN
        INSERT INTO EMPLOYED
        VALUES (abb, ssn);
    END;
    $$ LANGUAGE plpgsql;