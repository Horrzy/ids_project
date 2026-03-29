-- Skript s priklady na prikaz SELECT, predpoklada 
-- vytvorenou a naplnenou databazi
--
SELECT * FROM Klient;
SELECT * FROM Ucet;
SELECT * FROM Pobocka;
SELECT * FROM Transakce;

-- Kteøí klienti mají úèet u spoøitelny?
SELECT * 
FROM Klient;

-- Z kterých mìst jsou klienti spoøitelny?
SELECT DISTINCT mesto
FROM Klient;

SELECT mesto
FROM Klient;

-- Které úèty jsou u poboèky Jánská?
SELECT *
FROM Ucet
WHERE pobocka = 'Jánská';

-- Kolik èiní jmìní poboèek v USD pri kurzu 25 Kè/$?
SELECT nazev, jmeni/25 
FROM Pobocka;

-- Sloupec lze pojmenovat
SELECT nazev, jmeni/25 AS jmeni_v_$ 
FROM Pobocka;

-- nebo
SELECT nazev, jmeni/25 jmeni_v_$ 
FROM Pobocka;

SELECT nazev, ' Jmìní v USD =' AS jmeni_v_$, jmeni/25 
FROM Pobocka;

-- Uspoøádání pomocí ORDER BY
SELECT nazev, jmeni/25 AS jmeni_v_$ 
FROM Pobocka 
ORDER BY nazev;

SELECT nazev, jmeni/25 AS jmeni_v_$ 
FROM Pobocka 
ORDER BY nazev DESC;

SELECT nazev, jmeni/25 AS jmeni_v_$ 
FROM Pobocka 
ORDER BY jmeni_v_$;

SELECT nazev, jmeni/25 AS jmeni_v_$ 
FROM Pobocka 
ORDER BY 2 DESC;

-- Kteøí klienti mají úèet v poboèce Jánská
SELECT r_cislo,jmeno FROM Klient;
SELECT * FROM Ucet;

SELECT DISTINCT K.*
FROM Klient K, Ucet U
WHERE K.r_cislo=U.r_cislo AND pobocka='Jánská';

-- Kteøí klienti provádìli transakce v poboèce Jánská 12.10.1998?
SELECT r_cislo,jmeno FROM Klient;
SELECT * FROM Ucet;
SELECT * FROM Transakce;

SELECT K.r_cislo, K.jmeno, T.c_uctu, castka
FROM Klient K, Ucet U, Transakce T
WHERE K.r_cislo=U.r_cislo AND U.c_uctu=T.c_uctu 
            AND pobocka='Jánská' AND datum=TO_DATE('1998-10-12','YYYY-MM-DD')
ORDER BY K.r_cislo;

-- Kteøí klienti provádìli transakce v poboèce Jánská 12.10.1998? JOIN
SELECT r_cislo,jmeno FROM Klient;
SELECT * FROM Ucet;
SELECT * FROM Transakce;

SELECT r_cislo, jmeno, c_uctu, castka
FROM Klient NATURAL JOIN Ucet NATURAL JOIN Transakce
WHERE pobocka='Jánská' AND datum=TO_DATE('1998-10-12','YYYY-MM-DD')
ORDER BY r_cislo;

-- Pozor na chybu násobného použití NATURAL JOIN ve verzích < 11.2
-- Øešení:
SELECT r_cislo, jmeno, c_uctu, castka
FROM Klient JOIN Ucet USING (r_cislo) JOIN Transakce USING (c_uctu)
WHERE pobocka='Jánská' AND datum=TO_DATE('1998-10-12','YYYY-MM-DD')
ORDER BY r_cislo;

-- Bydlí nìkteøí klienti ve stejném domì?
SELECT r_cislo, ulice, mesto FROM Klient;

SELECT K1.jmeno,K1.r_cislo, K2.jmeno, K2.r_cislo, K1.ulice, K1.mesto
FROM Klient K1, Klient K2
WHERE K1.mesto=K2.mesto AND K1.ulice=K2.ulice AND K1.r_cislo>K2.r_cislo;

SELECT K1.jmeno,K1.r_cislo, K2.jmeno, K2.r_cislo, K1.ulice, K1.mesto
FROM Klient K1, Klient K2
WHERE K1.mesto=K2.mesto AND K1.ulice=K2.ulice;

SELECT K1.jmeno,K1.r_cislo, K2.jmeno, K2.r_cislo, K1.ulice, K1.mesto
FROM Klient K1, Klient K2
WHERE K1.mesto=K2.mesto AND K1.ulice=K2.ulice AND K1.r_cislo<>K2.r_cislo;

