------------------------------------------------
-- CS1555/2055 Project 2 Schema
-- Schema for Arbow_DB, containing tables and
-- corresponding constraints.
--
-- Authors: Hala Nubani, Ethan Wells, Ben Kiddie
------------------------------------------------

DROP SCHEMA IF EXISTS arbor_db CASCADE;
CREATE SCHEMA arbor_db;
SET SCHEMA 'arbor_db';

------------------------------------------------------
-- CLOCK table.
--
-- Keys:
-- PK -> synthetic_time (timestamp)
--
-- Assumptions:
-- Only one synthetic time can exist.
------------------------------------------------------
DROP TABLE IF EXISTS CLOCK CASCADE;
CREATE TABLE CLOCK (
    synthetic_time timestamp,

    CONSTRAINT clock_pk PRIMARY KEY (synthetic_time)
);

------------------------------------------------------
-- FOREST table.
--
-- Keys:
-- PK -> forest_no (integer)
--
-- Assumptions:
-- Acid level must be between 0 and 14.
-- No two forests can have overlapping MBRs.
-- Area the area of the MBR using given points.
-- MBR bounds must be given.
-- MBR area cannot be 0 or negative, nor can max
--  values be less than min values.
------------------------------------------------------
DROP TABLE IF EXISTS FOREST CASCADE;
CREATE TABLE FOREST (
    forest_no integer,
    name varchar(30),
    area integer,
    acid_level real,
    MBR_XMin real NOT NULL,
    MBR_XMax real NOT NULL,
    MBR_YMin real NOT NULL,
    MBR_YMax real NOT NULL,

    CONSTRAINT forest_pk PRIMARY KEY (forest_no),
    CONSTRAINT forest_bounded_acid_level CHECK (acid_level BETWEEN 0 AND 14)
);

------------------------------------------------------
-- STATE table.
--
-- Keys:
-- PK -> abbreviation (varchar(2))
--
-- Assumptions:
-- State name is unique.
-- Population is non-negative.
-- No two states can have overlapping MBRs.
-- Area the area of the MBR using given points.
-- MBR bounds must be given.
-- MBR area cannot be 0 or negative, nor can max
--  values be less than min values.
------------------------------------------------------
DROP TABLE IF EXISTS STATE CASCADE;
CREATE TABLE STATE (
    name varchar(30),
    abbreviation char(2),
    area integer,
    population integer,
    MBR_XMin real NOT NULL,
    MBR_XMax real NOT NULL,
    MBR_YMin real NOT NULL,
    MBR_YMax real NOT NULL,

    CONSTRAINT state_pk PRIMARY KEY (abbreviation),
    CONSTRAINT state_unique_name UNIQUE (name),
    CONSTRAINT state_positive_population CHECK (population >= 0)
);

DROP DOMAIN IF EXISTS raunkiaer_life_form;
CREATE DOMAIN raunkiaer_life_form AS varchar(16)
    CHECK (
        VALUE IN (
            'Phanerophytes',
            'Epiphytes',
            'Chamaephytes',
            'Hemicryptophytes',
            'Cryptophytes',
            'Therophytes',
            'Aerophytes'
        )
    );

------------------------------------------------------
-- TREE_SPECIES table.
--
-- Keys:
-- PK -> (genus, epithet) (both varchar(30))
--
-- Assumptions:
-- Largest height must be greater than 0.
------------------------------------------------------
DROP TABLE IF EXISTS TREE_SPECIES CASCADE;
CREATE TABLE TREE_SPECIES (
    genus varchar(30),
    epithet varchar(30),
    ideal_temperature real,
    largest_height real,
    raunkiaer_life_form raunkiaer_life_form,

    CONSTRAINT tree_species_pk PRIMARY KEY (genus, epithet),
    CONSTRAINT tree_positive_largest_height CHECK (largest_height > 0)
);

------------------------------------------------------
-- TREE_COMMON_NAME table.
--
-- Keys:
-- PK -> (genus, epithet, common_name)
--  (all varchar(30))
--
-- Assumptions:
-- Multiple species can share same common name.
-- Same species can have multiple common names.
------------------------------------------------------
DROP TABLE IF EXISTS TREE_COMMON_NAME CASCADE;
CREATE TABLE TREE_COMMON_NAME (
    genus varchar(30),
    epithet varchar(30),
    common_name varchar(30),

    CONSTRAINT tree_common_name_pk PRIMARY KEY (genus, epithet, common_name)
);

DROP DOMAIN IF EXISTS rank;
CREATE DOMAIN rank AS varchar(10)
    CHECK (
        VALUE IN (
            'Lead',
            'Senior',
            'Associate'
        )
    );

------------------------------------------------------
-- WORKER table.
--
-- Keys:
-- PK -> (SSN) (varchar(9))
--
-- Assumptions:
-- SSN must be 9 digits.
------------------------------------------------------
DROP TABLE IF EXISTS WORKER CASCADE;
CREATE TABLE WORKER (
    SSN char(9),
    first varchar(30),
    last varchar(30),
    middle char(1),
    rank rank,

    CONSTRAINT worker_pk PRIMARY KEY (SSN),
    CONSTRAINT worker_valid_ssn CHECK (SSN SIMILAR TO '[0-9]{9}')
);

------------------------------------------------------
-- PHONE table.
--
-- Keys:
-- PK -> number (varchar(16))
-- FK -> worker (varchar(9)) references WORKER(SSN)
--
-- Assumptions:
-- Number must be 10 digits.
-- On update/deletion of worker, all associated
--  numbers are updated/deleted.
------------------------------------------------------
DROP TABLE IF EXISTS PHONE CASCADE;
CREATE TABLE PHONE (
    worker varchar(9),
    type varchar(30),
    number varchar(16),

    CONSTRAINT phone_pk PRIMARY KEY (number),
    CONSTRAINT phone_fk_worker FOREIGN KEY (worker) REFERENCES WORKER(SSN)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT phone_valid_number CHECK
        (number SIMILAR TO '[0-9]{10}')
);

