-- Tabulka (pohled) tabulek

DROP TABLE "Klient";

SELECT table_name FROM User_tables;
SELECT table_name FROM All_tables ORDER BY  table_name;
SELECT * FROM User_tables WHERE table_name = 'KLIENT';
SELECT * FROM User_tables WHERE table_name = 'Klient';
SELECT * FROM User_tables WHERE table_name = UPPER('Klient');

-- Jméno tabulky jako identifikátor v uvozovkách "Klient"
CREATE TABLE "Klient"(
c1 INTEGER);

-- Tabulka (pohled) sloupcu tabulek
-- Oracle
SELECT table_name, column_name FROM User_tab_columns;

SELECT column_name 
FROM User_tab_columns 
WHERE table_name='KLIENT';

DESCRIBE Klient;

-- Tabulka (pohled) pohledu

CREATE VIEW Janska AS
  SELECT Z.*
     FROM  Klient Z, Ucet U
     WHERE Z.r_cislo=U.r_cislo AND pobocka='Jánská';

-- Oracle
SELECT view_name, text FROM User_views;

-- Tabulka (pohled) na deklarativní integritní omezeni
-- Oracle
SELECT owner, constraint_name FROM USER_CONSTRAINTS
WHERE table_name = 'KLIENT';

-- Formátování pøi spuštìní v SQL Plus
COLUMN table_name FORMAT A15;
COLUMN column_name FORMAT A15;
COLUMN constraint_type FORMAT A1;

-- Omezení typu PRIMARY KEY nebo UNIQUE v tabulce Klient
SELECT CC.table_name, CC.column_name, C.constraint_type
FROM USER_CONSTRAINTS C JOIN USER_CONS_COLUMNS CC USING (constraint_name)
WHERE CC.table_name='KLIENT' AND (C.constraint_type='P' OR C.constraint_type='U');


