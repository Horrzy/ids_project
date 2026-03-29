----------------------------------------------
-- IDS Projekt - 2. část
-- Téma: Ordinace praktického lékaře
-- Autoři: xlogin01, xlogin02  (DOPLNIT!)
-- Datum: 2026-03-29
----------------------------------------------

-- ==========================================
-- Odstranění existujících objektů
-- (umožňuje opakované spuštění skriptu)
-- ==========================================
DROP TABLE Navsteva_Vykon CASCADE CONSTRAINTS;
DROP TABLE Navsteva_Prohlidka CASCADE CONSTRAINTS;
DROP TABLE Predpis CASCADE CONSTRAINTS;
DROP TABLE Externi_vysetreni CASCADE CONSTRAINTS;
DROP TABLE Ockovani CASCADE CONSTRAINTS;
DROP TABLE Navsteva CASCADE CONSTRAINTS;
DROP TABLE Pacient CASCADE CONSTRAINTS;
DROP TABLE Pojistovna CASCADE CONSTRAINTS;
DROP TABLE Vykon CASCADE CONSTRAINTS;
DROP TABLE Lek CASCADE CONSTRAINTS;
DROP TABLE Typ_ockovani CASCADE CONSTRAINTS;
DROP TABLE Pravidelna_prohlidka CASCADE CONSTRAINTS;

DROP SEQUENCE seq_navsteva_id;
DROP SEQUENCE seq_ext_vysetreni_id;

-- ==========================================
-- Sekvence pro automatické generování PK
-- ==========================================
CREATE SEQUENCE seq_navsteva_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_ext_vysetreni_id START WITH 1 INCREMENT BY 1;

-- ==========================================
-- Vytvoření tabulek
-- ==========================================

-- Pojišťovna
CREATE TABLE Pojistovna (
    cislo_pojistovny NUMBER NOT NULL,
    nazev VARCHAR2(100) NOT NULL,
    adresa VARCHAR2(200) NOT NULL,
    CONSTRAINT pk_pojistovna PRIMARY KEY (cislo_pojistovny),
    CONSTRAINT chk_cislo_pojistovny CHECK (cislo_pojistovny BETWEEN 100 AND 999)
);

/*
 * Generalizace/Specializace: Pacient -> Registrovaný / Akutní
 *
 * Zvolený způsob převodu: Sloučení podtříd do jedné tabulky nadtřídy.
 *
 * Entita "Akutní" nemá žádné vlastní atributy, entita "Registrovaný" má pouze
 * atribut "Číslo karty". Proto je nejvhodnější sloučit obě podtřídy do nadřazené
 * tabulky "Pacient" s přidáním:
 *   - diskriminátoru "typ_pacienta" určujícího typ (registrovany/akutni)
 *   - sloupce "cislo_karty" (povinný pro registrované, NULL pro akutní)
 *
 * Konzistence je zajištěna CHECK omezením. Tento přístup minimalizuje počet
 * tabulek a JOINů a je vhodný, protože Akutní nemá žádné vlastní atributy.
 */
