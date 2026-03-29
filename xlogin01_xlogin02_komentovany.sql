----------------------------------------------
-- IDS Projekt - 2. část
-- Téma: Ordinace praktického lékaře
-- Autoři: xlogin01, xlogin02  (DOPLNIT!)
-- Datum: 2026-03-29
----------------------------------------------

-- ==========================================
-- KROK 1: Odstranění existujících objektů
-- ==========================================
-- Aby šlo skript spustit opakovaně, nejdřív smažeme všechny tabulky a sekvence.
-- CASCADE CONSTRAINTS = smaž tabulku i když na ni odkazují cizí klíče z jiných tabulek.
-- Při prvním spuštění tyto příkazy vyhodí chybu "table does not exist" – to je v pořádku.

DROP TABLE Navsteva_Vykon CASCADE CONSTRAINTS;       -- vazební tabulka Návštěva<->Výkon
DROP TABLE Navsteva_Prohlidka CASCADE CONSTRAINTS;   -- vazební tabulka Návštěva<->Prohlídka
DROP TABLE Predpis CASCADE CONSTRAINTS;              -- předpisy léků
DROP TABLE Externi_vysetreni CASCADE CONSTRAINTS;    -- externí vyšetření
DROP TABLE Ockovani CASCADE CONSTRAINTS;             -- očkování
DROP TABLE Navsteva CASCADE CONSTRAINTS;             -- návštěvy
DROP TABLE Pacient CASCADE CONSTRAINTS;              -- pacienti
DROP TABLE Pojistovna CASCADE CONSTRAINTS;           -- pojišťovny
DROP TABLE Vykon CASCADE CONSTRAINTS;                -- výkony (typy)
DROP TABLE Lek CASCADE CONSTRAINTS;                  -- léky
DROP TABLE Typ_ockovani CASCADE CONSTRAINTS;         -- typy očkování
DROP TABLE Pravidelna_prohlidka CASCADE CONSTRAINTS; -- pravidelné prohlídky

-- Smažeme i sekvence (číselné řady pro automatické generování ID)
DROP SEQUENCE seq_navsteva_id;
DROP SEQUENCE seq_ext_vysetreni_id;

-- ==========================================
-- KROK 2: Vytvoření sekvencí
-- ==========================================
-- SEQUENCE = automatický čítač, který generuje unikátní čísla (1, 2, 3, ...).
-- Použijeme ho pro automatické přidělování ID návštěvám a externím vyšetřením.
-- START WITH 1 = začni od jedničky
-- INCREMENT BY 1 = každé další číslo je o 1 větší

CREATE SEQUENCE seq_navsteva_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_ext_vysetreni_id START WITH 1 INCREMENT BY 1;

-- ==========================================
-- KROK 3: Vytvoření tabulek
-- ==========================================

-- ------------------------------------------
-- Tabulka: POJIŠŤOVNA
-- ------------------------------------------
-- Uchovává seznamy pojišťoven, u kterých jsou pacienti registrováni.
CREATE TABLE Pojistovna (
    cislo_pojistovny NUMBER NOT NULL,        -- číslo pojišťovny (např. 111 = VZP), NOT NULL = povinné
    nazev VARCHAR2(100) NOT NULL,            -- název pojišťovny, max 100 znaků
    adresa VARCHAR2(200) NOT NULL,           -- adresa sídla pojišťovny

    -- PRIMARY KEY = unikátní identifikátor řádku, každá pojišťovna má jedinečné číslo
    CONSTRAINT pk_pojistovna PRIMARY KEY (cislo_pojistovny),

    -- CHECK = kontrola, že číslo pojišťovny je 3-ciferné (100 až 999)
    -- České pojišťovny mají vždy 3-ciferný kód (111, 201, 205, 207, ...)
    CONSTRAINT chk_cislo_pojistovny CHECK (cislo_pojistovny BETWEEN 100 AND 999)
);

