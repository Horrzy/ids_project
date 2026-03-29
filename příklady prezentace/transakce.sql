-- Skript ukazuje nìkteré vlastnosti a situace transakèního zpracování dvou
-- soubìžných transakcí. K tomu lze využít v SQL Developeru dvou rùzných pøipojení
-- (connection) vytvoøených napø. tak, že druhé vytvoøíme kopií existujícího 
-- s jiným jménem. Pro každé pøípojení a tedy potom použijeme samostatné okno editoru 
-- SQL Worksheet s tímto skriptem a v jednom budeme provádìt skupiny pøíkazù 
-- transakce uvedené ve skriptu poznámkou PRVNÍ TRANSAKCE a ve druhém skupiny
-- pøíkazù uvedené ve skriptu poznámkou DRUHÁ TRANSAKCE. Provádíme v takovém 
-- poøadí, jak jdou skupiny pøíkazù ve skriptu za sebou.
-- Alternativou mùže být analogické použití dvou instancí programu PSL Plus.

-- Skript pøedpokládá databázi "Banka" vytvoøenou skriptem banka_createDB.sql

-------------------- PRVNÍ TRANSAKCE
-- Nastavení stavù dvou úètu na 10000, resp. 20000
UPDATE Ucet SET stav=10000 WHERE c_uctu=1182648;
UPDATE Ucet SET stav=20000 WHERE c_uctu=2075752;
-- Zrušení bankovních transakcí vytvoøených tímto skriptem (inicializace 
-- pøi opakovaném spuštìní).
DELETE FROM Transakce WHERE datum>TO_DATE('14-10-1998','DD.MM.YY');

-- Výpis tabulek Úèet a Transakce
SELECT * FROM Ucet;
SELECT * FROM Transakce ORDER BY c_uctu, c_transakce DESC;

-- potvrzení zmìn
COMMIT;

-- Trigger pro uložení øádku o bankovní transakci pøi zmìnì stavu úètu
-- Není používána sekvence ani IDENTITY pro èíslo úètu, ale použije se nejvyšší, 
-- zvýšené o 1
CREATE OR REPLACE TRIGGER vloz_transakci_tr
AFTER UPDATE OF stav ON Ucet
FOR EACH ROW
DECLARE
   c_tr INTEGER; 
BEGIN  
   SELECT COALESCE (MAX(c_transakce),0)INTO c_tr FROM Transakce WHERE c_uctu=:old.c_uctu;
   INSERT INTO Transakce
      VALUES (:old.c_uctu,c_tr+1,SYSDATE,:new.stav-:old.stav);
END;
/
-- Pøevod z úètu na úèet- zahájení databázové transakce. Bude obsahovat 
-- i modifikace provedené triggerem vloz_transakci_tr
UPDATE Ucet SET stav=stav-1000 WHERE c_uctu=1182648;
UPDATE Ucet SET stav=stav+1000 WHERE c_uctu=2075752;
-- Tabulky Ucet a Transakce - PRVNÍ TRANSAKCE vidí zmìny
SELECT * FROM Ucet;
SELECT * FROM Transakce ORDER BY c_uctu, c_transakce DESC;

------------------------- DRUHÁ TRANSAKCE
-- Jiné soubìžné transakce zmìny nevidí, vidí pùvodní hodnoty.
SELECT * FROM Ucet;
SELECT * FROM Transakce ORDER BY c_uctu, c_transakce DESC;

----------------------- PRVNÍ TRANSAKCE
-- Zrušení transakce
ROLLBACK;
-- Tabulky Ucet a Transakce - byly navráceny pùvodní hodnoty.
SELECT * FROM Ucet;
SELECT * FROM Transakce ORDER BY c_uctu, c_transakce DESC;

-- Provedení transakce znovu
UPDATE Ucet SET stav=stav-1000 WHERE c_uctu=1182648;
UPDATE Ucet SET stav=stav+1000 WHERE c_uctu=2075752;

-- Potvrzení transakce
COMMIT;

--------------------------- DRUHÁ TRANSAKCE
-- Po potvrzení vidí nové hodnoty i soubìžné transakce
SELECT * FROM Ucet;
SELECT * FROM Transakce ORDER BY c_uctu, c_transakce DESC;

-------------------------- PRVNÍ TRANSAKCE
-- Lze vyzkoušet zotavení po poruše (simulováno násilným ukonèením aplikace,
-- neodpovídá restartu DB serveru, ale efekt je stejný)
SELECT * FROM Ucet;
SELECT * FROM Transakce ORDER BY c_uctu, c_transakce DESC;
-- Další modifikace
UPDATE Ucet SET stav=stav-1000 WHERE c_uctu=1182648;
UPDATE Ucet SET stav=stav+1000 WHERE c_uctu=2075752;
-- Stav se zmìnil, ale není ještì potvrzený

-- POZOR, ULOŽIT SI PØÍPADNÉ ZMÌNY SQL SKRIPTù
-- Tady násilnì SQL Developer èi SQL Plus ukonèit, znovu spustit a pokraèovat
-- z tohoto bodu
-- Výpis tabulek Ucet a Transakce neobsahuje zmìny nepotvrzené transakce
SELECT * FROM Ucet;
SELECT * FROM Transakce ORDER BY c_uctu, c_transakce DESC;

