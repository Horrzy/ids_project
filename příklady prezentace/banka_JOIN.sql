-- Skript s priklady na varianty spojeni, predpoklada 
-- vytvorenou a naplnenou databazi
--
SELECT * FROM Klient;
SELECT * FROM Ucet;
-- spojeni pomoci podminky ve WHERE
SELECT K.jmeno, U.c_uctu
FROM Klient K, Ucet U
WHERE K.r_cislo=U.r_cislo;

-- spojeni pomoci JOIN ON
SELECT K.jmeno, U.c_uctu
FROM Klient K JOIN Ucet U ON K.r_cislo=U.r_cislo;

SELECT *
FROM Klient K JOIN Ucet U ON K.r_cislo=U.r_cislo;

-- spojeni pomoci JOIN USING
SELECT jmeno, c_uctu
FROM Klient JOIN Ucet USING (r_cislo);

SELECT *
FROM Klient JOIN Ucet USING (r_cislo);

-- spojeni pomoci JOIN USING - sloupce v USING nesmí být kvalifikované
SELECT K.jmeno, U.c_uctu, r_cislo
FROM Klient K JOIN Ucet U USING (r_cislo);

SELECT K.jmeno, U.c_uctu
FROM Klient K JOIN Ucet U USING (K.r_cislo);

SELECT K.jmeno, U.c_uctu, K.r_cislo
FROM Klient K JOIN Ucet U USING (r_cislo);

-- spojeni pomoci JOIN USING - jen nìkteré ze stejných sloupcù použity
SELECT *
FROM Klient K1 JOIN Klient K2 USING (ulice)
WHERE K1.r_cislo>K2.r_cislo;

-- spojeni pomoci NATURAL JOIN - spoleèné sloupce nekvalifikované
SELECT jmeno, r_cislo, c_uctu
FROM Klient NATURAL JOIN Ucet;

-- nebo
SELECT K.jmeno, r_cislo, U.c_uctu
FROM Klient K NATURAL JOIN Ucet U;

SELECT *
FROM Klient NATURAL JOIN Ucet;

-- vnejsi spojeni
SELECT jmeno
FROM Klient;

SELECT jmeno, c_uctu
FROM Klient NATURAL JOIN Ucet;

SELECT jmeno, c_uctu
FROM Klient NATURAL LEFT JOIN Ucet;

SELECT jmeno, c_uctu
FROM Klient NATURAL LEFT JOIN Ucet
ORDER BY c_uctu;

SELECT jmeno, c_uctu
FROM Klient NATURAL LEFT JOIN Ucet
ORDER BY c_uctu NULLS FIRST;

-- Kteøí klienti nemají úèet
SELECT jmeno
FROM Klient NATURAL LEFT JOIN Ucet
WHERE c_uctu IS NULL;