-- ------------------------------------------
-- Tabulka: PACIENT
-- ------------------------------------------
-- DŮLEŽITÉ: Tato tabulka obsahuje řešení GENERALIZACE/SPECIALIZACE.
--
-- V ER diagramu máme:  Pacient (nadtřída)
--                        ├── Registrovaný (podtřída, má "Číslo karty")
--                        └── Akutní (podtřída, nemá žádné vlastní atributy)
--
-- Převod do relační DB: Sloučili jsme vše do JEDNÉ tabulky "Pacient".
-- Proč? Protože "Akutní" nemá žádné vlastní sloupce, takže by vznikla
-- zbytečná prázdná tabulka. Místo toho:
--   - Sloupec "typ_pacienta" rozlišuje, zda jde o registrovaného nebo akutního
--   - Sloupec "cislo_karty" je vyplněný jen u registrovaných (u akutních je NULL)
--   - CHECK omezení hlídá konzistenci (registrovaný MUSÍ mít kartu, akutní NESMÍ)

CREATE TABLE Pacient (
    cislo_pacienta NUMBER NOT NULL,          -- unikátní ID pacienta (primární klíč)
    rodne_cislo VARCHAR2(11) NOT NULL,       -- rodné číslo ve formátu YYMMDD/XXXX (max 11 znaků vč. lomítka)
    jmeno VARCHAR2(50) NOT NULL,             -- křestní jméno
    prijmeni VARCHAR2(50) NOT NULL,          -- příjmení
    telefon VARCHAR2(20),                    -- telefon (nepovinný – bez NOT NULL)
    datum_narozeni DATE NOT NULL,            -- datum narození (Oracle typ DATE)
    adresa VARCHAR2(200),                    -- bydliště (nepovinné)
    typ_pacienta VARCHAR2(20) NOT NULL,      -- diskriminátor: 'registrovany' nebo 'akutni'
    cislo_karty VARCHAR2(20),                -- číslo zdravotní karty (jen pro registrované)
    cislo_pojistovny NUMBER NOT NULL,        -- FK (cizí klíč) na tabulku Pojistovna

    -- Primární klíč – každý pacient má unikátní cislo_pacienta
    CONSTRAINT pk_pacient PRIMARY KEY (cislo_pacienta),

    -- UNIQUE = rodné číslo musí být unikátní (žádní dva pacienti nemají stejné RČ)
    CONSTRAINT uq_rodne_cislo UNIQUE (rodne_cislo),

    -- FOREIGN KEY = cizí klíč – cislo_pojistovny musí existovat v tabulce Pojistovna
    -- Tzn. nemůžeš vložit pacienta s pojišťovnou, která neexistuje
    CONSTRAINT fk_pacient_pojistovna FOREIGN KEY (cislo_pojistovny)
        REFERENCES Pojistovna(cislo_pojistovny),

    -- *** SPECIÁLNÍ OMEZENÍ HODNOT (požadavek zadání) ***
    -- CHECK s regulárním výrazem validující formát rodného čísla:
    --   ^\d{2}           = rok narození (2 číslice)
    --   (0[1-9]|1[0-2]   = měsíc 01-12 pro muže
    --   |5[1-9]|6[0-2])  = měsíc 51-62 pro ženy (přičtení 50)
    --   (0[1-9]|[12]\d   = den 01-29
    --   |3[01])           = nebo den 30-31
    --   /?                = volitelné lomítko
    --   \d{3,4}$          = 3 nebo 4 číslice za lomítkem
    -- Příklady platných hodnot: '850612/1234', '9052154321', '750101/111'
    CONSTRAINT chk_rodne_cislo CHECK (
        REGEXP_LIKE(rodne_cislo,
            '^\d{2}(0[1-9]|1[0-2]|5[1-9]|6[0-2])(0[1-9]|[12]\d|3[01])/?\d{3,4}$')
    ),

    -- Typ pacienta smí být jen 'registrovany' nebo 'akutni' – nic jiného
    CONSTRAINT chk_typ_pacienta CHECK (typ_pacienta IN ('registrovany', 'akutni')),

    -- Logická kontrola generalizace:
    -- Pokud typ = 'registrovany' → cislo_karty MUSÍ být vyplněné (AND IS NOT NULL)
    -- Pokud typ = 'akutni'       → cislo_karty MUSÍ být prázdné (AND IS NULL)
    CONSTRAINT chk_cislo_karty CHECK (
        (typ_pacienta = 'registrovany' AND cislo_karty IS NOT NULL) OR
        (typ_pacienta = 'akutni' AND cislo_karty IS NULL)
    )
);