CREATE TABLE Pacient (
    cislo_pacienta NUMBER NOT NULL,
    rodne_cislo VARCHAR2(11) NOT NULL,
    jmeno VARCHAR2(50) NOT NULL,
    prijmeni VARCHAR2(50) NOT NULL,
    telefon VARCHAR2(20),
    datum_narozeni DATE NOT NULL,
    adresa VARCHAR2(200),
    typ_pacienta VARCHAR2(20) NOT NULL,
    cislo_karty VARCHAR2(20),
    cislo_pojistovny NUMBER NOT NULL,
    CONSTRAINT pk_pacient PRIMARY KEY (cislo_pacienta),
    CONSTRAINT uq_rodne_cislo UNIQUE (rodne_cislo),
    CONSTRAINT fk_pacient_pojistovna FOREIGN KEY (cislo_pojistovny)
        REFERENCES Pojistovna(cislo_pojistovny),
    -- Speciální omezení hodnot: Rodné číslo (RČ)
    -- Formát: YYMMDD/XXX nebo YYMMDD/XXXX
    -- MM = 01-12 pro muže, 51-62 pro ženy (přičtení 50)
    CONSTRAINT chk_rodne_cislo CHECK (
        REGEXP_LIKE(rodne_cislo,
            '^\d{2}(0[1-9]|1[0-2]|5[1-9]|6[0-2])(0[1-9]|[12]\d|3[01])/?\d{3,4}$')
    ),
    CONSTRAINT chk_typ_pacienta CHECK (typ_pacienta IN ('registrovany', 'akutni')),
    -- Registrovaný pacient musí mít číslo karty, akutní nesmí
    CONSTRAINT chk_cislo_karty CHECK (
        (typ_pacienta = 'registrovany' AND cislo_karty IS NOT NULL) OR
        (typ_pacienta = 'akutni' AND cislo_karty IS NULL)
    )
);

-- Návštěva
-- Automatické generování PK ze sekvence (viz trigger níže)
CREATE TABLE Navsteva (
    cislo_navstevy NUMBER DEFAULT NULL,
    datum_cas TIMESTAMP NOT NULL,
    typ_navstevy VARCHAR2(50) NOT NULL,
    cislo_pacienta NUMBER NOT NULL,
    CONSTRAINT pk_navsteva PRIMARY KEY (cislo_navstevy),
    CONSTRAINT fk_navsteva_pacient FOREIGN KEY (cislo_pacienta)
        REFERENCES Pacient(cislo_pacienta),
    CONSTRAINT chk_typ_navstevy CHECK (typ_navstevy IN ('planovana', 'akutni'))
);

-- Trigger: automatické generování PK pro Návštěvu ze sekvence
-- Pokud je při INSERTu hodnota cislo_navstevy NULL, doplní se z SEQUENCE.
CREATE OR REPLACE TRIGGER trg_navsteva_pk
BEFORE INSERT ON Navsteva
FOR EACH ROW
BEGIN
    IF :NEW.cislo_navstevy IS NULL THEN
        :NEW.cislo_navstevy := seq_navsteva_id.NEXTVAL;
    END IF;
END;
/

-- Výkon
CREATE TABLE Vykon (
    typ_vykonu NUMBER NOT NULL,
    nazev VARCHAR2(100) NOT NULL,
    popis VARCHAR2(500),
    CONSTRAINT pk_vykon PRIMARY KEY (typ_vykonu)
);

-- Vazební tabulka: Návštěva <-> Výkon (M:N)
CREATE TABLE Navsteva_Vykon (
    cislo_navstevy NUMBER NOT NULL,
    typ_vykonu NUMBER NOT NULL,
    CONSTRAINT pk_navsteva_vykon PRIMARY KEY (cislo_navstevy, typ_vykonu),
    CONSTRAINT fk_nv_navsteva FOREIGN KEY (cislo_navstevy)
        REFERENCES Navsteva(cislo_navstevy),
    CONSTRAINT fk_nv_vykon FOREIGN KEY (typ_vykonu)
        REFERENCES Vykon(typ_vykonu)
);

-- Lék
CREATE TABLE Lek (
    cislo_leku NUMBER NOT NULL,
    nazev VARCHAR2(100) NOT NULL,
    popis VARCHAR2(500),
    CONSTRAINT pk_lek PRIMARY KEY (cislo_leku)
);

-- Předpis (FK na Návštěvu i Lék)
CREATE TABLE Predpis (
    cislo_predpisu NUMBER NOT NULL,
    datum_vystaveni DATE NOT NULL,
    davkovani VARCHAR2(200) NOT NULL,
    cislo_navstevy NUMBER NOT NULL,
    cislo_leku NUMBER NOT NULL,
    CONSTRAINT pk_predpis PRIMARY KEY (cislo_predpisu),
    CONSTRAINT fk_predpis_navsteva FOREIGN KEY (cislo_navstevy)
        REFERENCES Navsteva(cislo_navstevy),
    CONSTRAINT fk_predpis_lek FOREIGN KEY (cislo_leku)
        REFERENCES Lek(cislo_leku)
);

