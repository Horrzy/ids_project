-- Skript s ukazkami pouzitymi pri vykladu prikazu DDL SQL
-- CREATE TABLE, ALTER TABLE, DROP TABLE, CREATE SYNONYM, 
-- CREATE SEQUENCE
--
SELECT table_name
FROM TABS;

SELECT table_name
FROM USER_INDEXES;

DROP TABLE Transakce CASCADE CONSTRAINTS;
DROP TABLE Ucet CASCADE CONSTRAINTS;
DROP TABLE Pobocka CASCADE CONSTRAINTS;
DROP TABLE Klient CASCADE CONSTRAINTS;
DROP SEQUENCE seq_c_uctu;
DROP TABLE Pujcka CASCADE CONSTRAINTS;

DROP SYNONYM Klient1;
DROP USER xstudent CASCADE;
DROP ROLE studentrole;


SELECT * FROM Klient;


CREATE TABLE Klient (
r_cislo  CHAR(11),
jmeno VARCHAR(20) NOT NULL,
ulice VARCHAR(20),
mesto VARCHAR(20)
); 

CREATE TABLE Pobocka (
nazev VARCHAR(20),
jmeni INTEGER
); 

CREATE TABLE UCET (
c_uctu  INTEGER,
stav DECIMAL(10,2),
r_cislo CHAR(11) NOT NULL,
pobocka VARCHAR(20)
); 

CREATE TABLE Transakce (
c_uctu  INTEGER,
c_transakce INTEGER,
datum DATE,
castka DECIMAL(7,2)
); 

ALTER TABLE Klient ADD CONSTRAINT PK_klient PRIMARY KEY (r_cislo);
ALTER TABLE Pobocka ADD CONSTRAINT PK_pobocka PRIMARY KEY (nazev);
ALTER TABLE Ucet ADD CONSTRAINT PK_ucet PRIMARY KEY (c_uctu);
ALTER TABLE Ucet ADD CONSTRAINT FK_ucet_rcislo FOREIGN KEY (r_cislo) 
   REFERENCES Klient ON DELETE CASCADE;
ALTER TABLE Ucet ADD CONSTRAINT FK_ucet_pobocka FOREIGN KEY (pobocka) 
   REFERENCES Pobocka;
ALTER TABLE Transakce ADD CONSTRAINT PK_transakce PRIMARY KEY (c_uctu,c_transakce);
ALTER TABLE Transakce ADD CONSTRAINT FK_transakce_cuctu FOREIGN KEY (c_uctu) 
   REFERENCES Ucet ON DELETE CASCADE;

-- Pro PRIMARY KEY a UNIQUE se vytvoøí index
SELECT table_name
FROM USER_INDEXES;

INSERT INTO Klient 
VALUES('440726/0672','Jan Novák','Cejl 8','Brno');
INSERT INTO Klient
VALUES('530610/4532','Petr Veselý','Podzimní 28','Brno');
INSERT INTO Klient
VALUES('601001/2218','Ivan Zeman ','Cejl 8','Brno');
INSERT INTO Klient
VALUES('510230/048','Pavel Tomek','Tomkova 34','Brno');
INSERT INTO Klient
VALUES('580807/9638','Josef Mádr','Svatoplukova 15','Brno');
INSERT INTO Klient
VALUES('625622/6249','Jana Malá','Brnìnská 56','Vyškov');

SELECT * FROM Klient;

-- Porušení PK
INSERT INTO Klient 
VALUES('440726/0672','Jan Novák','Cejl 8','Brno');
INSERT INTO Klient (jmeno, ulice, mesto) 
VALUES('Jan Novák','Cejl 8','Brno');

INSERT INTO Pobocka
VALUES('Jánská',10000000);
INSERT INTO Pobocka
VALUES('Palackého',5000000);
SELECT * FROM Pobocka;

INSERT INTO Ucet
VALUES(4320286,52000,'440726/0672','Jánská');
INSERT INTO Ucet
VALUES(2348531,10000,'530610/4532','Jánská');
INSERT INTO Ucet
VALUES(1182648,10853,'530610/4532','Palackého');
INSERT INTO Ucet
VALUES(2075752,26350,'440726/0672','Palackého');
SELECT * FROM Ucet;

INSERT INTO Transakce
VALUES(4320286,1,TO_DATE('10.10.1998', 'dd.mm.yyyy'),3000);
INSERT INTO Transakce
VALUES(4320286,2,TO_DATE('12.10.1998', 'dd.mm.yyyy'),-5000);
INSERT INTO Transakce
VALUES(2075752,1,TO_DATE('14.10.1998', 'dd.mm.yyyy'),-2000);
INSERT INTO Transakce
VALUES(2075752,2,TO_DATE('14.10.1998', 'dd.mm.yyyy'),10000);

COMMIT;

--Vytvoøení dalšího uživatele, role a pøiøazení práv - je tøeba mít pøíslušné oprávnìní
CREATE USER xstudent IDENTIFIED BY xstudent DEFAULT TABLESPACE Users
            QUOTA 10 M ON USERS;

CREATE ROLE Studentrole;
GRANT CONNECT, RESOURCE, CREATE SESSION TO Studentrole;
GRANT Studentrole TO xstudent;
--===============================================
-- Následující pøíkazy provést po pøihlášení jako xstudent/xstudent,
-- nejlépe ve druhém oknì nebo v SQLDeveloper mít další spojení
-- k téže DB, zrušit stávající a pøipojit se jako xstudent/xstudent

--Vytvoøení tabulky Klient ve schématu xstudent
CREATE TABLE Klient (
id INTEGER,
jmeno VARCHAR (50)
);
INSERT INTO Klient VALUES(1, 'Student');
COMMIT;
SELECT * FROM Klient;
GRANT SELECT ON Klient TO zendulka;
--===============================================
-- Toto už opìt z pùvodního pøipojení
-- Pøístup k tabulce Klient v aktuálním schématu
SELECT * FROM Klient;

-- pøístup k tabulce Klient ve schématu xstudent prostøednictvím plného jména
SELECT * FROM xstudent.Klient;

-- Vytvoøení synonyma Klient1

CREATE SYNONYM Klient1 FOR xstudent.Klient;
-- Použití synonyma
SELECT * FROM Klient1;

-- Sekvence
CREATE SEQUENCE seq_c_uctu;
SELECT seq_c_uctu.nextval
FROM DUAL;
-- Použití pro vkládání øádkù
INSERT INTO Ucet
VALUES(seq_c_uctu.NEXTVAL,10000,'530610/4532','Jánská');
INSERT INTO Ucet
VALUES(seq_c_uctu.NEXTVAL,10853,'530610/4532','Palackého');


SELECT * FROM Klient;
SELECT * FROM Pobocka;
SELECT * FROM Ucet;
SELECT * FROM Transakce;