-- ------------------------------------------
-- Tabulka: NÁVŠTĚVA
-- ------------------------------------------
-- Každý řádek = jedna návštěva pacienta v ordinaci.
-- PK (cislo_navstevy) se generuje AUTOMATICKY ze sekvence pomocí triggeru (viz níže).
CREATE TABLE Navsteva (
    cislo_navstevy NUMBER DEFAULT NULL,      -- PK – pokud vložíš NULL, trigger doplní číslo ze sekvence
    datum_cas TIMESTAMP NOT NULL,            -- datum a čas návštěvy (TIMESTAMP = datum + čas s přesností)
    typ_navstevy VARCHAR2(50) NOT NULL,      -- 'planovana' nebo 'akutni'
    cislo_pacienta NUMBER NOT NULL,          -- FK na tabulku Pacient (který pacient přišel)

    CONSTRAINT pk_navsteva PRIMARY KEY (cislo_navstevy),

    -- Cizí klíč: cislo_pacienta musí existovat v tabulce Pacient
    CONSTRAINT fk_navsteva_pacient FOREIGN KEY (cislo_pacienta)
        REFERENCES Pacient(cislo_pacienta),

    -- Typ návštěvy může být jen 'planovana' nebo 'akutni'
    CONSTRAINT chk_typ_navstevy CHECK (typ_navstevy IN ('planovana', 'akutni'))
);

-- ------------------------------------------
-- Trigger pro automatické generování PK
-- ------------------------------------------
-- TRIGGER = kus kódu, který se automaticky spustí při určité události.
-- Tento trigger se spustí PŘED každým INSERTem do tabulky Navsteva.
-- Pokud inserted řádek nemá vyplněné cislo_navstevy (je NULL),
-- trigger ho automaticky vyplní dalším číslem ze sekvence.
-- Díky tomu můžeš psát: INSERT INTO Navsteva (cislo_navstevy, ...) VALUES (NULL, ...);
-- a PK se doplní automaticky (1, 2, 3, ...).

CREATE OR REPLACE TRIGGER trg_navsteva_pk  -- název triggeru
BEFORE INSERT ON Navsteva                  -- spustí se PŘED insertem do Navsteva
FOR EACH ROW                               -- pro každý vkládaný řádek zvlášť
BEGIN
    -- :NEW odkazuje na nově vkládaný řádek
    IF :NEW.cislo_navstevy IS NULL THEN                    -- pokud PK není zadané
        :NEW.cislo_navstevy := seq_navsteva_id.NEXTVAL;    -- vezmi další číslo ze sekvence
    END IF;
END;
/
-- Lomítko "/" na konci je nutné v Oracle – ukončuje PL/SQL blok (trigger/procedura)

-- ------------------------------------------
-- Tabulka: VÝKON
-- ------------------------------------------
-- Číselník/katalog typů výkonů (měření TK, odběr krve, EKG, ...).
-- Každý výkon má svůj kód (typ_vykonu), název a popis.
CREATE TABLE Vykon (
    typ_vykonu NUMBER NOT NULL,              -- kód výkonu (PK)
    nazev VARCHAR2(100) NOT NULL,            -- název výkonu
    popis VARCHAR2(500),                     -- podrobnější popis (nepovinný)
    CONSTRAINT pk_vykon PRIMARY KEY (typ_vykonu)
);

