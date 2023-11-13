------------------------------------------------
-- CS1555/2055 Project 2 Triggers
-- Triggers for Arbor_DB and their corresponding
-- trigger functions.
--
-- Authors: Hala Nubani, Ethan Wells, Ben Kiddie
------------------------------------------------

SET SCHEMA 'arbor_db';

-- Reusable function. Checks if two MBRs overlap.
CREATE OR REPLACE FUNCTION checkMBROverlap(xmin1 real, xmin2 real, ymin1 real,
    ymin2 real, xmax1 real, xmax2 real, ymax1 real, ymax2 real) RETURNS boolean AS
    $$
    DECLARE
        overlap boolean := true;
    BEGIN
        -- Check if MBRs are mutually outside other's x-bounds.
        IF xmin1 > xmax2 OR xmin2 > xmax1 THEN
            overlap := false;
        END IF;
        -- Check if MBRs are mutually outside other's y-bounds.
        IF ymin1 > ymax2 OR ymin2 > ymax1 THEN
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
            IF NOT checkMBROverlap(NEW.mbr_xmin, rec_state.mbr_xmin,
                NEW.mbr_ymin, rec_state.mbr_ymin,
                NEW.mbr_xmax, rec_state.mbr_xmax,
                NEW.mbr_ymax, rec_state.mbr_ymax) THEN
                CONTINUE;
            END IF;
            -- If so, calculate area overlap.
            x_dist = min(NEW.mbr_xmax, rec_state.mbr_xmax) - max(NEW.mbr_xmin, rec_state.mbr_xmin);
            y_dist = min(NEW.mbr_ymax, rec_state.mbr_ymax) - max(NEW.mbr_ymin, rec_state.mbr_ymin);
            area = x_dist * y_dist;
            percentage = area / NEW.area;
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
                   AND checkMBROverlap(NEW.mbr_xmin, rec_state.mbr_xmin,
                NEW.mbr_ymin, rec_state.mbr_ymin,
                NEW.mbr_xmax, rec_state.mbr_xmax,
                NEW.mbr_ymax, rec_state.mbr_ymax) THEN
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
                   AND checkMBROverlap(NEW.mbr_xmin, rec_forest.mbr_xmin,
                NEW.mbr_ymin, rec_forest.mbr_ymin,
                NEW.mbr_xmax, rec_forest.mbr_xmax,
                NEW.mbr_ymax, rec_forest.mbr_ymax) THEN
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
-- prevented if the case is not as such.
CREATE OR REPLACE FUNCTION checkMaintainerEmployment() RETURNS TRIGGER AS
    $$
    DECLARE
        rec_state_abb record;
        rec_state record;
    BEGIN
        -- For each state (abbreviation) that the worker is employed in...
        FOR rec_state_abb IN SELECT state FROM EMPLOYED WHERE worker = NEW.maintainer_id
        LOOP
            -- First, obtain the full state tuple.
            SELECT * INTO rec_state FROM STATE WHERE abbreviation = rec_state_abb.state;
            -- If the X and Y position of the sensor lies within state, proceed with insert/update.
            IF NEW.X <= rec_state.MBR_XMax AND NEW.X >= rec_state.MBR_XMin
                AND NEW.Y <= rec_state.MBR_YMax AND NEW.Y >= rec_state.MBR_YMin THEN
                RETURN NEW;
            END IF;
        END LOOP;
        -- If X any Y position of sensor is not contained within any state, throw an exception.
        RAISE 'maintainer_not_employed_in_state' USING errcode = 'NOEMP';
    EXCEPTION
        WHEN sqlstate 'NOEMP' THEN
            RAISE NOTICE 'The new maintainer of this sensor is not employed by a state which covers the sensor. This operation has been reverted.';
            RETURN OLD;
    END;
    $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS checkMaintainerEmployment ON SENSOR;
CREATE TRIGGER checkMaintainerEmployment
    BEFORE INSERT OR UPDATE
    ON SENSOR
    FOR EACH ROW
    EXECUTE FUNCTION checkMaintainerEmployment();
