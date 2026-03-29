-- Ukázky typických použití databázového triggeru

DROP TRIGGER Pobocka_on_update_cascade;
DROP TRIGGER Klient_datum_zmeny;
DROP TABLE Audit_ucet CASCADE CONSTRAINTS;
DROP TABLE Neautorizovane_transakce_log CASCADE CONSTRAINTS;
DROP TRIGGER Audit_ucet;


-- Implementace integritního omezení ON UPDATE CASCADE
-- pro Ucet(pobocka)
CREATE OR REPLACE TRIGGER Pobocka_on_update_cascade
	AFTER UPDATE OF nazev ON Pobocka
	FOR EACH ROW
BEGIN
	UPDATE Ucet SET pobocka = :NEW.nazev
	WHERE pobocka = :OLD.nazev;
END;
/

SELECT * FROM Pobocka;
SELECT c_uctu, pobocka FROM Ucet;

UPDATE Pobocka 
SET nazev='Jánská 20'
WHERE nazev='Jánská';

ROLLBACK;

-- Implementace složitìjšího bezpeènostního omezení
CREATE TABLE Neautorizovane_transakce_log (uzivatel VARCHAR(10), castka NUMBER, 
           datum DATE, akce VARCHAR2(20));
CREATE OR REPLACE TRIGGER Transakce_autorizovana_operace
	AFTER INSERT ON Transakce
	FOR EACH ROW
  WHEN (NEW.castka > 50000 OR NEW.castka < -50000)
DECLARE
  neautorizovana_operace EXCEPTION;
BEGIN
	IF USER() <> 'AUTHORIZED' THEN
    RAISE neautorizovana_operace;  
  END IF;
EXCEPTION
  WHEN neautorizovana_operace THEN
    INSERT INTO Neautorizovane_transakce_log 
    VALUES (USER(), :NEW.castka, SYSDATE, 
            CASE WHEN :NEW.castka>0 THEN'Vklad'
               ELSE 'Výbìr'
            END);
END;
/

SHOW ERRORS;

SELECT * FROM Transakce;
SELECT * FROM Neautorizovane_transakce_log;
INSERT INTO Transakce
VALUES(2075752,3,TO_DATE(SYSDATE, 'dd.mm.yyyy'),50001);
ROLLBACK;
 
-- Operace na pozadí
-- Pøidání sloupce datum_posledni_zmeny do tabulky Klient
-- a uložení hodnoty pomocí triggeru pøi každé zmìnì

SELECT r_cislo, jmeno
FROM Klient;

ALTER TABLE Klient ADD datum_posledni_zmeny DATE;

SELECT r_cislo, jmeno, TO_CHAR(datum_posledni_zmeny,'DD.MM.YYYY:HH24:MM:SS') datum
FROM KLient;

CREATE OR REPLACE TRIGGER Klient_datum_zmeny
	BEFORE INSERT OR UPDATE ON Klient
	FOR EACH ROW
BEGIN
	:NEW.datum_posledni_zmeny := SYSDATE;
END;
/

UPDATE Klient 
SET jmeno = 'Jana Velká'
WHERE jmeno = 'Jana Malá';

INSERT INTO Klient (r_cislo,jmeno)
VALUES('580721/2580', 'Josef Velký');

SELECT r_cislo, jmeno, TO_CHAR(datum_posledni_zmeny,'DD.MM.YYYY:HH24:MM:SS') datum
FROM KLient;

ROLLBACK;
ALTER TABLE Klient DROP COLUMN datum_posledni_zmeny;

-- Audit zmìn v databázi
-- Pøi modifikikaci obsahu tabulky Ucet vloží informaci
-- do tabulky Audit_ucet

CREATE TABLE Audit_ucet (
c_uctu_org INTEGER,
stav_org DECIMAL(10,2),
r_cislo_org CHAR(11),
pobocka_org VARCHAR(20),
c_uctu_nov INTEGER,
stav_nov DECIMAL(10,2),
r_cislo_nov CHAR(11),
pobocka_nov VARCHAR(20),
modifikoval VARCHAR(20),
cas TIMESTAMP
);

CREATE OR REPLACE TRIGGER Audit_ucet
AFTER INSERT OR DELETE OR UPDATE ON Ucet
FOR EACH ROW
BEGIN
   INSERT INTO Audit_ucet VALUES
     (:OLD.c_uctu, :OLD.stav, :OLD.r_cislo, :OLD.pobocka,
     :NEW.c_uctu, :NEW.stav, :NEW.r_cislo, :NEW.pobocka,
     USER, SYSTIMESTAMP);
END;
/

SELECT c_uctu, stav
FROM Ucet;

UPDATE Ucet
SET stav=stav-1000
WHERE c_uctu=2075752;
UPDATE Ucet
SET stav=stav+1000
WHERE c_uctu=4320286;


SELECT c_uctu_org,stav_org,stav_nov,modifikoval,TO_CHAR(cas,'DD.MM.YYYY HH24:MM:SS') cas
FROM Audit_ucet;

ROLLBACK;