-- ------------------------------------------
-- Vazební tabulka: NÁVŠTĚVA <-> VÝKON (M:N)
-- ------------------------------------------
-- Vztah M:N (many-to-many) = jedna návštěva může zahrnovat VÍCE výkonů
--                             a jeden typ výkonu se provádí na VÍCE návštěvách.
-- V relační DB se M:N vztah řeší pomocí "vazební tabulky" (junction table),
-- která má dva cizí klíče – jeden na každou stranu vztahu.
-- Primární klíč je SLOŽENÝ (composite) z obou FK sloupců.
CREATE TABLE Navsteva_Vykon (
    cislo_navstevy NUMBER NOT NULL,          -- FK na Navsteva
    typ_vykonu NUMBER NOT NULL,              -- FK na Vykon

    -- Složený primární klíč = kombinace (návštěva + výkon) musí být unikátní
    -- Tzn. stejný výkon nemůže být u stejné návštěvy zapsán dvakrát
    CONSTRAINT pk_navsteva_vykon PRIMARY KEY (cislo_navstevy, typ_vykonu),

    CONSTRAINT fk_nv_navsteva FOREIGN KEY (cislo_navstevy)
        REFERENCES Navsteva(cislo_navstevy),
    CONSTRAINT fk_nv_vykon FOREIGN KEY (typ_vykonu)
        REFERENCES Vykon(typ_vykonu)
);

-- ------------------------------------------
-- Tabulka: LÉK
-- ------------------------------------------
-- Číselník léků, které lékař může předepsat.
CREATE TABLE Lek (
    cislo_leku NUMBER NOT NULL,              -- unikátní číslo léku (PK)
    nazev VARCHAR2(100) NOT NULL,            -- obchodní název
    popis VARCHAR2(500),                     -- popis / účinná látka
    CONSTRAINT pk_lek PRIMARY KEY (cislo_leku)
);

-- ------------------------------------------
-- Tabulka: PŘEDPIS
-- ------------------------------------------
-- Každý řádek = jeden předpis léku vystavený při návštěvě.
-- Každý předpis se vztahuje k jedné návštěvě (FK) a jednomu léku (FK).
CREATE TABLE Predpis (
    cislo_predpisu NUMBER NOT NULL,          -- unikátní číslo předpisu (PK)
    datum_vystaveni DATE NOT NULL,           -- datum, kdy byl předpis vystavený
    davkovani VARCHAR2(200) NOT NULL,        -- instrukce pro dávkování (např. "3x denně po jídle")
    cislo_navstevy NUMBER NOT NULL,          -- FK: při které návštěvě byl předpis vypsán
    cislo_leku NUMBER NOT NULL,              -- FK: který lék je předepsán

    CONSTRAINT pk_predpis PRIMARY KEY (cislo_predpisu),

    -- Cizí klíč na Navsteva – předpis patří ke konkrétní návštěvě
    CONSTRAINT fk_predpis_navsteva FOREIGN KEY (cislo_navstevy)
        REFERENCES Navsteva(cislo_navstevy),

    -- Cizí klíč na Lek – předpis odkazuje na konkrétní lék
    CONSTRAINT fk_predpis_lek FOREIGN KEY (cislo_leku)
        REFERENCES Lek(cislo_leku)
);

-- ------------------------------------------
-- Tabulka: EXTERNÍ VYŠETŘENÍ
-- ------------------------------------------
-- Lékař může při návštěvě poslat pacienta na vyšetření na jiné pracoviště.
-- Tabulka eviduje tato externí vyšetření.
-- PK se opět generuje automaticky ze sekvence (viz trigger níže).
CREATE TABLE Externi_vysetreni (
    id_ext_vysetreni NUMBER DEFAULT NULL,    -- PK – automaticky generované (NULL → sekvence)
    nazev VARCHAR2(100) NOT NULL,            -- název vyšetření
    popis VARCHAR2(500),                     -- popis vyšetření
    pracoviste VARCHAR2(200) NOT NULL,       -- kam pacient dochází (název pracoviště)
    cislo_navstevy NUMBER NOT NULL,          -- FK: při které návštěvě bylo vyšetření požadováno
    cislo_pacienta NUMBER NOT NULL,          -- FK: který pacient na vyšetření dochází

    CONSTRAINT pk_ext_vysetreni PRIMARY KEY (id_ext_vysetreni),

    CONSTRAINT fk_ev_navsteva FOREIGN KEY (cislo_navstevy)
        REFERENCES Navsteva(cislo_navstevy),
    CONSTRAINT fk_ev_pacient FOREIGN KEY (cislo_pacienta)
        REFERENCES Pacient(cislo_pacienta)
);

