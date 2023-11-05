DROP SCHEMA IF EXISTS arbor_db CASCADE;
CREATE SCHEMA arbor_db;
SET SCHEMA 'arbor_db';

CREATE TABLE CLOCK (
    synthetic_time timestamp,
    CONSTRAINT clock_pk PRIMARY KEY (synthetic_time)
);

CREATE TABLE FOREST (
    forest_no integer,
    name varchar(30),
    area integer,
    acid_level real,
    MBR_XMin real,
    MBR_XMax real,
    MBR_YMin real,
    MBR_YMax real,
    CONSTRAINT forest_pk PRIMARY KEY (forest_no)
);

CREATE TABLE STATE (
    name varchar(30),
    abbreviation char(2),
    area integer,
    population integer,
    MBR_XMin real,
    MBR_XMax real,
    MBR_YMin real,
    MBR_YMax real,
    CONSTRAINT state_pk PRIMARY KEY (name)
);

DROP DOMAIN IF EXISTS Raunkiaer_life_form;
CREATE DOMAIN Raunkiaer_life_form AS varchar(16)
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

CREATE TABLE TREE_SPECIES (
    genus varchar(30),
    epithet varchar(30),
    ideal_temperature real,
    largest_height real,
    raunkiaer_life_form Raunkiaer_life_form,
    CONSTRAINT tree_species_pk PRIMARY KEY (genus, epithet)
);

CREATE TABLE TREE_COMMON_NAME (
    genus varchar(30),
    epithet varchar(30),
    common_name varchar(30),
    CONSTRAINT tree_common_name_pk PRIMARY KEY (genus, epithet),
    CONSTRAINT unique_common_name UNIQUE (common_name)
);

CREATE TABLE WORKER (
    SSN char(9),
    first varchar(30),
    last varchar(30),
    middle char(1),
    rank varchar(10),
    CONSTRAINT worker_pk PRIMARY KEY (SSN),
    CONSTRAINT worker_rank CHECK (rank IN ('Lead', 'Senior', 'Associate'))
);

CREATE TABLE PHONE (
    worker varchar(30),
    type varchar(30),
    number varchar(16),
    CONSTRAINT phone_pk PRIMARY KEY (worker, type),
    CONSTRAINT phone_fk FOREIGN KEY (worker) REFERENCES WORKER(SSN)
);

CREATE TABLE EMPLOYED (
    state varchar(30),
    worker varchar(30),
    CONSTRAINT employed_pk PRIMARY KEY (state, worker),
    CONSTRAINT employed_fk FOREIGN KEY (state) REFERENCES STATE(name)
);

CREATE TABLE SENSOR (
    sensor_id integer,
    last_charged timestamp,
    energy integer,
    last_read timestamp,
    X real,
    Y real,
    maintainer_id varchar(30),
    CONSTRAINT sensor_pk PRIMARY KEY (sensor_id),
    CONSTRAINT sensor_fk FOREIGN KEY (maintainer_id) REFERENCES WORKER(SSN)
);

CREATE TABLE REPORT (
    sensor_id integer,
    report_time timestamp,
    temperature real,
    CONSTRAINT report_pk PRIMARY KEY (sensor_id, report_time),
    CONSTRAINT report_fk FOREIGN KEY (sensor_id) REFERENCES SENSOR(sensor_id)
);

CREATE TABLE COVERAGE (
    forest_no integer,
    state varchar(30),
    percentage real,
    area integer,
    CONSTRAINT coverage_pk PRIMARY KEY (forest_no, state),
    CONSTRAINT coverage_fk_forest FOREIGN KEY (forest_no) REFERENCES FOREST(forest_no),
    CONSTRAINT coverage_fk_state FOREIGN KEY (state) REFERENCES STATE(name)
);


CREATE TABLE FOUND_IN (
    forest_no integer,
    genus varchar(30),
    epithet varchar(30),
    CONSTRAINT found_in_pk PRIMARY KEY (forest_no, genus, epithet),
    CONSTRAINT found_in_fk_forest FOREIGN KEY (forest_no) REFERENCES FOREST(forest_no),
    CONSTRAINT found_in_fk_species FOREIGN KEY (genus, epithet) REFERENCES TREE_SPECIES(genus, epithet)
);
