-- Optimalizace zpracování dotazu
-- Používá se ukázková databáze "Banka" využívaná pøi výkladu SQL, 
-- lze ji vytvoøit skriptem createDB.sql
-- Dále se používá databáze uživatele SCOTT, která je souèástí instalace

-- EXPLAIN PLAN
-- Zde se pøedpokládá použití nástroje SQL Developer a jeho schopnosti zobrazit
-- provádìcí plán vybraný optomalizátorem (grafická vizualizace výsledku provedení
-- pøíkazu EXPLAIN PLAN
-- Každý z následujících pøíkazù si mùžete jednak spustit (pro zobrazení plánu 
-- ale není nutné) a kliknutím na tlaèítko ve SQL Worksheet si zobrazte provádìcí plán.

DELETE FROM Ucet WHERE c_uctu=2075752; -- Úprava obsahu DB pro následující pøíkazy
COMMIT; -- Potvrzení transakce

SELECT *
FROM Ucet;

-- Jakému dotazu tento pøíkaz odpovídá?
SELECT DISTINCT K.*
FROM Klient K, Ucet U
WHERE K.r_cislo=U.r_cislo AND U.pobocka='Jánská' AND NOT EXISTS
    (SELECT * 
     FROM Ucet U
     WHERE U.r_cislo=K.r_cislo AND U.pobocka<>'Jánská');

-- Tipy (hints) u Oracle (viz pøednáška str.12)
-- Zde je použita rozsáhlejší ukázková databáze HR, která obsahuje informace o zamìstnancích, 
-- oddìleních, kde pracují, na jaké pozici, uchovávají historii pozic atd.
-- Tato ukázková databáze používaná v pøíkladech v dokumentaci Oracle ale není 
-- na školním serveru nainstalována. Proto jsem vytvoøil a naplnil tabulky 
-- ve svém schematu a práva ètení jsem udìlil uživateli PUBLIC.

SELECT employee_id, department_id
FROM zendulka.employees;

--Pø) Doporuèení použít index - optimalizátor použil (vyzkoušejte si bez doporuèení)
SELECT /*+ INDEX (employees emp_emp_id_pk)*/
employee_id, department_id
FROM zendulka.employees;

--Pø) Doporuèení použít index - zde doporuèení optimalizátor neakceptoval
SELECT /*+ INDEX (employees emp_department_ix)*/
employee_id, department_id
FROM zendulka.employees;

--Pø) Doporuèení použít implementaci spojení øádkù metodou sort-merge
SELECT /*+ USE_MERGE(employees departments) */ *
FROM zendulka.employees, zendulka.departments
WHERE employees.department_id = departments.department_id;

-- Následující èást ukazuje nìkteré ze statistik, které optomalizátor využívá 
-- pøi optimalizaci. Jsou uloženy v systémovém katalogu.
-- Vracíme se opìt k naší ukázkové databázi banky.

-- Obsah tabulky Ucet
SELECT * FROM Ucet;

-- Nìkteré z uchovávaných statistik k tabulce Ucet a jejímu sloupci stav. 
-- Po vytvoøení tabulek jsou statistiky prázdné.
SELECT UT. TABLE_NAME, UT.NUM_ROWS,UT.AVG_ROW_LEN,CS.NUM_DISTINCT,
       CS.AVG_COL_LEN,CS.LAST_ANALYZED
FROM USER_TABLES UT JOIN USER_TAB_COLUMNS CS
       ON UT.TABLE_NAME=CS.TABLE_NAME AND UT.TABLE_NAME='UCET' 
       AND CS.COLUMN_NAME='STAV';

-- Kolik øádkù v tabulce úèet je? 
SELECT COUNT(*) "pocet radku", COUNT(DISTINCT stav) "pocet ruznych hodnot"
FROM Ucet;
-- Podíváme se opìt na statistiky pøíkazem výše - nic se nezmìnilo

-- Jedna z možností, jak aktualizovat statistiky - pøíkaz ANALYZE STATISTICS
ANALYZE TABLE Ucet COMPUTE STATISTICS;

-- Podíváme se opìt na statistiky pøíkazem výše - jsou aktualizovány

-- Vložíme dva nové øádky
INSERT INTO Ucet
VALUES(1182660,10111,'530610/4532','Palackého');
INSERT INTO Ucet
VALUES(2075761,26666,'440726/0672','Palackého');
-- Potvrdíme hodnoty
COMMIT;
-- Podíváme se opìt na statistiky pøíkazem výše - nic se nezmìnilo
-- Aktualizujeme statistiky pøíkazem viz výše
-- Podíváme se opìt na statistiky pøíkazem výše - jsou aktualizované
-- Potvrdíme zmìny

-- Mùžeme vrátit pùvodní stav
DELETE FROM Ucet WHERE c_uctu=1182660;
DELETE FROM Ucet WHERE c_uctu=2075761;
COMMIT;

SELECT * FROM Ucet;