-- SAVEPOINT - možnost potvrzení jen èásti transakce. 
UPDATE Ucet SET stav=stav-2000 WHERE c_uctu=1182648;
SAVEPOINT prvni_ucet;
UPDATE Ucet SET stav=stav+2000 WHERE c_uctu=2075752;
-- Zmìny (nepotvrzené) jsou vidìt
SELECT * FROM Ucet;
SELECT * FROM Transakce ORDER BY c_uctu, c_transakce DESC;

-- Zrušení efektu druhého pøíkazu UPDATE
ROLLBACK TO SAVEPOINT prvni_ucet;
-- U druhého/cílového úètu pùvodní hodnota, zrušena i odpovídající vklad
SELECT * FROM Ucet;
SELECT * FROM Transakce ORDER BY c_uctu, c_transakce DESC;
-- Zrušení zbytku transakce
ROLLBACK;
-- Zrušena i modifikace zdrojového úètu a odpovídající výbìr.
SELECT * FROM Ucet;
SELECT * FROM Transakce ORDER BY c_uctu, c_transakce DESC;

--====================
--Soubìžný pøístup
--====================
-- Dvì soubìžné transakce ètou, nezamyká se výluèným zámkem
SELECT * FROM Ucet;
SELECT * FROM Transakce ORDER BY c_uctu, c_transakce DESC;

--------------------------- DRUHÁ TRANSAKCE
-- Také má pøístup k datùm
SELECT * FROM Ucet;
SELECT * FROM Transakce ORDER BY c_uctu, c_transakce DESC;

--------------------------- PRVNÍ TRANSAKCE
-- První transakce realizuje pøevod z úètu na úèet.
UPDATE Ucet SET stav=stav-1100 WHERE c_uctu=1182648;
UPDATE Ucet SET stav=stav+1100 WHERE c_uctu=2075752;

SELECT * FROM Ucet;
SELECT * FROM Transakce ORDER BY c_uctu, c_transakce DESC;

-------------------------------- DRUHÁ TRANSAKCE
-- Chce pøeèíst modifikovaná dat. Pokud by se používaly jen sdílené a výluèné 
-- zámky, èekala by na odemèení. Oracle ale používá tzv. konzistentní ètení, 
-- tj. druhá transakce data mùže èíst a vidí hodnoty platné v dobì jejího zahájení 
-- (používá se tzv. verzování).
SELECT * FROM Ucet;
SELECT * FROM Transakce ORDER BY c_uctu, c_transakce DESC;

-- Nyní chce druhá transakce realizovat pøevod mezi úèty, z nichž zdojový je jiný
-- a cílový jeden z modifikovaných a dosud nepotvrzených první transakcí.
-- Transakce bude èekat na odemèení první transakcí.
UPDATE Ucet SET stav=stav-3000 WHERE c_uctu=2348531;
UPDATE Ucet SET stav=stav-3000 WHERE c_uctu=1182648;

--------------------------- PRVNÍ TRANSAKCE
-- Potvrzení zmìn a uvolnìní zámkù
COMMIT;

-- DRUHÁ TRANSAKCE
-- Druhá transakce dokonèí a potvrdí.
SELECT * FROM Ucet;
SELECT * FROM Transakce;
COMMIT;
----------------------------- PRVNÍ TRANSAKCE
-- Explicitní uzamèení celé tabulky v režimu SHARE (umoznuje soubezne dotazovani, ale ne aktualizaci)
LOCK TABLE Ucet IN SHARE MODE;
SELECT * FROM Ucet;

---------------------------- DRUHÁ TRANSAKCE
-- Aktualizace rùzných uètù - èeká
UPDATE Ucet SET stav=stav-1500 WHERE c_uctu=1182648;  -- èeká
UPDATE Ucet SET stav=stav+1500 WHERE c_uctu=2075752;  -- pokraèuje
COMMIT;   -- potvrdí zmìny

---------------------------- PRVNÍ TRANSAKCE
-- Potvrzení a uvolnìní zámku
COMMIT;

---------------------------- DRUHÁ TRANSAKCE
-- Dokonèí
SELECT * FROM Ucet;
SELECT * FROM Transakce;

-- DEADLOCK
----------------------------- PRVNÍ TRANSAKCE
-- Uzamkne a modifikuje úèet U1
UPDATE Ucet SET stav=stav-1500 WHERE c_uctu=1182648;

----------------------------- DRUHÁ TRANSAKCE
-- Uzamkne výluèným zámkem a modifikuje úèet U2
UPDATE Ucet SET stav=stav-2000 WHERE c_uctu=2075752;
-- Chce uzamknout výluèným zámkem a modifikovat úèet U1 
UPDATE Ucet SET stav=stav+2000 WHERE c_uctu=1182648;  -- èeká na uvolnìní PRVNÍ

----------------------------- PRVNÍ TRANSAKCE
-- Chce uzamknout výluèným zámkem a modifikovat úèet U2
UPDATE Ucet SET stav=stav+1500 WHERE c_uctu=2075752;  -- èeká na uvolnìní DRUHOU
                                                      -- nastal DEADLOCK
------------------------------ DRUHÁ TRANSAKCE
-- Detekce deadlocku, dochází k chybì
-- Øešení - zrušením transakce
ROLLBACK;

----------------------------- PRVNÍ TRANSAKCE
-- Dokonèí a mùže potvrdit
COMMIT;