-- Externí vyšetření
-- Automatické generování PK ze sekvence (viz trigger níže)
CREATE TABLE Externi_vysetreni (
    id_ext_vysetreni NUMBER DEFAULT NULL,
    nazev VARCHAR2(100) NOT NULL,
    popis VARCHAR2(500),
    pracoviste VARCHAR2(200) NOT NULL,
    cislo_navstevy NUMBER NOT NULL,
    cislo_pacienta NUMBER NOT NULL,
    CONSTRAINT pk_ext_vysetreni PRIMARY KEY (id_ext_vysetreni),
    CONSTRAINT fk_ev_navsteva FOREIGN KEY (cislo_navstevy)
        REFERENCES Navsteva(cislo_navstevy),
    CONSTRAINT fk_ev_pacient FOREIGN KEY (cislo_pacienta)
        REFERENCES Pacient(cislo_pacienta)
);

CREATE OR REPLACE TRIGGER trg_ext_vysetreni_pk
BEFORE INSERT ON Externi_vysetreni
FOR EACH ROW
BEGIN
    IF :NEW.id_ext_vysetreni IS NULL THEN
        :NEW.id_ext_vysetreni := seq_ext_vysetreni_id.NEXTVAL;
    END IF;
END;
/

-- Pravidelná prohlídka
CREATE TABLE Pravidelna_prohlidka (
    typ_prohlidky NUMBER NOT NULL,
    nazev VARCHAR2(100) NOT NULL,
    popis VARCHAR2(500),
    doba_frekvence NUMBER NOT NULL, -- frekvence v měsících
    CONSTRAINT pk_prav_prohlidka PRIMARY KEY (typ_prohlidky)
);

-- Vazební tabulka: Návštěva <-> Pravidelná prohlídka (M:N)
CREATE TABLE Navsteva_Prohlidka (
    cislo_navstevy NUMBER NOT NULL,
    typ_prohlidky NUMBER NOT NULL,
    CONSTRAINT pk_navsteva_prohlidka PRIMARY KEY (cislo_navstevy, typ_prohlidky),
    CONSTRAINT fk_np_navsteva FOREIGN KEY (cislo_navstevy)
        REFERENCES Navsteva(cislo_navstevy),
    CONSTRAINT fk_np_prohlidka FOREIGN KEY (typ_prohlidky)
        REFERENCES Pravidelna_prohlidka(typ_prohlidky)
);

-- Typ očkování
CREATE TABLE Typ_ockovani (
    typ_ockovani NUMBER NOT NULL,
    nazev VARCHAR2(100) NOT NULL,
    popis VARCHAR2(500),
    doba_ucinnosti NUMBER, -- v měsících
    CONSTRAINT pk_typ_ockovani PRIMARY KEY (typ_ockovani)
);

-- Očkování
CREATE TABLE Ockovani (
    id_ockovani NUMBER NOT NULL,
    datum_ockovani DATE NOT NULL,
    popis VARCHAR2(500),
    typ_ockovani NUMBER NOT NULL,
    cislo_navstevy NUMBER,
    CONSTRAINT pk_ockovani PRIMARY KEY (id_ockovani),
    CONSTRAINT fk_ock_typ FOREIGN KEY (typ_ockovani)
        REFERENCES Typ_ockovani(typ_ockovani),
    CONSTRAINT fk_ock_navsteva FOREIGN KEY (cislo_navstevy)
        REFERENCES Navsteva(cislo_navstevy)
);

-- ==========================================
-- Vložení ukázkových dat
-- ==========================================