------------------------------------------------------
-- EMPLOYED table.
--
-- Keys:
-- PK -> (state, worker) (varchar(2) and varchar(9))
-- FK -> state (varchar(2)) references
--  STATE(abbreviation)
-- FK -> worker (varchar(9)) references WORKER(SSN)
--
-- Assumptions:
-- Worker can be employed by multiple states.
-- On update/deletion of state, all associated
--  employments are updated/deleted.
-- On update/deletion of worker, all associated
--  employments are updated/deleted.
------------------------------------------------------
DROP TABLE IF EXISTS EMPLOYED CASCADE;
CREATE TABLE EMPLOYED (
    state varchar(2),
    worker varchar(9),

    CONSTRAINT employed_pk PRIMARY KEY (state, worker),
    CONSTRAINT employed_fk_state FOREIGN KEY (state) REFERENCES STATE(abbreviation)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT employed_fk_worker FOREIGN KEY (worker) REFERENCES WORKER(SSN)
        ON UPDATE CASCADE ON DELETE CASCADE
);

------------------------------------------------------
-- SENSOR table.
--
-- Keys:
-- PK -> sensor_id (integer)
-- FK -> maintainer_id (varchar(9)) references
--  WORKER(SSN)
--
-- Assumptions:
-- Energy must be between 0 and 100.
-- Sensors must be located at a point within the
--  MBR bounds of a state that the maintainer is
--  employed at.
-- Upon unemployment of the maintainer, sensor is
--  reassigned to the minimum SSN worker in the same
--  state if possible, or deleted if not.
-- On update/deletion of a maintainer, associated
--  sensors are updated/deleted.
------------------------------------------------------
DROP TABLE IF EXISTS SENSOR CASCADE;
CREATE TABLE SENSOR (
    sensor_id integer,
    last_charged timestamp,
    energy integer,
    last_read timestamp,
    X real NOT NULL,
    Y real NOT NULL,
    maintainer_id varchar(9),

    CONSTRAINT sensor_pk PRIMARY KEY (sensor_id),
    CONSTRAINT sensor_fk_worker FOREIGN KEY (maintainer_id) REFERENCES WORKER(SSN)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINt sensor_bounded_energy CHECK (energy BETWEEN 0 AND 100)
);

------------------------------------------------------
-- REPORT table.
--
-- Keys:
-- PK -> (sensor_id, report_time) (integer, timestamp)
-- FK -> sensor_id (integer) references
--  SENSOR(sensor_id)
--
-- Assumptions:
-- Temperature must be given.
-- On update/deletion of sensor, all associated
--  reports are updated/deleted.
------------------------------------------------------
DROP TABLE IF EXISTS REPORT CASCADE;
CREATE TABLE REPORT (
    sensor_id integer,
    report_time timestamp,
    temperature real NOT NULL,

    CONSTRAINT report_pk PRIMARY KEY (sensor_id, report_time),
    CONSTRAINT report_fk_sensor FOREIGN KEY (sensor_id) REFERENCES SENSOR(sensor_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

------------------------------------------------------
-- COVERAGE table.
--
-- Keys:
-- PK -> (forest_no, state) (integer, varchar(2))
-- FK -> forest_no (integer) references
--  FOREST(forest_no)
-- FK -> state (varchar(2)) references
--  STATE(abbreviation)
--
-- Assumptions:
-- Entries are auto-calculated upon insertion of a
--  forest and updated whenever forest bounds change.
-- Percentage must be greater than 0 and less than
--  100.
-- On update/deletion of a state, all associated
--  coverage is updated/deleted.
-- UN update/deletion of a forest, all associated
--  coverage is updated/deleted.
------------------------------------------------------
DROP TABLE IF EXISTS COVERAGE CASCADE;
CREATE TABLE COVERAGE (
    forest_no integer,
    state varchar(2),
    percentage real,
    area integer,

    CONSTRAINT coverage_pk PRIMARY KEY (forest_no, state),
    CONSTRAINT coverage_fk_forest FOREIGN KEY (forest_no) REFERENCES FOREST(forest_no)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT coverage_fk_state FOREIGN KEY (state) REFERENCES STATE(abbreviation)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT coverage_bounded_percent CHECK (percentage > 0 AND percentage <= 100)
);

------------------------------------------------------
-- FOUND_IN table.
--
-- Keys:
-- PK -> (forest_no, genus, epithet)
--  (integer, varchar(30), varchar(30))
-- FK -> forest_no (integer) references
--  FOREST(forest_no)
-- FK -> (genus, epithet) (both varchar(30))
--  references TREE_SPECIES(genus, epithet)
--
-- Assumptions:
-- On update/deletion of a forest, all associated
--  findings are updated/deleted.
-- UN update/deletion of a species, all associated
--  findings are updated/deleted.
------------------------------------------------------
DROP TABLE IF EXISTS FOUND_IN CASCADE;
CREATE TABLE FOUND_IN (
    forest_no integer,
    genus varchar(30),
    epithet varchar(30),

    CONSTRAINT found_in_pk PRIMARY KEY (forest_no, genus, epithet),
    CONSTRAINT found_in_fk_forest FOREIGN KEY (forest_no) REFERENCES FOREST(forest_no)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT found_in_fk_species FOREIGN KEY (genus, epithet) REFERENCES TREE_SPECIES(genus, epithet)
        ON UPDATE CASCADE ON DELETE CASCADE
);