-- Trigger pro automatické generování PK externího vyšetření (stejný princip jako u Navsteva)
CREATE OR REPLACE TRIGGER trg_ext_vysetreni_pk
BEFORE INSERT ON Externi_vysetreni
FOR EACH ROW
BEGIN
    IF :NEW.id_ext_vysetreni IS NULL THEN
        :NEW.id_ext_vysetreni := seq_ext_vysetreni_id.NEXTVAL;
    END IF;
END;
/

-- ------------------------------------------
-- Tabulka: PRAVIDELNÁ PROHLÍDKA
-- ------------------------------------------
-- Číselník typů pravidelných prohlídek (preventivní, diabetologická, ...).
-- Každý typ má nastavenou frekvenci (jak často se opakuje).
CREATE TABLE Pravidelna_prohlidka (
    typ_prohlidky NUMBER NOT NULL,           -- kód typu prohlídky (PK)
    nazev VARCHAR2(100) NOT NULL,            -- název prohlídky
    popis VARCHAR2(500),                     -- podrobný popis
    doba_frekvence NUMBER NOT NULL,          -- jak často se opakuje (v měsících, např. 24 = každé 2 roky)
    CONSTRAINT pk_prav_prohlidka PRIMARY KEY (typ_prohlidky)
);

-- ------------------------------------------
-- Vazební tabulka: NÁVŠTĚVA <-> PRAVIDELNÁ PROHLÍDKA (M:N)
-- ------------------------------------------
-- Jedna návštěva může zahrnovat více typů prohlídek,
-- a jeden typ prohlídky se provádí na více návštěvách.
CREATE TABLE Navsteva_Prohlidka (
    cislo_navstevy NUMBER NOT NULL,          -- FK na Navsteva
    typ_prohlidky NUMBER NOT NULL,           -- FK na Pravidelna_prohlidka

    -- Složený PK – jedna prohlídka může být u jedné návštěvy jen jednou
    CONSTRAINT pk_navsteva_prohlidka PRIMARY KEY (cislo_navstevy, typ_prohlidky),

    CONSTRAINT fk_np_navsteva FOREIGN KEY (cislo_navstevy)
        REFERENCES Navsteva(cislo_navstevy),
    CONSTRAINT fk_np_prohlidka FOREIGN KEY (typ_prohlidky)
        REFERENCES Pravidelna_prohlidka(typ_prohlidky)
);

-- ------------------------------------------
-- Tabulka: TYP OČKOVÁNÍ
-- ------------------------------------------
-- Číselník typů očkování (chřipka, tetanus, COVID-19, ...).
-- Každý typ má nastavenou dobu účinnosti (po které je třeba přeočkovat).
CREATE TABLE Typ_ockovani (
    typ_ockovani NUMBER NOT NULL,            -- kód typu očkování (PK)
    nazev VARCHAR2(100) NOT NULL,            -- název (např. 'Tetanus')
    popis VARCHAR2(500),                     -- podrobný popis
    doba_ucinnosti NUMBER,                   -- jak dlouho očkování účinkuje (v měsících, nepovinné)
    CONSTRAINT pk_typ_ockovani PRIMARY KEY (typ_ockovani)
);

