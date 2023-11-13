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

DROP TABLE IF EXISTS CLOCK CASCADE;
CREATE TABLE CLOCK (
    synthetic_time timestamp,
    CONSTRAINT clock_pk PRIMARY KEY (synthetic_time)
);

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

DROP TABLE IF EXISTS WORKER CASCADE;
CREATE TABLE WORKER (
    SSN char(9),
    first varchar(30),
    last varchar(30),
    middle char(1),
    rank rank,

    CONSTRAINT worker_pk PRIMARY KEY (SSN),
    CONSTRAINT worker_valid_ssn CHECK
        (SSN LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
);

DROP TABLE IF EXISTS PHONE CASCADE;
CREATE TABLE PHONE (
    worker varchar(9),
    type varchar(30),
    number varchar(16),

    CONSTRAINT phone_pk PRIMARY KEY (number),
    CONSTRAINT phone_fk_worker FOREIGN KEY (worker) REFERENCES WORKER(SSN)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT phone_valid_number CHECK
        (number LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
);

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

DROP TABLE IF EXISTS REPORT CASCADE;
CREATE TABLE REPORT (
    sensor_id integer,
    report_time timestamp,
    temperature real NOT NULL,

    CONSTRAINT report_pk PRIMARY KEY (sensor_id, report_time),
    CONSTRAINT report_fk_sensor FOREIGN KEY (sensor_id) REFERENCES SENSOR(sensor_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

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
        ON UPDATE CASCADE ON DELETE CASCADE
);

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