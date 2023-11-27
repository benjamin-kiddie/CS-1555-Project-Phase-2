------------------------------------------------
-- CS1555/2055 Project 2 Tests
-- File for storing various test queries.
--
-- Authors: Hala Nubani, Ethan Wells, Ben Kiddie
------------------------------------------------

SET SCHEMA 'arbor_db';

INSERT INTO CLOCK VALUES (localtimestamp);

-- Testing of analytical queries.
SELECT * FROM rankForestSensors();
SELECT * FROM habitableEnvironment('Ilex', 'Decidua', '3');
SELECT * FROM topSensors(10, 24);