-- ------------------------------------------
-- Tabulka: OČKOVÁNÍ
-- ------------------------------------------
-- Konkrétní provedená očkování. Každé očkování má svůj typ a volitelně
-- odkaz na návštěvu, při které bylo provedeno.
CREATE TABLE Ockovani (
    id_ockovani NUMBER NOT NULL,             -- unikátní ID očkování (PK)
    datum_ockovani DATE NOT NULL,            -- datum provedení očkování
    popis VARCHAR2(500),                     -- poznámka (např. 'Sezónní vakcína 2024')
    typ_ockovani NUMBER NOT NULL,            -- FK: jaký typ očkování byl proveden
    cislo_navstevy NUMBER,                   -- FK: při které návštěvě (může být NULL – nepovinné)

    CONSTRAINT pk_ockovani PRIMARY KEY (id_ockovani),

    -- Cizí klíč na typ očkování
    CONSTRAINT fk_ock_typ FOREIGN KEY (typ_ockovani)
        REFERENCES Typ_ockovani(typ_ockovani),

    -- Cizí klíč na návštěvu (NULL povoleno – očkování nemusí být vázáno na návštěvu)
    CONSTRAINT fk_ock_navsteva FOREIGN KEY (cislo_navstevy)
        REFERENCES Navsteva(cislo_navstevy)
);

-- ==========================================
-- KROK 4: Vložení ukázkových dat
-- ==========================================
-- INSERT INTO = vložení nového řádku do tabulky.
-- VALUES (...) = konkrétní hodnoty pro každý sloupec.
-- Pozor na pořadí: hodnoty musí odpovídat sloupcům v tabulce (nebo ve vyjmenovaných sloupcích).
-- TO_DATE('...', 'YYYY-MM-DD') = převod textového řetězce na Oracle datum.
-- TO_TIMESTAMP('...', '...') = převod na časové razítko (datum + čas).

-- Pojišťovny (cislo_pojistovny, nazev, adresa)
INSERT INTO Pojistovna VALUES (111, 'Všeobecná zdravotní pojišťovna', 'Orlická 4/2020, 130 00 Praha 3');
INSERT INTO Pojistovna VALUES (201, 'Vojenská zdravotní pojišťovna', 'Drahobejlova 1404/4, 190 03 Praha 9');
INSERT INTO Pojistovna VALUES (207, 'Oborová zdravotní pojišťovna', 'Roškotova 1225/1, 140 00 Praha 4');

-- Pacienti – ukázka registrovaných i akutních pacientů
-- Registrovaný pacient: typ_pacienta = 'registrovany', cislo_karty = 'K001'
-- Akutní pacient: typ_pacienta = 'akutni', cislo_karty = NULL
INSERT INTO Pacient VALUES (1, '850612/1234', 'Jan', 'Novák', '+420123456789',
    TO_DATE('1985-06-12', 'YYYY-MM-DD'), 'Brněnská 15, 602 00 Brno',
    'registrovany', 'K001', 111);       -- pojišťovna 111 = VZP
INSERT INTO Pacient VALUES (2, '905215/4321', 'Marie', 'Svobodová', '+420987654321',
    TO_DATE('1990-02-15', 'YYYY-MM-DD'), 'Masarykova 8, 602 00 Brno',
    'registrovany', 'K002', 207);       -- pojišťovna 207 = OZP; RČ 9052xx = žena (měsíc 52 = únor + 50)
INSERT INTO Pacient VALUES (3, '750101/1111', 'Petr', 'Dvořák', '+420111222333',
    TO_DATE('1975-01-01', 'YYYY-MM-DD'), 'Koliště 3, 601 00 Brno',
    'registrovany', 'K003', 201);       -- pojišťovna 201 = VOZP
INSERT INTO Pacient VALUES (4, '000305/5678', 'Tomáš', 'Procházka', '+420555666777',
    TO_DATE('2000-03-05', 'YYYY-MM-DD'), 'Úvoz 10, 602 00 Brno',
    'akutni', NULL, 111);               -- AKUTNÍ pacient – cislo_karty je NULL

