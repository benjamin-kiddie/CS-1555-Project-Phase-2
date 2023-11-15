------------------------------------------------
-- CS1555/2055 Project 2 Tests
-- File for storing various test queries.
--
-- Authors: Hala Nubani, Ethan Wells, Ben Kiddie
------------------------------------------------

SET SCHEMA 'arbor_db';

-- Testing of operations:
INSERT INTO CLOCK VALUES (NOW());
INSERT INTO STATE VALUES ('Rhode Island', 'RI', 0, 1, 0, 20, 0, 20);
INSERT INTO STATE VALUES ('New York', 'NY', 0, 1, 21, 40, 21, 40);
INSERT INTO STATE VALUES ('New York 2', 'NL', 0, 1, 21, 40, 21, 40);
CALL addForest('Test Forest', 0, 7, 0, 20, 0, 20);
CALL addTreeSpecies('Test', 'Species', 100, 7, 'Epiphytes');
CALL addSpeciesToForest(1, 'Test', 'Species');
CALL newWorker('000000000', 'Test', 'Test', 'T', 'Associate', 'RI');
CALL newWorker('000000001', 'Test2', 'Test2', 'T', 'Associate', 'RI');
CALL employWorkerToState('000000000', 'NY');
CALL placeSensor(100, 0, 0, '000000000');
CALL generateReport(1, LOCALTIMESTAMP, 100);

CALL removeSpeciesFromForest(1, 'Test', 'Species');
CALL deleteWorker('000000000');
CALL moveSensor(1, 100, 100);

SELECT MIN(worker)
FROM EMPLOYED
WHERE state = 'RI' AND worker != '000000000';
UPDATE sensor
SET maintainer_id = '000000000'
WHERE sensor_id = 1;
CALL employWorkerToState('000000000', 'RI');
CALL removeWorkerFromState('000000000', 'RI');

SELECT * FROM listSensors(1);
SELECT * FROM listMaintainedSensors('873331998');
SELECT * FROM locateTreeSpecies('Test', 'Species');