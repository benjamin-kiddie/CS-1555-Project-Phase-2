------------------------------------------------
-- CS1555/2055 Project 2 Triggers
-- Triggers for Arbor_DB and their corresponding
-- trigger functions.
--
-- Authors: Hala Nubani, Ethan Wells, Ben Kiddie
------------------------------------------------

SET SCHEMA 'arbor_db';

-- Reusable function. Checks if two MBRs overlap.
CREATE OR REPLACE FUNCTION checkMBROverlap(rec_1 record, rec_2 record) RETURNS boolean AS
    $$
    DECLARE
        overlap boolean := true;
    BEGIN
        -- Check if MBRs are mutually outside other's x-bounds.
        IF rec_1.mbr_xmin > rec_2.mbr_xmax OR rec_1.mbr_xmin > rec_2.mbr_xmax THEN
            overlap := false;
        END IF;
        -- Check if MBRs are mutually outside other's y-bounds.
        IF rec_1.mbr_ymin > rec_2.mbr_ymax OR rec_1.mbr_ymin > rec_2.mbr_ymax THEN
            overlap := false;
        END IF;
        RETURN overlap;
    END;
    $$ LANGUAGE plpgsql;

-----------------------------------------------------------------

-- Reusable function. Checks if a sensor falls within an MBR.
CREATE OR REPLACE FUNCTION checkSensorInMBR(rec_sensor record, rec_mbr record) RETURNS boolean AS
    $$
    DECLARE
        overlap boolean := true;
    BEGIN
        -- Check if MBRs are mutually outside other's x-bounds.
        IF NOT rec_sensor.x BETWEEN rec_mbr.mbr_xmin AND rec_mbr.mbr_xmax THEN
            overlap := false;
        END IF;
        -- Check if MBRs are mutually outside other's y-bounds.
        IF NOT rec_sensor.y BETWEEN rec_mbr.mbr_ymin AND rec_mbr.mbr_ymax THEN
            overlap := false;
        END IF;
        RETURN overlap;
    END;
    $$ LANGUAGE plpgsql;

-----------------------------------------------------------------

-- Check if a forest falls within the bounds of
-- any state, and if so, add an entry in coverage
-- indicating the percentage of area covered.
CREATE OR REPLACE FUNCTION addForestCoverage() RETURNS TRIGGER AS
    $$
    DECLARE
        rec_state record;
        x_dist real;
        y_dist real;
        area integer;
        percentage real;
    BEGIN
        -- Loop through all states.
        FOR rec_state IN SELECT abbreviation, mbr_xmin, mbr_xmax, mbr_ymin, mbr_ymax FROM STATE
        LOOP
            -- Check if forest overlaps with current state.
            IF NOT checkMBROverlap(NEW, rec_state) THEN
                CONTINUE;
            END IF;
            -- If so, calculate area overlap.
            x_dist = least(NEW.mbr_xmax, rec_state.mbr_xmax) - greatest(NEW.mbr_xmin, rec_state.mbr_xmin);
            y_dist = least(NEW.mbr_ymax, rec_state.mbr_ymax) - greatest(NEW.mbr_ymin, rec_state.mbr_ymin);
            area = x_dist * y_dist;
            percentage = area / NEW.area * 100;
            -- Insert into COVERAGE table.
            INSERT INTO COVERAGE
            VALUES (NEW.forest_no, rec_state.abbreviation, percentage, area);
        END LOOP;
        -- Return.
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS addForestCoverage ON FOREST;
CREATE TRIGGER addForestCoverage
    AFTER INSERT
    ON FOREST
    FOR EACH ROW
    EXECUTE PROCEDURE addForestCoverage();

-----------------------------------------------------------------

