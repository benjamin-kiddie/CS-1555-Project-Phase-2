------------------------------------------------
-- CS1555/2055 Project 2 Operations
-- Procedures that implement all 15 requested
-- data operations.
--
-- Authors: Hala Nubani, Ethan Wells, Ben Kiddie
------------------------------------------------

SET SCHEMA 'arbor_db';

-- Given a name, area, acid_level, and MBR bounds,
-- add an entry to the forest table.
CREATE OR REPLACE PROCEDURE addForest(n varchar(30), a integer, al real, xmin real,
                                        xmax real, ymin real, ymax real) AS
    $$
    DECLARE
        no integer;
    BEGIN
        -- Create new forest_no.
        SELECT COALESCE(MAX(forest_no), 0) + 1 INTO no FROM FOREST;
        -- Insert new tuple.
        INSERT INTO FOREST
        VALUES (no, n, a, al, xmin, xmax, ymin, ymax);
    END;
    $$ LANGUAGE plpgsql;

-- Given a genus, epithet, temperature, height, and life form,
-- add a new entry to the species table.
CREATE OR REPLACE PROCEDURE addTreeSpecies(gen varchar(30), epi varchar(30), temp real, height real, raunkiaer raunkiaer_life_form) AS
    $$
    BEGIN
        INSERT INTO TREE_SPECIES
        VALUES (gen, epi, temp, height, raunkiaer);
    END;
    $$ LANGUAGE plpgsql;

-- Given a forest_no, genus, and epithet, add amn entry to the
-- found in table.
CREATE OR REPLACE PROCEDURE addSpeciesToForest(no integer, gen varchar(30), epi varchar(30)) AS
    $$
    BEGIN
        INSERT INTO FOUND_IN
        VALUES (no, gen, epi);
    END;
    $$ LANGUAGE plpgsql;

-- Given an ssn, first name, last name, middle initial,
-- rank, and abbreviation, add an entry to the worker table.
CREATE OR REPLACE PROCEDURE newWorker(n char(9), f varchar(30), l varchar(30), mi char(1), r rank, abb char(2)) AS
    $$
    BEGIN
        INSERT INTO WORKER
        VALUES (n, f, l, mi, r);
        INSERT INTO EMPLOYED
        VALUES (abb, n);
    END;
    $$ LANGUAGE plpgsql;

-- Given an ssn and abbreviation, add an entry to
-- the employed table.
CREATE OR REPLACE PROCEDURE employWorkerToState(ssn char(9), abb char(2)) AS
    $$
    BEGIN
        INSERT INTO EMPLOYED
        VALUES (abb, ssn);
    END;
    $$ LANGUAGE plpgsql;

-- Given energy, x, y, and maintainer_id
-- add new sensor into sensor table
CREATE OR REPLACE PROCEDURE placeSensor(enr integer, x real, y real, mid varchar(9)) AS
    $$
    DECLARE
        new_sensor_id integer;
        time timestamp;
    BEGIN
        -- Generate a new unique sensor ID
        SELECT COALESCE(MAX(sensor_id), 0) + 1 INTO new_sensor_id FROM SENSOR;
        -- Get the current synthetic time from the CLOCK table
        SELECT synthetic_time INTO time FROM CLOCK;
        -- Insert a new entry into the SENSOR table
        INSERT INTO SENSOR(sensor_id, last_charged, energy, last_read, X, Y, maintainer_id)
        VALUES (new_sensor_id, time, enr, time, x, y, mid);
    END;
    $$ LANGUAGE plpgsql;


-- Given an sensor_id, report time, and temperature,
-- add an entry to report table.
CREATE OR REPLACE PROCEDURE generateReport(sid integer, rt timestamp, temp real) AS
    $$
    BEGIN
        INSERT INTO REPORT
        VALUES (sid, rt, temp);
    END;
    $$ LANGUAGE plpgsql;

-- Given an genus, epithet, and forest_no, remove
-- an entry from the found in table.
CREATE OR REPLACE PROCEDURE removeSpeciesFromForest(no integer, gen varchar(30), epi varchar(30)) AS
    $$
    BEGIN
        DELETE FROM FOUND_IN
        WHERE forest_no = no AND genus = gen AND epithet = epi;
    END;
    $$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE deleteWorker(n varchar(9)) AS
    $$
    BEGIN
        DELETE FROM WORKER
        WHERE ssn = n;
    END;
    $$ LANGUAGE plpgsql;

-- Given sensor_id and X,Y
-- Update sensor in sensor table

CREATE OR REPLACE PROCEDURE moveSensor(sid integer, new_x real, new_y real) AS
    $$
    BEGIN
        UPDATE SENSOR s
        SET X = new_x, Y = new_y
        WHERE sensor_id = sid;
    END;
    $$ LANGUAGE plpgsql;

-- Given a SSN and abbreviation, remove entry from employed table.
-- If possible, reassign all associated sensors to the
-- worker with the lowest SSN working for the state.
CREATE OR REPLACE PROCEDURE removeWorkerFromState(n char(9), abb char(2)) AS
    $$
    BEGIN
        DELETE FROM EMPLOYED
        WHERE worker = n AND state = abb;
    END;
    $$ LANGUAGE plpgsql;

-- Given sensor_id
-- delete sensor entry from sensor table.
CREATE OR REPLACE PROCEDURE removerSensor(sid integer)AS
    $$
    BEGIN
        DELETE FROM SENSOR
        WHERE sensor_id = sid;
    END;
    $$ LANGUAGE plpgsql;

-- Given forest_id, list all sensors within that forest.
CREATE OR REPLACE FUNCTION listSensors(no integer) RETURNS TABLE (
        sensor_id integer,
        last_charged timestamp,
        energy integer,
        last_read timestamp,
        X real,
        Y real,
        maintainer_id varchar(9)
    ) AS $$
    DECLARE
        rec_forest record;
    BEGIN
        SELECT * INTO rec_forest FROM FOREST WHERE forest_no = no;
        RETURN QUERY
        SELECT s.*
        FROM SENSOR s
        WHERE (s.X BETWEEN rec_forest.MBR_XMin AND rec_forest.MBR_XMAX) AND
              (s.Y BETWEEN rec_forest.MBR_YMin AND rec_forest.MBR_YMAX);
    END;
    $$ LANGUAGE plpgsql;

-- Given an SSN, display all sensors associated with that worker.
CREATE OR REPLACE FUNCTION listMaintainedSensors(n char(9)) RETURNS TABLE (
        sensor_id integer,
        last_charged timestamp,
        energy integer,
        last_read timestamp,
        X real,
        Y real,
        maintainer_id varchar(9)
    ) AS $$
    BEGIN
        RETURN QUERY
        SELECT s.*
        FROM SENSOR s
        WHERE s.maintainer_id = n;
    END;
    $$ LANGUAGE plpgsql;

-- Given an alpha string and beta string, list all forests
-- that contain trees with a genus like alpha and an epithet
-- like beta.
CREATE OR REPLACE FUNCTION locateTreeSpecies(alpha varchar(30), beta varchar(30)) RETURNS TABLE (
        forest_no integer,
        name varchar(30),
        area integer,
        acid_level real,
        MBR_XMin real,
        MBR_XMax real,
        MBR_YMin real,
        MBR_YMax real
    ) AS $$
    BEGIN
        RETURN QUERY
        SELECT f.*
        FROM FOREST f NATURAL JOIN FOUND_IN fi
        WHERE fi.genus ILIKE alpha AND fi.epithet ILIKE beta;
    END;
    $$ LANGUAGE plpgsql;