SELECT K1.jmeno,K1.r_cislo,K2.jmeno,K2.r_cislo,ulice,mesto
FROM Klient K1 JOIN Klient K2 USING (mesto,ulice)
WHERE K1.r_cislo>K2.r_cislo;

SELECT K1.jmeno,K1.r_cislo,K2.jmeno,K2.r_cislo,K1.ulice,K1.mesto
FROM Klient K1 JOIN Klient K2 ON K1.mesto=K2.mesto AND K1.ulice=K2.ulice
AND K1.r_cislo>K2.r_cislo;

-- Kolik klientù má spoøitelna?
SELECT r_cislo,jmeno from Klient;

SELECT COUNT(*) AS pocet
FROM Klient;


-- Jaký byl maximální vklad?
SELECT * FROM Transakce;

SELECT MAX(castka) AS max_vklad
FROM Transakce;

-- Neni GROUP BY, bere se jako jedna skupina, 
-- tj. nelze kombinovat skupinové/agregaèní a neskupinové

SELECT MAX(castka) AS max_vklad, AVG (castka) AS prumer
FROM Transakce;

SELECT c_uctu, MAX(castka) AS max_vklad
FROM Transakce;

SELECT * FROM Ucet;

-- Jaká èástka je na úètech v jednotlivých poboèkách
SELECT pobocka, SUM(stav) AS celkem_na_uctech
FROM Ucet
GROUP BY pobocka;

--Kolik mají úètù a na nich penìz jednotliví klienti?
SELECT * FROM Ucet;

SELECT jmeno, r_cislo, COUNT(*) AS pocet, SUM(stav) AS celkem
FROM Klient NATURAL JOIN Ucet
GROUP BY jmeno,r_cislo;

-- Chyba neuvedení jména v GROUP BY, má-li být výstupem (je v klauzuli SELECT)
SELECT jmeno, r_cislo, COUNT(*) AS pocet,SUM(stav) AS celkem
FROM Klient NATURAL JOIN Ucet
GROUP BY r_cislo;


--Použití vnìjšího spojení
SELECT jmeno, r_cislo, COUNT(c_uctu) AS pocet, SUM(stav) AS celkem
FROM Klient NATURAL LEFT JOIN Ucet
GROUP BY jmeno,r_cislo
ORDER BY 4 DESC;

SELECT jmeno, r_cislo, COUNT(c_uctu) AS pocet, SUM(stav) AS celkem
FROM Klient NATURAL LEFT JOIN Ucet
GROUP BY jmeno,r_cislo
ORDER BY 4 DESC NULLS LAST;

-- Zanoøování agregaèních funkcí
--------------------------------
SELECT * FROM UCET;

-- Kolik mají jednotliví klienti prùmìrnì na úètu?
SELECT r_cislo, AVG(stav) AS "prùmìr na úètu"
FROM Ucet
GROUP BY r_cislo;

-- Chceme-li i jméno
SELECT r_cislo, jmeno, AVG(stav) "prùmìr na úètu"
FROM Ucet JOIN Klient USING(r_cislo)
GROUP BY r_cislo, jmeno;

-- nebo (použití dotazu ve FROM)
SELECT r_cislo, jmeno, prumer "prùmìr na úètu"
FROM (SELECT r_cislo, AVG(stav) prumer
      FROM Ucet
      GROUP BY r_cislo) 
      JOIN Klient USING(r_cislo);

-- max. prùmìr využitím zanoøení agregaèních funkcí(Oracle)
SELECT MAX(AVG(stav)) AS "nejvyšší prùmìr na úètu"
FROM Ucet
GROUP BY r_cislo;

-- bez zanoøení poddotaz ve FROM
SELECT MAX(prumer) AS "nejvyšší prùmìr na úètu"
FROM (SELECT (AVG(stav)) AS prumer
     FROM Ucet
     GROUP BY r_cislo);

-- tabulku poddotazu ve FROM lze pojmenovat
SELECT MAX(P.prumer) AS "nejvyšší prùmìr na úètu"
FROM (SELECT (AVG(stav)) AS prumer
     FROM Ucet
     GROUP BY r_cislo) P;

-- Chceme znát i vlastníka úètù s nejvyšším prùmìrem
-- Takto nelze
SELECT r_cislo, MAX(AVG(stav)) AS "nejvyšší prùmìr na úètu"
FROM Ucet
GROUP BY r_cislo;