-- Calculate an MBR's area when it is
-- inserted or modified. If this area is <=0,
-- prevent insertion.
CREATE OR REPLACE FUNCTION calculateMBRArea() RETURNS TRIGGER AS
    $$
    DECLARE
        x_dist real;
        y_dist real;
        area integer;
    BEGIN
        x_dist := NEW.mbr_xmax - NEW.mbr_xmin;
        y_dist := NEW.mbr_ymax - NEW.mbr_ymin;
        -- If MBR has 0 or negative dimensions, raise an exception.
        IF x_dist <= 0 OR y_dist <= 0 THEN
            RAISE 'improper_mbr_bounds' USING errcode = 'MBRBD';
        END IF;
        area = x_dist * y_dist;
        NEW.area = area;
         -- Return.
        RETURN NEW;
    EXCEPTION
        WHEN sqlstate 'MBRBD' THEN
            RAISE NOTICE 'The given MBR bounds will result in an area of 0 or less. Operation reverted.';
            RETURN OLD;
    END;
    $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS calculateForestArea ON FOREST;
CREATE TRIGGER calculateForestArea
    BEFORE INSERT OR UPDATE
    ON FOREST
    FOR EACH ROW
    EXECUTE PROCEDURE calculateMBRArea();

DROP TRIGGER IF EXISTS calculateStateArea ON STATE;
CREATE TRIGGER calculateStateArea
    BEFORE INSERT OR UPDATE
    ON STATE
    FOR EACH ROW
    EXECUTE PROCEDURE calculateMBRArea();

-----------------------------------------------------------------

-- Check if an inserted or modified state will overlap
-- with any other states. If so, abort the insert/update.
CREATE OR REPLACE FUNCTION checkStateOverlap() RETURNS TRIGGER AS
    $$
    DECLARE
        rec_state record;
    BEGIN
        -- Loop over all states, checking for overlap.
        FOR rec_state IN SELECT abbreviation, mbr_xmin, mbr_xmax, mbr_ymin, mbr_ymax FROM STATE
        LOOP
            -- If state will overlap with existing state, raise an exception.
            IF NEW.abbreviation != rec_state.abbreviation
                   AND checkMBROverlap(NEW, rec_state) THEN
                RAISE 'overlap_with_existing_state' USING errcode = 'SOLAP';
            END IF;
        END LOOP;
         -- Return.
        RETURN NEW;
    EXCEPTION
        WHEN sqlstate 'SOLAP' THEN
            RAISE NOTICE 'Newly inserted/updated state will overlap with existing state. Operation reverted.';
            RETURN OLD;
    END;
    $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS checkStateOverlap ON STATE;
CREATE TRIGGER checkStateOverlap
    BEFORE INSERT OR UPDATE
    ON STATE
    FOR EACH ROW
    EXECUTE PROCEDURE checkStateOverlap();

-----------------------------------------------------------------

-- Check if an inserted or modified forest will overlap
-- with any other forests. If so, abort the insert/update.
CREATE OR REPLACE FUNCTION checkForestOverlap() RETURNS TRIGGER AS
    $$
    DECLARE
        rec_forest record;
    BEGIN
        -- Loop over all states, checking for overlap.
        FOR rec_forest IN SELECT forest_no, mbr_xmin, mbr_xmax, mbr_ymin, mbr_ymax FROM FOREST
        LOOP
            -- If forest will overlap with existing forest, raise an exception.
            IF NEW.forest_no != rec_forest.forest_no
                   AND checkMBROverlap(NEW, rec_forest) THEN
                RAISE 'overlap_with_existing_forest' USING errcode = 'FOLAP';
            END IF;
        END LOOP;
         -- Return.
        RETURN NEW;
    EXCEPTION
        WHEN sqlstate 'FOLAP' THEN
            RAISE NOTICE 'Newly inserted/updated forest will overlap with existing forest. Operation reverted.';
            RETURN OLD;
    END;
    $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS checkForestOverlap ON FOREST;
CREATE TRIGGER checkForestOverlap
    BEFORE INSERT OR UPDATE
    ON FOREST
    FOR EACH ROW
    EXECUTE PROCEDURE checkForestOverlap();

-----------------------------------------------------------------