-- Pojišťovny
INSERT INTO Pojistovna VALUES (111, 'Všeobecná zdravotní pojišťovna', 'Orlická 4/2020, 130 00 Praha 3');
INSERT INTO Pojistovna VALUES (201, 'Vojenská zdravotní pojišťovna', 'Drahobejlova 1404/4, 190 03 Praha 9');
INSERT INTO Pojistovna VALUES (207, 'Oborová zdravotní pojišťovna', 'Roškotova 1225/1, 140 00 Praha 4');

-- Pacienti (registrovaní i akutní)
INSERT INTO Pacient VALUES (1, '850612/1234', 'Jan', 'Novák', '+420123456789',
    TO_DATE('1985-06-12', 'YYYY-MM-DD'), 'Brněnská 15, 602 00 Brno',
    'registrovany', 'K001', 111);
INSERT INTO Pacient VALUES (2, '905215/4321', 'Marie', 'Svobodová', '+420987654321',
    TO_DATE('1990-02-15', 'YYYY-MM-DD'), 'Masarykova 8, 602 00 Brno',
    'registrovany', 'K002', 207);
INSERT INTO Pacient VALUES (3, '750101/1111', 'Petr', 'Dvořák', '+420111222333',
    TO_DATE('1975-01-01', 'YYYY-MM-DD'), 'Koliště 3, 601 00 Brno',
    'registrovany', 'K003', 201);
INSERT INTO Pacient VALUES (4, '000305/5678', 'Tomáš', 'Procházka', '+420555666777',
    TO_DATE('2000-03-05', 'YYYY-MM-DD'), 'Úvoz 10, 602 00 Brno',
    'akutni', NULL, 111);

