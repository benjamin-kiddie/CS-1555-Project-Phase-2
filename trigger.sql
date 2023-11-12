------------------------------------------------
-- CS1555/2055 Project 2 Triggers
-- Triggers for Arbor_DB and their corresponding
-- trigger functions.
--
-- Authors: Hala Nubani, Ethan Wells, Ben Kiddie
------------------------------------------------

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
            percentage = area / ((NEW.mbr_xmax - NEW.mbr_xmin) * (NEW.mbr_ymax - NEW.mbr_ymin));
            -- Insert into COVERAGE table.
            INSERT INTO COVERAGE
            VALUES (NEW.forest_no, rec_state.abbreviation, percentage, area);
        END LOOP;
    END;
    $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS addForestCoverage ON FOREST;
CREATE TRIGGER addForestCoverage
    AFTER INSERT
    ON FOREST
    FOR EACH ROW
    EXECUTE PROCEDURE addForestCoverage();

-----------------------------------------------------------------

-- Calculate a forest's area when it is
-- inserted or modified. If this area is <=0,
-- prevent insertion.
CREATE OR REPLACE FUNCTION calculateForestArea() RETURNS TRIGGER AS
    $$
    DECLARE
        x_dist real;
        y_dist real;
        area integer;
    BEGIN
        x_dist := NEW.mbr_xmax - NEW.mbr_xmin;
        y_dist := NEW.mbr_ymax - NEW.mbr_ymin;
        IF x_dist <= 0 OR y_dist <= 0 THEN
            RAISE EXCEPTION 'The given MBR bounds will result in an area of 0 or less. Aborting insertion.';
        END IF;
        area = x_dist * y_dist;
        NEW.area = area;
    END;
    $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS calculateForestArea ON FOREST;
CREATE TRIGGER calculateForestArea
    BEFORE INSERT OR UPDATE
    ON FOREST
    FOR EACH ROW
    EXECUTE PROCEDURE calculateForestArea();

-----------------------------------------------------------------

-- Calculate a state's area when it is
-- inserted or modified. If this area is <=0,
-- abort the insert/update.
CREATE OR REPLACE FUNCTION calculateStateArea() RETURNS TRIGGER AS
    $$
    DECLARE
        x_dist real;
        y_dist real;
        area integer;
    BEGIN
        x_dist := NEW.mbr_xmax - NEW.mbr_xmin;
        y_dist := NEW.mbr_ymax - NEW.mbr_ymin;
        IF x_dist <= 0 OR y_dist <= 0 THEN
            RAISE EXCEPTION 'The given MBR bounds will result in an area of 0 or less. Aborting insertion.';
        END IF;
        area = x_dist * y_dist;
        NEW.area = area;
    END;
    $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS calculateStateArea ON STATE;
CREATE TRIGGER calculateStateArea
    BEFORE INSERT OR UPDATE
    ON STATE
    FOR EACH ROW
    EXECUTE PROCEDURE calculateStateArea();

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
            IF NEW.abbreviation != rec_state.abbreviation
                   AND checkMBROverlap(NEW.mbr_xmin, rec_state.mbr_xmin,
                NEW.mbr_ymin, rec_state.mbr_ymin,
                NEW.mbr_xmax, rec_state.mbr_xmax,
                NEW.mbr_ymax, rec_state.mbr_ymax) THEN
                RAISE EXCEPTION 'Newly inserted/updated state will overlap with existing state.';
            END IF;
        END LOOP;
    END;
    $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS checkStateOverlap ON STATE;
CREATE TRIGGER checkStateOverlap
    BEFORE INSERT OR UPDATE
    ON STATE
    FOR EACH ROW
    EXECUTE PROCEDURE checkStateOverlap();

-----------------------------------------------------------------

-- Check if an inserted or modified state will overlap
-- with any other states. If so, abort the insert/update.
CREATE OR REPLACE FUNCTION checkForestOverlap() RETURNS TRIGGER AS
    $$
    DECLARE
        rec_forest record;
    BEGIN
        -- Loop over all states, checking for overlap.
        FOR rec_forest IN SELECT forest_no, mbr_xmin, mbr_xmax, mbr_ymin, mbr_ymax FROM FOREST
        LOOP
            IF NEW.forest_no != rec_forest.forest_no
                   AND checkMBROverlap(NEW.mbr_xmin, rec_forest.mbr_xmin,
                NEW.mbr_ymin, rec_forest.mbr_ymin,
                NEW.mbr_xmax, rec_forest.mbr_xmax,
                NEW.mbr_ymax, rec_forest.mbr_ymax) THEN
                RAISE EXCEPTION 'Newly inserted/updated forest will overlap with existing forest.';
            END IF;
        END LOOP;
    END;
    $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS checkStateOverlap ON STATE;
CREATE TRIGGER checkStateOverlap
    BEFORE INSERT OR UPDATE
    ON STATE
    FOR EACH ROW
    EXECUTE PROCEDURE checkStateOverlap();