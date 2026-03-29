DROP VIEW  Janska;
DROP VIEW Brnensti;
DROP VIEW Brnensti1;
DROP VIEW Brnensti2;
DROP VIEW Brnensti2a;
DROP VIEW Pocty;
DROP VIEW Pocty1;
DROP MATERIALIZED VIEW MBrnensti;

CREATE OR REPLACE VIEW Janska AS
  SELECT K.*
     FROM  Klient K, Ucet U
     WHERE K.r_cislo=U.r_cislo AND pobocka='J·nsk·';
     
SELECT * 
FROM Janska;

-- jmena sloupcu musi byt jednoznacna (nekvalifikovana)
CREATE OR REPLACE VIEW Janska AS
  SELECT *
     FROM  Klient K JOIN Ucet U ON K.r_cislo=U.r_cislo AND pobocka='J·nsk·';

-- r_cislo musÌ b˝t jenom jednou
CREATE OR REPLACE VIEW Janska AS
  SELECT K.*, U.c_uctu, U.pobocka, U.stav
     FROM  Klient K JOIN Ucet U ON K.r_cislo=U.r_cislo AND pobocka='J·nsk·';

-- nebo
CREATE OR REPLACE VIEW Janska AS
  SELECT *
     FROM  Klient JOIN Ucet USING (r_cislo) 
     WHERE pobocka='J·nsk·';

-- Pojmenov·nÌ sloupc˘ u v˝raz˘ v klauzuli SELECT
-- Takto nelze
CREATE VIEW Pocty AS
   SELECT pobocka, COUNT(*) FROM Ucet GROUP BY pobocka;
-- na rozdÌl od b·zovÈ tabulky  
SELECT pobocka, COUNT(*) FROM Ucet GROUP BY pobocka;

-- je t¯eba pojmenovat
CREATE VIEW Pocty (nazev, pocet) AS
   SELECT pobocka, COUNT(*) FROM Ucet GROUP BY pobocka;
-- nebo
CREATE OR REPLACE VIEW Pocty AS
   SELECT pobocka, COUNT(*) pocet FROM Ucet GROUP BY pobocka;

SELECT *
FROM Pocty;
   
-- DefiniËnÌ p¯Ìkaz SELECT m˙ûe pouûÌvat nejen b·zovÈ tabulky, 
-- ale i jinÈ pohledy
CREATE OR REPLACE VIEW Pocty1 AS
   SELECT MAX(pocet) max_pocet FROM Pocty;
   
SELECT *
FROM Pocty1;
   
-- Z·znam v syst. katalogu Oracle
SELECT text FROM USER_VIEWS WHERE view_name='JANSKA';
SELECT text FROM USER_VIEWS WHERE view_name='POCTY1';

-- PouûitÌ pohledu k dotazov·nÌ
SELECT r_cislo FROM Ucet WHERE pobocka='J·nsk·';
SELECT * FROM Janska;
SELECT * FROM Janska WHERE mesto='Brno';

-- Pro dotazov·nÌ pouûitÌ jako jakÈkoliv jinÈ tabulky
SELECT r_cislo, jmeno, SUM (stav) celkem
FROM Janska NATURAL JOIN Ucet
GROUP BY r_cislo, jmeno
ORDER BY celkem DESC;

-- ObnovenÌ p˘vodnÌ definice pohledu
CREATE OR REPLACE VIEW Janska AS
  SELECT K.*
     FROM  Klient K, Ucet U
     WHERE K.r_cislo=U.r_cislo AND pobocka='J·nsk·';

-- Aktualizace
-- 'key-preserved table' je takov· v˝sledn· tabulka, kter· zajiöùuje, ûe hodnota
-- prim·rnÌho klÌËe b·zovÈ tabulky se ve v˝sledku vyskytne nejv˝öe jednou. To tady 
-- nenÌ, protoûe klient m˘ûe mÌt vÌce ˙Ët˘.
INSERT INTO Janska 
VALUES ('501128/4271','Jan Nosek','BoûetÏchova 10','Brno');

-- u ORACLE jde, podle standardu SQL 92 ale neni aktualizovatelny
DELETE FROM Janska
WHERE r_cislo='440726/0672';


SELECT column_name FROM USER_UPDATABLE_COLUMNS WHERE TABLE_NAME='JANSKA';

SELECT r_cislo FROM Janska;
SELECT r_cislo FROM Klient;
SELECT * FROM Ucet;
SELECT r_cislo FROM Ucet WHERE pobocka='J·nsk·';

