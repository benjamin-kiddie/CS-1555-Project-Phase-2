------------------------------------------------
-- CS1555/2055 Project 2 Analytical Queries
-- Implements all assigned analytical queries.
--
-- Authors: Hala Nubani, Ethan Wells, Ben Kiddie
------------------------------------------------

SET SCHEMA 'arbor_db';

-- View that shows the number of sensors in a forest.
-- Used by rankForestSensors().
DROP VIEW IF EXISTS numSensorsInForest;
CREATE VIEW numSensorsInForest AS
    SELECT i.forest_no, COUNT(forest_no) AS num_sensors
    FROM (SELECT forest_no, sensor_id
          FROM SENSOR s
          JOIN FOREST f ON (s.x BETWEEN f.mbr_xmin AND f.mbr_xmax)
                            AND (s.y BETWEEN f.mbr_ymin AND f.mbr_ymax)) AS i
    GROUP BY i.forest_no;

-- Rank all forests based on the number of sensors within them,
-- with forests with more sensors being ranked higher than
-- forests with fewer sensors.
CREATE OR REPLACE FUNCTION rankForestSensors() RETURNS TABLE (
        forest_no integer,
        rank bigint
    ) AS
    $$
    BEGIN
        RETURN QUERY
        SELECT n.forest_no, RANK () OVER (
            ORDER BY n.num_sensors DESC
        )
        FROM numSensorsInForest n;
    END;
    $$ LANGUAGE plpgsql;

-- List all forests that are habitable for a given tree species
-- based on temperature data from the past k years.
CREATE OR REPLACE FUNCTION habitableEnvironment(g varchar(30), e varchar(30),
                                                k integer) RETURNS TABLE (
        forest_no integer
    ) AS
    $$
    DECLARE
        ideal_temp real;
        start_date timestamp;
    BEGIN
        -- Find ideal temperature for given species.
        SELECT ideal_temperature
        INTO ideal_temp
        FROM TREE_SPECIES WHERE genus = g AND EPITHET = e;
        -- Find start date for average temperatures.
        SELECT (SELECT * FROM CLOCK) - (INTERVAL '1 year' * k) INTO start_date;
        -- Find suitable forests.
        RETURN QUERY
        SELECT p.forest_no
        FROM (SELECT srf.forest_no, AVG(srf.temperature) AS average_temperature
              FROM (SELECT f.forest_no, sr.temperature
                    FROM (SELECT s.x, s.y, r.temperature
                          FROM SENSOR s
                          NATURAL JOIN (SELECT * FROM REPORT
                                        WHERE report_time BETWEEN start_date AND
                                            (SELECT * FROM CLOCK)) AS r) AS sr
                    JOIN FOREST f ON (sr.x BETWEEN f.mbr_xmin AND f.mbr_xmax)
                                      AND (sr.y BETWEEN f.mbr_ymin AND f.mbr_ymax)) AS srf
              GROUP BY srf.forest_no) AS p
        WHERE average_temperature BETWEEN ideal_temp - 5 AND ideal_temp + 5;
    END;
    $$ LANGUAGE plpgsql;

