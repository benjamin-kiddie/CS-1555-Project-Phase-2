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
        -- Determine current max forest number
        no := (SELECT COALESCE(MAX(forest_no), 0) FROM FOREST) + 1;
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

--Given energy, x,y, and maintainer_id
-- add new sensor into sensor table
CREATE OR REPLACE PROCEDURE placeSensor(enr integer, x real, y real, mid varchar(9)) AS
    $$
    DECLARE
        new_sensor_id integer;
        synthetic_time timestamp;
    BEGIN
        -- Generate a new unique sensor ID
        SELECT COALESCE(MAX(sensor_id), 0) + 1 INTO new_sensor_id FROM SENSOR;

        -- Get the current synthetic time from the CLOCK table
        SELECT synthetic_time INTO synthetic_time FROM CLOCK;

        -- Insert a new entry into the SENSOR table
        INSERT INTO SENSOR(sensor_id, last_charged, energy, last_read, X, Y, maintainer_id)
        VALUES (new_sensor_id, synthetic_time, enr, synthetic_time, x, y, mid);
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
CREATE OR REPLACE PROCEDURE removeSpeciesFromForest(gen varchar(30), epi varchar(30), no integer) AS
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

CREATE OR REPLACE PROCEDURE moveSensor(sid integer, x real, y real)AS
    $$
    BEGIN
        UPDATE SENSOR
        SET X = x, Y = y
        WHERE sensor_id = sid;
    END;
    $$ LANGUAGE plpgsql;

-- Given a SSN and abb
-- remove worker's employment for given state
-- does this correctly handle assigning sensor id to another worker?

CREATE OR REPLACE PROCEDURE removeWorkerFromState(n char(9), abb char(2))AS
    $$
    BEGIN
        DELETE FROM EMPLOYED
        WHERE SSN = n AND abbreviation = abb;
    END;
    $$ LANGUAGE plpgsql;

-- Given sensor_id
-- delete sensor entry from sensor table
-- + any reports related should be deleted

CREATE OR REPLACE PROCEDURE removerSensor(sid integer)AS
    $$
    BEGIN
        DELETE FROM SENSOR
        WHERE sensor_id = sid;
    END;
    $$ LANGUAGE plpgsql;

-- Given forest_id
-- List all sensors

CREATE OR REPLACE FUNCTION listSensors(forest_id integer) RETURNS TABLE (
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
        SELECT s.sensor_id, s.last_charged, s.energy, s.last_read, s.X, s.Y, s.maintainer_id
        FROM SENSOR s
        WHERE s.sensor_id IN (
            SELECT sensor_id
            FROM FOUND_IN
            WHERE forest_no = forest_id
        );
    END;
    $$ LANGUAGE plpgsql;



-- Given SSN
-- Display all sensors

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
        SELECT sensor_id, last_charged, energy, last_read, X, Y, maintainer_id
        FROM SENSOR
        WHERE maintainer_id = n;
    END;
    $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION locateTreeSpecies(alpha VARCHAR, beta VARCHAR) RETURNS TABLE (
        forest_no INTEGER,
        name VARCHAR(30),
        area INTEGER,
        acid_level REAL,
        MBR_XMin REAL,
        MBR_XMax REAL,
        MBR_YMin REAL,
        MBR_YMax REAL
    ) AS $$
    BEGIN
        RETURN QUERY
        SELECT f.forest_no, f.name, f.area, f.acid_level, f.MBR_XMin, f.MBR_XMax, f.MBR_YMin, f.MBR_YMax
        FROM FOREST f
        JOIN FOUND_IN fi ON f.forest_no = fi.forest_no
        JOIN TREE_SPECIES ts ON ts.genus ILIKE alpha OR ts.epithet ILIKE beta
        WHERE ts.genus = fi.genus AND ts.epithet = fi.epithet;
    END;
    $$ LANGUAGE plpgsql;