ROLLBACK;

-- Aktualizace pohledu
-- SelektivnÌ pohled
CREATE OR REPLACE VIEW Brnensti AS
   SELECT* FROM Klient WHERE mesto='Brno';

CREATE OR REPLACE VIEW Brnensti AS
   SELECT* FROM Klient WHERE mesto='Brno'
WITH CHECK OPTION;


SELECT * FROM Brnensti;
SELECT * FROM Klient;

INSERT INTO Brnensti 
   VALUES ('560726/0826','Josef Nov·k','Kobliûn· 5','Brno');

DELETE FROM Brnensti WHERE r_cislo='560726/0826';
INSERT INTO Brnensti 
   VALUES ('560726/0111','Josef Nov·k','Vinohradsk· 5','Praha');
ROLLBACK;

-- ProjektivnÌ pohled - bez PK
CREATE OR REPLACE VIEW Brnensti1 AS
   SELECT jmeno, ulice FROM Klient WHERE mesto='Brno';

SELECT column_name FROM USER_UPDATABLE_COLUMNS WHERE TABLE_NAME='BRNENSTI1';

SELECT * FROM Brnensti1;
INSERT INTO Brnensti1
   VALUES ('Josef Vlk','KoliötÏ 55');

-- ProjektivnÌ pohled - s PK, sloupce mimo pohled dovolujÌ NULL
CREATE VIEW Brnensti2 AS
   SELECT r_cislo,jmeno FROM Klient WHERE mesto='Brno';
SELECT * FROM Brnensti2;
INSERT INTO Brnensti2
   VALUES ('112233/4444','Josef Vlk');

-- NenÌ vidÏt, protoûe mesto je NULL a nenÌ WIH CHECK OPTION
SELECT jmeno, mesto FROM Klient;

-- zruseni, nutno z bazove tabulky, protoze mesto je NULL
DELETE FROM Brnensti2 WHERE r_cislo='112233/4444';
DELETE FROM Klient WHERE r_cislo='112233/4444';

CREATE OR REPLACE VIEW Brnensti2a AS
   SELECT r_cislo,jmeno FROM Klient WHERE mesto='Brno'
   WITH CHECK OPTION;
SELECT * FROM Brnensti2a;
INSERT INTO Brnensti2a
   VALUES ('112233/4445','Josef Vlk');

-- AgregaËnÌ
CREATE OR REPLACE VIEW Pocty (nazev, pocet) AS
   SELECT pobocka, COUNT(*) FROM Ucet GROUP BY pobocka;
SELECT * FROM Pocty;
INSERT INTO Pocty
   VALUES ('Pansk·',20);

-- materializovany pohled s obnovou po COMMIT nad zdrojovou tabulku (master) (Oracle)
CREATE MATERIALIZED VIEW MBrnensti 
REFRESH ON COMMIT AS
   SELECT* FROM Klient WHERE mesto='Brno';
   
CREATE VIEW Brnensti AS
   SELECT* FROM Klient WHERE mesto='Brno';

SELECT r_cislo, jmeno FROM Klient WHERE mesto='Brno';
SELECT r_cislo, jmeno FROM MBrnensti;
SELECT r_cislo, jmeno FROM Brnensti;

-- Operace nad zdrojovou tabulkou (master)
DELETE FROM Klient WHERE r_cislo='510230/048';

INSERT INTO Klient
VALUES('580214/523','Jan Vorel','Jungmannova 18','Brno');

COMMIT;
-- Nelegalni operace na materializovatelnem pohledu
-- Lze ale (klauzulÌ FOR UPDATE p¯Ìkazu CREATE MATERIALIZED VIEW) umoûnit aktualizaci
DELETE FROM MBrnensti WHERE r_cislo = '580214/523';

COMMIT;

SELECT * FROM Klient;
SELECT * FROM MBrnensti;

-- Obnova po COMMIT
INSERT INTO Klient
VALUES('510230/048','Pavel Tomek','Tomkova 34','Brno');
DELETE FROM Klient WHERE r_cislo='580214/523';

DROP VIEW  Janska;
DROP VIEW Brnensti;
DROP VIEW Brnensti1;
DROP VIEW Brnensti2;
DROP VIEW Brnensti2a;
DROP VIEW Pocty;
DROP VIEW Pocty1;
DROP MATERIALIZED VIEW MBrnensti;

--Oracle
SELECT view_name FROM User_views;
SELECT mview_name FROM User_mviews;

COMMIT;