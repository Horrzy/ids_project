SELECT table_name FROM TABS;

-- zruseni tabulek
DROP TABLE Zamestnanec;
DROP TABLE Oddeleni;
-------------------------------------------------------------------------------
-- takto tabulky nelze vytvorit kvuli referencnimu cyklu
CREATE TABLE Zamestnanec (
os_c INTEGER,
jmeno VARCHAR(40),
odd_c INTEGER,
PRIMARY KEY(os_c),
FOREIGN KEY(odd_c) REFERENCES Oddeleni
);

CREATE TABLE Oddeleni (
odd_c INTEGER,
nazev VARCHAR(20),
os_c INTEGER,
PRIMARY KEY (odd_c),	// vedoucí oddìlení
FOREIGN KEY (os_c) REFERENCES Zamestnanec
);
-------------------------------------------------------------------------------
-- je treba referencni cyklus uzavrit az po vytvoreni tabulek,
-- nejlepe pridat vsechna omezeni typu FOREIGN KEY pomoci ALTER TABLE
CREATE TABLE Zamestnanec (
os_c INTEGER,
jmeno VARCHAR(40),
odd_c INTEGER,
PRIMARY KEY(os_c)
);

CREATE TABLE Oddeleni (
odd_c INTEGER,
nazev VARCHAR(20),
os_c INTEGER,
PRIMARY KEY (odd_c)
); 

ALTER TABLE Zamestnanec 
ADD CONSTRAINT FK_odd_c FOREIGN KEY (odd_c) REFERENCES Oddeleni;

ALTER TABLE Oddeleni 
ADD CONSTRAINT FK_os_c FOREIGN KEY (os_c) REFERENCES Zamestnanec;
-------------------------------------------------------------------------------
-- zruseni tabulek. Opet vadi, kdyz se na rusenou tabulku odkazuje nejaka
-- jina
DROP TABLE Zamestnanec;
DROP TABLE Oddeleni;
ALTER TABLE Zamestnanec DROP CONSTRAINT FK_odd_c; 
-------------------------------------------------------------------------------
-- klauzule CASCADE CONSTRAINTS zrusi omezeni, ktera se odkazuji na 
-- rusenou tabulku
DROP TABLE Zamestnanec CASCADE CONSTRAINTS;

-- u sebereferujici tabulky problem neni
CREATE TABLE Zamestnanec (
osCislo INTEGER,
jmeno VARCHAR(40),
nadrizeny INTEGER,
PRIMARY KEY(osCislo),
FOREIGN KEY(nadrizeny) REFERENCES Zamestnanec
);