-- Checks if the maintainer of a sensor is employed within one
-- of the states that covers the sensor's position. Operation is
-- prevented if this is not the case.
CREATE OR REPLACE FUNCTION checkMaintainerEmployment() RETURNS TRIGGER AS
    $$
    DECLARE
        rec_employed record;
        rec_state record;
    BEGIN
        -- For each state (abbreviation) that the worker is employed in...
        FOR rec_employed IN SELECT state FROM EMPLOYED WHERE worker = NEW.maintainer_id
        LOOP
            -- First, obtain the full state tuple.
            SELECT * INTO rec_state FROM STATE WHERE abbreviation = rec_employed.state;
            -- If the X and Y position of the sensor lies within state, proceed with insert/update.
            IF checkSensorInMBR(NEW, rec_state) THEN
                RAISE NOTICE 'Found permissable state.';
                RETURN NEW;
            END IF;
        END LOOP;
        -- If X any Y position of sensor is not contained within any state, throw an exception.
        RAISE 'maintainer_not_employed_in_state' USING errcode = 'NOEMP';
    EXCEPTION
        WHEN sqlstate 'NOEMP' THEN
            RAISE NOTICE 'The maintainer of this sensor is not employed by a state which covers the sensor. Operation reverted.';
            RETURN OLD;
    END;
    $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS checkMaintainerEmployment ON SENSOR;
CREATE TRIGGER checkMaintainerEmployment
    BEFORE INSERT OR UPDATE
    ON SENSOR
    FOR EACH ROW
    EXECUTE FUNCTION checkMaintainerEmployment();

-------------------------------------------------------------------

-- Updates sensor maintainer when an employment entry is deleted.
-- Finds the lowest SSN in the same state and sets that SSN as the maintainer.
-- If no such SSN exists, deletes all associated sensors.
CREATE OR REPLACE FUNCTION reassignSensors() RETURNS TRIGGER AS $$
DECLARE
    lowest_ssn integer;
    rec_state record;
BEGIN
    -- Fetch the state from which the worker is being removed.
    SELECT * INTO rec_state FROM STATE WHERE abbreviation = OLD.state;
    -- Fetch the lowest worker SSN for this state that isn't the current maintainer.
    SELECT MIN(worker) INTO lowest_ssn
    FROM EMPLOYED WHERE state = OLD.state AND worker != OLD.worker;
    -- If there is no such SSN, delete all sensors that
    -- exist within this state and are maintained by this worker.
    IF lowest_ssn IS NULL THEN
        DELETE FROM SENSOR
        WHERE maintainer_id = OLD.worker
            AND (X BETWEEN rec_state.mbr_xmin AND rec_state.mbr_xmax)
            AND (Y BETWEEN rec_state.mbr_ymin AND rec_state.mbr_ymax);
    END IF;
    -- Otherwise, reassign these sensors to the worker with the lowest SSN.
    UPDATE SENSOR
    SET maintainer_id = lowest_ssn
    WHERE maintainer_id = OLD.worker
        AND (X BETWEEN rec_state.mbr_xmin AND rec_state.mbr_xmax)
        AND (Y BETWEEN rec_state.mbr_ymin AND rec_state.mbr_ymax);
    -- Return the new table.
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS reassignSensors ON EMPLOYED;
CREATE TRIGGER reassignSensors
    AFTER DELETE
    ON EMPLOYED
    FOR EACH ROW
    EXECUTE FUNCTION reassignSensors();

-------------------------------------------------------------------

-- Prevents an insert to clock if there is already a timestamp.
CREATE OR REPLACE FUNCTION capClockEntries() RETURNS TRIGGER AS
    $$
    DECLARE
        num integer;
    BEGIN
        SELECT COUNT(*) INTO num FROM CLOCK;
        IF num > 1 THEN
            RAISE 'num_clock_entries' USING errcode = 'NCLCK';
        END IF;
        RETURN NEW;
    EXCEPTION
        WHEN sqlstate 'NCLCK' THEN
            RAISE NOTICE 'Cannot have more than one time entry in clock. Operation reverted.';
            RETURN OLD;
    END;
    $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS capClockEntries ON CLOCK;
CREATE TRIGGER capClockEntries
    BEFORE INSERT
    ON CLOCK
    FOR EACH ROW
    EXECUTE FUNCTION capClockEntries();
