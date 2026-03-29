DROP TABLE Zbozi;
DROP TABLE Ceny2013;

SELECT * FROM Klient;
SELECT * FROM Ucet;
SELECT * FROM Transakce;


-- Kteøí klienti provádìli transakce v øíjnu 1998?
SELECT r_cislo,jmeno FROM Klient;
SELECT * FROM Ucet;
SELECT * FROM Transakce;

INSERT INTO Transakce
VALUES(4320286,3,TO_DATE('11.10.1998', 'dd.mm.yyyy'),30000);
INSERT INTO Transakce
VALUES(4320286,4,TO_DATE('20.10.1998', 'dd.mm.yyyy'),50000);

SELECT r_cislo, jmeno, c_uctu, castka
FROM (Klient JOIN Ucet USING (r_cislo)) JOIN Transakce USING (c_uctu)
WHERE TO_CHAR(datum,'MM.YYYY')='10.1998'
ORDER BY r_cislo;

-- Podmínìný výraz CASE
SELECT r_cislo, jmeno, c_uctu, CASE WHEN castka < 1000 THEN 'malá'
                                    WHEN castka BETWEEN 1000 AND 50000 THEN 'støední'
                                    WHEN castka > 50000 THEN 'velká'
                               ELSE 'neznámá'
                               END AS kategorie
FROM (Klient JOIN Ucet USING (r_cislo)) JOIN Transakce USING (c_uctu)
WHERE TO_CHAR(datum,'MM.YYYY')='10.1998'
ORDER BY kategorie;

-- Kolik bylo transakcí v jednotlivých dekádách øíjna 1998 v jednotlivých poboèkách?
-- Poèty po dekádách v jednotlivých sloupcích
SELECT pobocka, COUNT(CASE WHEN TO_CHAR(datum,'DD') < 10 THEN castka ELSE NULL END) AS D1,
       COUNT(CASE WHEN TO_CHAR(datum,'DD') BETWEEN 10 AND 19 THEN castka ELSE NULL END) AS D2,
       COUNT(CASE WHEN TO_CHAR(datum,'DD') BETWEEN 20 AND 29 THEN castka ELSE NULL END) AS D3
FROM (Klient JOIN Ucet USING (r_cislo)) JOIN Transakce USING (c_uctu)
WHERE TO_CHAR(datum,'MM.YYYY')='10.1998'
GROUP BY pobocka;

CREATE TABLE Zbozi (
   kod CHAR(10) PRIMARY KEY,
   cena_doporucena NUMERIC(10,2),
   cena_minimalni NUMERIC(10,2) NOT NULL,
   cena_akce NUMERIC(10,2)
);

INSERT INTO Zbozi
   VALUES ('A100', 150, 100, NULL);
INSERT INTO Zbozi
   VALUES ('A200', NULL, 100, NULL);
INSERT INTO Zbozi
   VALUES ('A300', 150, 100, 90);  
   
SELECT *
FROM Zbozi;
-- Výpoèet ceny pro akci - je-li zadaná, platí, jinak doporuèená,
-- není-li ani ta zadaná, pak minimální zvýšená o 10%
SELECT kod, COALESCE (cena_akce, cena_doporucena, 1.1*cena_minimalni) AS cena
FROM Zbozi;   
   
CREATE TABLE Ceny2013 (
   kod CHAR(10) PRIMARY KEY,
   cena_doporucena NUMERIC(10,2),
   cena_minimalni NUMERIC(10,2) NOT NULL
);

INSERT INTO Ceny2013
   VALUES ('A100', 150, 100);
INSERT INTO Ceny2013
   VALUES ('A200', NULL, 90);
INSERT INTO Ceny2013
   VALUES ('A300', 100, 80);  
   
SELECT kod,cena_doporucena, cena_minimalni 
FROM Zbozi;

SELECT *
FROM Ceny2013;

-- Které ceny se meziroènì zmìnily a jaká byla púvodní hodnota?
SELECT kod, NULLIF(Z.cena_doporucena, C.cena_doporucena) AS stara_cena_doporucena,
       NULLIF(Z.cena_minimalni, C.cena_minimalni) AS stara_cena_minimalni
FROM Zbozi Z JOIN Ceny2013 C USING (kod);

ROLLBACK;