-- Návštěvy
-- cislo_navstevy = NULL → trigger automaticky doplní číslo ze sekvence (1, 2, 3, 4)
-- Díky tomu nemusíme ručně vymýšlet ID!
INSERT INTO Navsteva (cislo_navstevy, datum_cas, typ_navstevy, cislo_pacienta)
    VALUES (NULL, TO_TIMESTAMP('2024-01-15 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'planovana', 1);  -- pacient Jan
INSERT INTO Navsteva (cislo_navstevy, datum_cas, typ_navstevy, cislo_pacienta)
    VALUES (NULL, TO_TIMESTAMP('2024-01-15 10:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'planovana', 2);  -- pacient Marie
INSERT INTO Navsteva (cislo_navstevy, datum_cas, typ_navstevy, cislo_pacienta)
    VALUES (NULL, TO_TIMESTAMP('2024-01-16 08:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'akutni', 4);     -- akutní pacient Tomáš
INSERT INTO Navsteva (cislo_navstevy, datum_cas, typ_navstevy, cislo_pacienta)
    VALUES (NULL, TO_TIMESTAMP('2024-02-01 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'planovana', 3);  -- pacient Petr

-- Výkony (katalog) – (typ_vykonu, nazev, popis)
INSERT INTO Vykon VALUES (1, 'Měření krevního tlaku', 'Standardní měření TK na paži');
INSERT INTO Vykon VALUES (2, 'Odběr krve', 'Odběr venózní krve pro laboratorní vyšetření');
INSERT INTO Vykon VALUES (3, 'EKG', 'Elektrokardiografie - vyšetření srdeční činnosti');
INSERT INTO Vykon VALUES (4, 'Aplikace injekce', 'Intramuskulární nebo subkutánní aplikace');

-- Vazba Návštěva–Výkon (cislo_navstevy, typ_vykonu)
-- Návštěva 1 (Jan) zahrnovala: měření TK + odběr krve
INSERT INTO Navsteva_Vykon VALUES (1, 1);   -- návštěva 1, výkon 1 (měření TK)
INSERT INTO Navsteva_Vykon VALUES (1, 2);   -- návštěva 1, výkon 2 (odběr krve)
-- Návštěva 2 (Marie) zahrnovala: měření TK + EKG
INSERT INTO Navsteva_Vykon VALUES (2, 1);   -- návštěva 2, výkon 1
INSERT INTO Navsteva_Vykon VALUES (2, 3);   -- návštěva 2, výkon 3
-- Návštěva 3 (Tomáš, akutní): měření TK
INSERT INTO Navsteva_Vykon VALUES (3, 1);   -- návštěva 3, výkon 1
-- Návštěva 4 (Petr): odběr krve + injekce
INSERT INTO Navsteva_Vykon VALUES (4, 2);   -- návštěva 4, výkon 2
INSERT INTO Navsteva_Vykon VALUES (4, 4);   -- návštěva 4, výkon 4

-- Léky (katalog) – (cislo_leku, nazev, popis)
INSERT INTO Lek VALUES (1, 'Ibuprofen 400mg', 'Nesteroidní protizánětlivý lék');
INSERT INTO Lek VALUES (2, 'Amoxicilin 500mg', 'Antibiotikum ze skupiny penicilinů');
INSERT INTO Lek VALUES (3, 'Paralen 500mg', 'Analgetikum a antipyretikum');

-- Předpisy – (cislo_predpisu, datum_vystaveni, davkovani, cislo_navstevy, cislo_leku)
-- Při návštěvě 1 byl Janovi předepsán Ibuprofen
INSERT INTO Predpis VALUES (1, TO_DATE('2024-01-15', 'YYYY-MM-DD'), '1 tableta 3x denně po jídle', 1, 1);
-- Při návštěvě 2 byl Marii předepsán Amoxicilin
INSERT INTO Predpis VALUES (2, TO_DATE('2024-01-15', 'YYYY-MM-DD'), '1 tableta 2x denně, 7 dní', 2, 2);
-- Při návštěvě 3 byl Tomášovi předepsán Paralen
INSERT INTO Predpis VALUES (3, TO_DATE('2024-01-16', 'YYYY-MM-DD'), '1-2 tablety při bolesti, max 4x denně', 3, 3);

-- Externí vyšetření
-- id = NULL → trigger automaticky vygeneruje ID ze sekvence
-- Při návštěvě 1 byl Jan poslán na RTG hrudníku do FN Brno
INSERT INTO Externi_vysetreni (id_ext_vysetreni, nazev, popis, pracoviste, cislo_navstevy, cislo_pacienta)
    VALUES (NULL, 'RTG hrudníku', 'Rentgenové vyšetření plic', 'Radiologická klinika FN Brno', 1, 1);
-- Při návštěvě 2 byla Marie poslána na ultrazvuk
INSERT INTO Externi_vysetreni (id_ext_vysetreni, nazev, popis, pracoviste, cislo_navstevy, cislo_pacienta)
    VALUES (NULL, 'Ultrazvuk břicha', 'Sonografie orgánů břišní dutiny', 'Interní klinika FN Brno', 2, 2);

-- Pravidelné prohlídky (katalog) – (typ_prohlidky, nazev, popis, doba_frekvence)
-- doba_frekvence = kolik měsíců mezi prohlídkami
INSERT INTO Pravidelna_prohlidka VALUES (1, 'Preventivní prohlídka', 'Komplexní preventivní prohlídka dospělého', 24);   -- každé 2 roky
INSERT INTO Pravidelna_prohlidka VALUES (2, 'Prohlídka diabetika', 'Pravidelná kontrola pacienta s diabetem', 3);        -- každé 3 měsíce
INSERT INTO Pravidelna_prohlidka VALUES (3, 'Kardiovaskulární prohlídka', 'Kontrola TK a kardiovaskulárních rizik', 6);   -- každých 6 měsíců

-- Vazba Návštěva–Prohlídka – (cislo_navstevy, typ_prohlidky)
-- Při návštěvě 1 proběhla preventivní prohlídka
INSERT INTO Navsteva_Prohlidka VALUES (1, 1);   -- návštěva 1, prohlídka 1 (preventivní)
-- Při návštěvě 4 proběhla prohlídka diabetika + kardiovaskulární
INSERT INTO Navsteva_Prohlidka VALUES (4, 2);   -- návštěva 4, prohlídka 2 (diabetik)
INSERT INTO Navsteva_Prohlidka VALUES (4, 3);   -- návštěva 4, prohlídka 3 (kardiovaskulární)

-- Typy očkování (katalog) – (typ_ockovani, nazev, popis, doba_ucinnosti)
-- doba_ucinnosti = kolik měsíců očkování účinkuje
INSERT INTO Typ_ockovani VALUES (1, 'Chřipka', 'Sezónní očkování proti chřipce', 12);                  -- 12 měsíců
INSERT INTO Typ_ockovani VALUES (2, 'Tetanus', 'Očkování proti tetanu', 120);                           -- 10 let = 120 měsíců
INSERT INTO Typ_ockovani VALUES (3, 'COVID-19', 'Očkování proti onemocnění COVID-19', 6);               -- 6 měsíců

-- Očkování – (id_ockovani, datum_ockovani, popis, typ_ockovani, cislo_navstevy)
-- Jan dostal při návštěvě 1 očkování proti chřipce
INSERT INTO Ockovani VALUES (1, TO_DATE('2024-01-15', 'YYYY-MM-DD'), 'Sezónní vakcína 2024', 1, 1);
-- Petr dostal při návštěvě 4 přeočkování tetanu
INSERT INTO Ockovani VALUES (2, TO_DATE('2024-02-01', 'YYYY-MM-DD'), 'Přeočkování tetanu', 2, 4);

-- ==========================================
-- KROK 5: Ověření – výpis počtu záznamů
-- ==========================================
-- Tento SELECT spojí výsledky z více tabulek a ukáže, kolik záznamů
-- bylo úspěšně vloženo do každé tabulky. UNION ALL = spojení výsledků.
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
