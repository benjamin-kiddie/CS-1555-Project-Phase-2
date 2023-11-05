
CREATE TABLE CLOCK (
    synthetic_time timestamp,
    PRIMARY KEY (synthetic_time)
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
    PRIMARY KEY (forest_no)
);


CREATE TABLE EMPLOYED (
    state varchar(30),
    worker varchar(30),
    PRIMARY KEY (state, worker),
    FOREIGN KEY (state) REFERENCES STATE(name)
);


CREATE TABLE PHONE (
    worker varchar(30),
    type varchar(30),
    number varchar(16),
    PRIMARY KEY (worker, type),
    FOREIGN KEY (worker) REFERENCES WORKER(SSN)
);


CREATE TABLE REPORT (
    sensor_id integer,
    report_time timestamp,
    temperature real,
    PRIMARY KEY (sensor_id, report_time),
    FOREIGN KEY (sensor_id) REFERENCES SENSOR(sensor_id)
);


CREATE TABLE SENSOR (
    sensor_id integer,
    last_charged timestamp,
    energy integer,
    last_read timestamp,
    X real,
    Y real,
    maintainer_id varchar(30),
    PRIMARY KEY (sensor_id),
    FOREIGN KEY (maintainer_id) REFERENCES WORKER(SSN)
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
    PRIMARY KEY (name)
);


CREATE TABLE TREE_COMMON_NAME (
    genus varchar(30),
    epithet varchar(30),
    common_name varchar(30),
    PRIMARY KEY (genus, epithet),
    UNIQUE (common_name)
);


CREATE TABLE TREE_SPECIES (
    genus varchar(30),
    epithet varchar(30),
    ideal_temperature real,
    largest_height real,
    raunkiaer_life_form varchar(16),
    PRIMARY KEY (genus, epithet),
    FOREIGN KEY (raunkiaer_life_form) REFERENCES Raunkiaer_life_form(type)
);


CREATE TABLE WORKER (
    SSN char(9),
    first varchar(30),
    last varchar(30),
    middle char(1),
    rank varchar(10),
    PRIMARY KEY (SSN),
    UNIQUE (first, last),
    CHECK (rank IN ('Lead', 'Senior', 'Associate'))
);


CREATE TABLE COVERAGE (
    forest_no integer,
    state varchar(30),
    percentage real,
    area integer,
    PRIMARY KEY (forest_no, state),
    FOREIGN KEY (forest_no) REFERENCES FOREST(forest_no),
    FOREIGN KEY (state) REFERENCES STATE(name)
);


CREATE TABLE FOUND_IN (
    forest_no integer,
    genus varchar(30),
    epithet varchar(30),
    PRIMARY KEY (forest_no, genus, epithet),
    FOREIGN KEY (forest_no) REFERENCES FOREST(forest_no),
    FOREIGN KEY (genus, epithet) REFERENCES TREE_SPECIES(genus, epithet)
);


CREATE TYPE Raunkiaer_life_form AS ENUM (
    'Phanerophytes',
    'Epiphytes',
    'Chamaephytes',
    'Hemicryptophytes',
    'Cryptophytes',
    'Therophytes',
    'Aerophytes'
);