-- Návštěvy (cislo_navstevy = NULL → generováno triggerem ze sekvence)
INSERT INTO Navsteva (cislo_navstevy, datum_cas, typ_navstevy, cislo_pacienta)
    VALUES (NULL, TO_TIMESTAMP('2024-01-15 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'planovana', 1);
INSERT INTO Navsteva (cislo_navstevy, datum_cas, typ_navstevy, cislo_pacienta)
    VALUES (NULL, TO_TIMESTAMP('2024-01-15 10:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'planovana', 2);
INSERT INTO Navsteva (cislo_navstevy, datum_cas, typ_navstevy, cislo_pacienta)
    VALUES (NULL, TO_TIMESTAMP('2024-01-16 08:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'akutni', 4);
INSERT INTO Navsteva (cislo_navstevy, datum_cas, typ_navstevy, cislo_pacienta)
    VALUES (NULL, TO_TIMESTAMP('2024-02-01 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'planovana', 3);

-- Výkony
INSERT INTO Vykon VALUES (1, 'Měření krevního tlaku', 'Standardní měření TK na paži');
INSERT INTO Vykon VALUES (2, 'Odběr krve', 'Odběr venózní krve pro laboratorní vyšetření');
INSERT INTO Vykon VALUES (3, 'EKG', 'Elektrokardiografie - vyšetření srdeční činnosti');
INSERT INTO Vykon VALUES (4, 'Aplikace injekce', 'Intramuskulární nebo subkutánní aplikace');

-- Vazba Návštěva–Výkon
INSERT INTO Navsteva_Vykon VALUES (1, 1);
INSERT INTO Navsteva_Vykon VALUES (1, 2);
INSERT INTO Navsteva_Vykon VALUES (2, 1);
INSERT INTO Navsteva_Vykon VALUES (2, 3);
INSERT INTO Navsteva_Vykon VALUES (3, 1);
INSERT INTO Navsteva_Vykon VALUES (4, 2);
INSERT INTO Navsteva_Vykon VALUES (4, 4);

-- Léky
INSERT INTO Lek VALUES (1, 'Ibuprofen 400mg', 'Nesteroidní protizánětlivý lék');
INSERT INTO Lek VALUES (2, 'Amoxicilin 500mg', 'Antibiotikum ze skupiny penicilinů');
INSERT INTO Lek VALUES (3, 'Paralen 500mg', 'Analgetikum a antipyretikum');

-- Předpisy
INSERT INTO Predpis VALUES (1, TO_DATE('2024-01-15', 'YYYY-MM-DD'), '1 tableta 3x denně po jídle', 1, 1);
INSERT INTO Predpis VALUES (2, TO_DATE('2024-01-15', 'YYYY-MM-DD'), '1 tableta 2x denně, 7 dní', 2, 2);
INSERT INTO Predpis VALUES (3, TO_DATE('2024-01-16', 'YYYY-MM-DD'), '1-2 tablety při bolesti, max 4x denně', 3, 3);

-- Externí vyšetření (id = NULL → generováno triggerem)
INSERT INTO Externi_vysetreni (id_ext_vysetreni, nazev, popis, pracoviste, cislo_navstevy, cislo_pacienta)
    VALUES (NULL, 'RTG hrudníku', 'Rentgenové vyšetření plic', 'Radiologická klinika FN Brno', 1, 1);
INSERT INTO Externi_vysetreni (id_ext_vysetreni, nazev, popis, pracoviste, cislo_navstevy, cislo_pacienta)
    VALUES (NULL, 'Ultrazvuk břicha', 'Sonografie orgánů břišní dutiny', 'Interní klinika FN Brno', 2, 2);

-- Pravidelné prohlídky
INSERT INTO Pravidelna_prohlidka VALUES (1, 'Preventivní prohlídka', 'Komplexní preventivní prohlídka dospělého', 24);
INSERT INTO Pravidelna_prohlidka VALUES (2, 'Prohlídka diabetika', 'Pravidelná kontrola pacienta s diabetem', 3);
INSERT INTO Pravidelna_prohlidka VALUES (3, 'Kardiovaskulární prohlídka', 'Kontrola TK a kardiovaskulárních rizik', 6);

-- Vazba Návštěva–Prohlídka
INSERT INTO Navsteva_Prohlidka VALUES (1, 1);
INSERT INTO Navsteva_Prohlidka VALUES (4, 2);
INSERT INTO Navsteva_Prohlidka VALUES (4, 3);

-- Typy očkování
INSERT INTO Typ_ockovani VALUES (1, 'Chřipka', 'Sezónní očkování proti chřipce', 12);
INSERT INTO Typ_ockovani VALUES (2, 'Tetanus', 'Očkování proti tetanu', 120);
INSERT INTO Typ_ockovani VALUES (3, 'COVID-19', 'Očkování proti onemocnění COVID-19', 6);

-- Očkování
INSERT INTO Ockovani VALUES (1, TO_DATE('2024-01-15', 'YYYY-MM-DD'), 'Sezónní vakcína 2024', 1, 1);
INSERT INTO Ockovani VALUES (2, TO_DATE('2024-02-01', 'YYYY-MM-DD'), 'Přeočkování tetanu', 2, 4);

-- Ověření: výpis počtu záznamů v tabulkách
SELECT 'Pojistovna' AS tabulka, COUNT(*) AS pocet FROM Pojistovna
UNION ALL SELECT 'Pacient', COUNT(*) FROM Pacient
UNION ALL SELECT 'Navsteva', COUNT(*) FROM Navsteva
UNION ALL SELECT 'Vykon', COUNT(*) FROM Vykon
UNION ALL SELECT 'Navsteva_Vykon', COUNT(*) FROM Navsteva_Vykon
UNION ALL SELECT 'Lek', COUNT(*) FROM Lek
UNION ALL SELECT 'Predpis', COUNT(*) FROM Predpis
UNION ALL SELECT 'Externi_vysetreni', COUNT(*) FROM Externi_vysetreni
UNION ALL SELECT 'Pravidelna_prohlidka', COUNT(*) FROM Pravidelna_prohlidka
UNION ALL SELECT 'Navsteva_Prohlidka', COUNT(*) FROM Navsteva_Prohlidka
UNION ALL SELECT 'Typ_ockovani', COUNT(*) FROM Typ_ockovani
UNION ALL SELECT 'Ockovani', COUNT(*) FROM Ockovani;