SELECT * FROM UCET;

-- Využití seøazení ("Top K query")
-- Pomocí ORDER BY
-- Dle standardu (až 2008 FETCH FIRST n ROWS ONLY, 
-- 2003 pomocí funkce ROW_NUMBER()OVER (ORDER BY key ASC)
-- MySQL, PostgerSQL LIMIT
-- Oracle pseudosloupec ROWNUM
SELECT *
FROM (SELECT AVG(stav) AS prumer
      FROM Ucet
      GROUP BY r_cislo
      ORDER BY prumer DESC)
WHERE ROWNUM = 1;

-- S rodným èíslem a jménem
SELECT *
FROM (SELECT r_cislo, jmeno, prumer AS "nejvyšší prùmìr na úètu" --jmeno,
      FROM (SELECT r_cislo, AVG(stav) AS prumer
            FROM Ucet
            GROUP BY r_cislo
            ) NATURAL JOIN Klient
      ORDER BY 3 DESC)
WHERE ROWNUM = 1
;

-- Pøedchozí neøeší pøípad, kdy je nìkolik s nejvìtší hodnotou.
-- (používá HAVING a ALL - viz dále). Obecnìji lze øešit takto:
SELECT R_cislo,AVG(stav) AS prumer
FROM Ucet
GROUP BY r_cislo
HAVING AVG(stav) >= ALL
    (SELECT AVG(stav)
     FROM Ucet
     GROUP BY r_cislo)
;

-- Zmena formatu data
ALTER SESSION SET NLS_DATE_FORMAT='YYYY-MM-DD';

SELECT mesto, COUNT(*) AS pocet, SUM(castka) AS celkem
FROM Klient JOIN Ucet USING (r_cislo) JOIN Transakce USING (c_uctu)
WHERE datum >= '1998-10-11' AND datum <= '1998-10-20'
GROUP BY mesto;

SELECT mesto, COUNT(*) AS pocet, SUM(castka) AS celkem
FROM Klient JOIN Ucet USING (r_cislo) JOIN Transakce USING (c_uctu)
WHERE datum >= TO_DATE('11-10-1998','DD-MM-YYYY') AND datum <= TO_DATE('20-10-1998','DD-MM-YYYY')
GROUP BY mesto;


-- Kteøí klienti mají na svých úètech více než 50000?
SELECT jmeno, r_cislo, SUM(stav) AS celkem
FROM Klient NATURAL JOIN Ucet
GROUP BY jmeno,r_cislo;

SELECT jmeno, r_cislo, SUM(stav) AS celkem
FROM Klient NATURAL JOIN Ucet
GROUP BY jmeno,r_cislo
HAVING SUM(stav)>50000; 

-- Není-li GROUP BY, chová se jako jedna skupina, tj. tady chyba
SELECT jmeno, r_cislo, SUM(stav) AS celkem
FROM Klient NATURAL JOIN Ucet
HAVING SUM(stav)>50000; 

--Tabulka s jednou hodnotou je považována za skalární hodnotu
-- Kdo má na uctu nejvice penìz?
SELECT * FROM Ucet;

SELECT r_cislo, jmeno, stav
FROM Klient NATURAL JOIN UCET
WHERE stav=(SELECT MAX(stav) FROM Ucet);

-- SOME,ANY,ALL
-- Kteøí mimobrnìnští klienti mají na svých úètech více než brnìnští?
SELECT r_cislo,jmeno,mesto FROM Klient;
INSERT INTO Ucet
VALUES(4520111,40000,'625622/6249','Jánská');
INSERT INTO Ucet
VALUES(4520112,40000,'625622/6249','Jánská');

SELECT r_cislo,jmeno,mesto FROM Klient;
SELECT * FROM Ucet;

SELECT jmeno, r_cislo, mesto, SUM(stav) AS celkem
FROM Klient NATURAL JOIN Ucet
GROUP BY jmeno, r_cislo, mesto;

SELECT jmeno, r_cislo, mesto, SUM(stav) AS celkem
FROM Klient NATURAL JOIN Ucet
WHERE mesto <> 'Brno'
GROUP BY jmeno, r_cislo, mesto
HAVING SUM(stav)>ALL
    (SELECT SUM(stav)
    FROM Klient NATURAL JOIN Ucet
    WHERE mesto='Brno'
    GROUP BY r_cislo);

-- Sloupec použitý pro spojení v NATURAL JOIN nesmí
-- být kvalifikovaný
SELECT K.jmeno, K.r_cislo, SUM(U.stav) AS celkem
FROM Klient K NATURAL JOIN Ucet U
WHERE mesto<>'Brno'
GROUP BY jmeno,r_cislo
HAVING SUM(stav)>ALL
    (SELECT SUM(U.stav)
    FROM Klient K NATURAL JOIN Ucet U
    WHERE mesto='Brno'
    GROUP BY r_cislo);

SELECT K.jmeno, r_cislo, SUM(U.stav) AS celkem
FROM Klient K NATURAL JOIN Ucet U
WHERE mesto<>'Brno'
GROUP BY jmeno,r_cislo
HAVING SUM(stav)>ALL
    (SELECT SUM(U.stav)
    FROM Klient K NATURAL JOIN Ucet U
    WHERE mesto='Brno'
    GROUP BY r_cislo);

ROLLBACK;
-- DELETE FROM Ucet WHERE c_uctu=4520111;
-- DELETE FROM Ucet WHERE c_uctu=4520112;

-- Má nìkterý zákazník neúplnì zadanou adresu?
SELECT *
FROM Klient WHERE ulice IS NULL OR mesto IS NULL;

INSERT INTO Klient 
VALUES('491120/0423','Jiøí Novák',NULL,'Brno');

ROLLBACK;
--DELETE FROM Klient WHERE r_cislo='491120/0423';

-- Kteøí klienti nevlastní u spoøitelny žádný úèet?
--CHYBNÌ
SELECT jmeno
FROM Klient NATURAL JOIN Ucet
WHERE c_uctu IS NULL;

-- SPRÁVNÌ
SELECT jmeno
FROM Klient NATURAL LEFT JOIN Ucet
WHERE c_uctu IS NULL;

-- Které transakce  probìhly v øíjnu 1998?
INSERT INTO Transakce
VALUES (4320286, 3, TO_DATE('1998-11-1','YYYY-MM-DD'), 20000);

SELECT * FROM Transakce;

SELECT jmeno, r_cislo, c_uctu, datum, castka
FROM Klient JOIN Ucet USING (r_cislo) JOIN Transakce USING (c_uctu)
WHERE datum BETWEEN TO_DATE('1998-10-1','YYYY-MM-DD') AND TO_DATE('1998-10-31','YYYY-MM-DD');

ROLLBACK;

-- EXISTS
-- Kteøí klienti mají úèet jen u poboèky Jánská?
SELECT * FROM Ucet;

DELETE FROM Ucet WHERE c_uctu=2075752;

SELECT jmeno, c_uctu, pobocka
FROM Klient NATURAL JOIN Ucet
ORDER BY jmeno;

-- Chybnì - nekorelovaný poddotaz
SELECT DISTINCT K.*
FROM Klient K, Ucet U
WHERE K.r_cislo=U.r_cislo AND U.pobocka='Jánská' AND NOT EXISTS
    (SELECT * 
     FROM Ucet U, Klient K
     WHERE U.r_cislo=K.r_cislo AND U.pobocka<>'Jánská');

-- Správnì - korelovaný poddotaz
SELECT DISTINCT K.*
FROM Klient K, Ucet U
WHERE K.r_cislo=U.r_cislo AND U.pobocka='Jánská' AND NOT EXISTS
    (SELECT * 
     FROM Ucet U
     WHERE U.r_cislo=K.r_cislo AND U.pobocka<>'Jánská');
     
-- Kteøí klienti mají úèet u všech poboèek?
SELECT *
FROM Klient K
WHERE NOT EXISTS 
    (SELECT * FROM Pobocka P WHERE NOT EXISTS 
          (SELECT * FROM Ucet U WHERE U.r_cislo=K.r_cislo AND U.pobocka=P.nazev)
    );
   
ROLLBACK;

SELECT * FROM Transakce;

-- Kteøí klienti mají køestní jméno Jan?
SELECT jmeno FROM Klient;

SELECT *
FROM Klient
WHERE jmeno LIKE 'Jan %';

-- Kteøí klienti mají u poboèky Jánská jen jeden úèet?
INSERT INTO Ucet
VALUES(1182649,10853,'530610/4532','Jánská');

SELECT r_cislo,jmeno
FROM Klient NATURAL JOIN Ucet
WHERE Pobocka='Jánská';

SELECT K.*
FROM Klient K, Ucet U
WHERE K.r_cislo=U.r_cislo AND U.pobocka='Jánská' 
   AND (SELECT COUNT(*)
       FROM Ucet U
       WHERE K.r_cislo=U.r_cislo AND
         U.pobocka='Jánská') = 1;
-- Jiná varianta
SELECT K.*
FROM Klient K, Ucet U
WHERE K.r_cislo=U.r_cislo AND U.pobocka='Jánská' 
  AND NOT EXISTS
    (SELECT *
     FROM Ucet U1
     WHERE K.r_cislo=U1.r_cislo AND
       U1.pobocka='Jánská' AND U.c_uctu <> U1.c_uctu);

ROLLBACK;

-- Kteøí klienti jsou z Brna nebo Prahy?
SELECT *
FROM Klient
WHERE mesto IN ('Praha', 'Brno');

-- Kteøí klienti provádìli transakce v øíjnu 1998?
SELECT jmeno, r_cislo, c_uctu, datum, castka
FROM Klient JOIN Ucet USING (r_cislo) JOIN Transakce USING (c_uctu)
WHERE datum BETWEEN TO_DATE('1998-10-1','YYYY-MM-DD') 
                    AND TO_DATE('1998-10-31','YYYY-MM-DD');

SELECT DISTINCT jmeno, r_cislo
FROM Klient JOIN Ucet USING (r_cislo) JOIN Transakce USING (c_uctu)
WHERE datum BETWEEN TO_DATE('1998-10-1','YYYY-MM-DD') 
                    AND TO_DATE('1998-10-31','YYYY-MM-DD');

SELECT jmeno, r_cislo
FROM Klient
WHERE r_cislo IN
   (SELECT r_cislo FROM Ucet
    WHERE c_uctu IN
     (SELECT c_uctu  FROM Transakce
      WHERE datum BETWEEN TO_DATE('1998-10-1','YYYY-MM-DD') 
                      AND TO_DATE('1998-10-31','YYYY-MM-DD')));
SELECT * FROM Transakce;
SELECT * FROM Ucet;

-- Kteøí klienti mají u poboèky Jánská úèet nebo pùjèku?
CREATE TABLE Pujcka (
c_pujcky  INTEGER NOT NULL,
r_cislo CHAR(11) NOT NULL,
pobocka VARCHAR(20),
castka DECIMAL(7,2),
splaceno DECIMAL(7,2),
PRIMARY KEY (c_pujcky),
FOREIGN KEY (r_cislo) REFERENCES Klient ON DELETE CASCADE,
FOREIGN KEY (pobocka) REFERENCES Pobocka
); 

INSERT INTO Pujcka
VALUES(111111,'580807/9638','Jánská',60000,10000);

SELECT jmeno, r_cislo, c_uctu, pobocka FROM Klient NATURAL JOIN Ucet WHERE pobocka='Jánská';
SELECT jmeno, r_cislo, c_pujcky, pobocka FROM Klient NATURAL JOIN Pujcka WHERE pobocka='Jánská';

-- Vlozeni dalsiho uctu (kvuli ALL)
INSERT INTO Ucet
VALUES(2348532,10000,'530610/4532','Jánská');

SELECT jmeno, r_cislo, c_uctu, pobocka FROM Klient NATURAL JOIN Ucet WHERE pobocka='Jánská';
SELECT jmeno, r_cislo, c_pujcky, pobocka FROM Klient NATURAL JOIN Pujcka WHERE pobocka='Jánská';


SELECT jmeno, r_cislo
FROM Klient NATURAL JOIN Ucet
WHERE pobocka='Jánská'
UNION
SELECT  jmeno, r_cislo
FROM Klient NATURAL JOIN Pujcka
WHERE pobocka='Jánská';

SELECT jmeno, r_cislo
FROM Klient NATURAL JOIN Ucet
WHERE pobocka='Jánská'
UNION ALL
SELECT  jmeno, r_cislo
FROM Klient NATURAL JOIN Pujcka
WHERE pobocka='Jánská';

ROLLBACK;
DROP TABLE Pujcka CASCADE CONSTRAINTS;

-- Použití pseudosloupce ROWNUM pro omezený výbìr
SELECT *
FROM Klient
WHERE ROWNUM < 5;

SELECT *
FROM Klient
WHERE ROWNUM < 5
ORDER BY jmeno;

SELECT *
FROM (SELECT * FROM Klient ORDER BY jmeno)
WHERE ROWNUM < 5;

SELECT * FROM Ucet;
SELECT * FROM Klient;
SELECT * FROM Transakce;

