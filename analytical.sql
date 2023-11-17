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

