-- Použití uvozovek pro øešení kolize identifikátorù s rezervovanými
SELECT table_name FROM TABS;      // dotaz nad katalogem na moje tabulky

DROP TABLE "TABLE";
DROP TABLE "Table";
DROP TABLE TableA;

CREATE TABLE TABLE (    // chyba
a INTEGER);

CREATE TABLE "TABLE" (  // OK
a INTEGER);

CREATE TABLE "Table" (  // OK
a INTEGER);

CREATE TABLE TableA (  // OK
a INTEGER);

SELECT a
FROM TABLE;            // chyba

SELECT a
FROM "TABLE";         // OK

INSERT INTO "TABLE" VALUES (1);   // OK