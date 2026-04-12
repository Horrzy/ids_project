
-- Téma: Ordinace praktického lékaře
-- Autor: Jan Raška (xraskaj00), Matěj Zaoral (xzaoram00)

-- DROP TABLES AND SEQUENCES

DROP TABLE externi_vysetreni CASCADE CONSTRAINTS;
DROP TABLE predpisy CASCADE CONSTRAINTS;
DROP TABLE ockovani CASCADE CONSTRAINTS;
DROP TABLE navsteva_vykon CASCADE CONSTRAINTS;
DROP TABLE navstevy CASCADE CONSTRAINTS;
DROP TABLE pacienti_registrovani CASCADE CONSTRAINTS;
DROP TABLE pacienti CASCADE CONSTRAINTS;
DROP TABLE pojistovny CASCADE CONSTRAINTS;
DROP TABLE leky CASCADE CONSTRAINTS;
DROP TABLE typy_ockovani CASCADE CONSTRAINTS;
DROP TABLE pravidelne_prohlidky CASCADE CONSTRAINTS;
DROP TABLE vykony CASCADE CONSTRAINTS;

DROP SEQUENCE seq_pacienti;
DROP SEQUENCE seq_navstevy;
DROP SEQUENCE seq_vykony;
DROP SEQUENCE seq_typy_ockovani;
DROP SEQUENCE seq_pravidelne_prohlidky;
DROP SEQUENCE seq_leky;
DROP SEQUENCE seq_ockovani;
DROP SEQUENCE seq_predpisy;
DROP SEQUENCE seq_externi_vysetreni;




-- CREATE SEQUENCES

CREATE SEQUENCE seq_pacienti;
CREATE SEQUENCE seq_navstevy;
CREATE SEQUENCE seq_vykony;
CREATE SEQUENCE seq_typy_ockovani;
CREATE SEQUENCE seq_pravidelne_prohlidky;
CREATE SEQUENCE seq_leky;
CREATE SEQUENCE seq_ockovani;
CREATE SEQUENCE seq_predpisy;
CREATE SEQUENCE seq_externi_vysetreni;




-- CREATE TABLES

CREATE TABLE pojistovny (
   cislo_pojistovny  INTEGER,
   nazev             VARCHAR(100) NOT NULL,
   adresa            VARCHAR(200)
);

CREATE TABLE pacienti (
   cislo_pacienta    INTEGER,
   jmeno             VARCHAR(50) NOT NULL,
   prijmeni          VARCHAR(50) NOT NULL,
   rodne_cislo       VARCHAR(11) NOT NULL,
   telefon           VARCHAR(20),
   datum_narozeni    DATE,
   adresa            VARCHAR(200),
   cislo_pojistovny  INTEGER NOT NULL
);

CREATE TABLE pacienti_registrovani (
   cislo_pacienta    INTEGER,
   cislo_karty       INTEGER NOT NULL
);

-- Vysvětlení generalizace:
-- Zvolili jsme metodu, kde pro každý podtyp vytváříme samostatnou tabulku.
-- Tabulka 'pacienti' obsahuje společné atributy obou typů pacientů.
-- Tabulka 'pacienti_registrovani' uchovává specifická data (číslo karty) a odkazuje na primární klíč v 'pacienti'.
-- Akutní případy nevyžadují specifické atributy, jsou tedy reprezentovány pouze v základní tabulce.

CREATE TABLE vykony (
   typ_vykonu        INTEGER,
   nazev             VARCHAR(100) NOT NULL,
   popis             VARCHAR(500)
);

CREATE TABLE typy_ockovani (
   typ_ockovani_id   INTEGER,
   nazev             VARCHAR(100) NOT NULL,
   popis             VARCHAR(500),
   doba_ucinnosti    INTEGER
);

CREATE TABLE pravidelne_prohlidky (
   typ_prohlidky     INTEGER,
   nazev             VARCHAR(100) NOT NULL,
   popis             VARCHAR(500),
   doba_frekvence    INTEGER
);

CREATE TABLE leky (
   cislo_leku        INTEGER,
   nazev             VARCHAR(100) NOT NULL,
   popis             VARCHAR(500)
);

CREATE TABLE navstevy (
   cislo_navstevy    INTEGER,
   datum_a_cas       TIMESTAMP NOT NULL,
   typ_navstevy      VARCHAR(20) NOT NULL,
   cislo_pacienta    INTEGER NOT NULL,
   typ_prohlidky     INTEGER
);

-- Trigger pro automatické generování primárního klíče
-- Pokud je v příkazu INSERT hodnota cislo_navstevy rovna NULL, trigger ji doplní ze sekvence.
CREATE OR REPLACE TRIGGER trg_navstevy_pk
BEFORE INSERT ON navstevy
FOR EACH ROW
BEGIN
    IF :NEW.cislo_navstevy IS NULL THEN
        :NEW.cislo_navstevy := seq_navstevy.NEXTVAL;
    END IF;
END;
/

CREATE TABLE navsteva_vykon (
   cislo_navstevy    INTEGER NOT NULL,
   typ_vykonu        INTEGER NOT NULL
);

CREATE TABLE ockovani (
   id_ockovani       INTEGER,
   datum_ockovani    DATE NOT NULL,
   popis             VARCHAR(500),
   cislo_pacienta    INTEGER NOT NULL,
   cislo_navstevy    INTEGER NOT NULL,
   typ_ockovani_id   INTEGER NOT NULL
);

CREATE TABLE predpisy (
   cislo_predpisu    INTEGER,
   datum_vystaveni   DATE NOT NULL,
   davkovani         VARCHAR(100),
   cislo_navstevy    INTEGER NOT NULL,
   cislo_leku        INTEGER NOT NULL
);

CREATE TABLE externi_vysetreni (
   id_ex_vysetreni   INTEGER,
   nazev             VARCHAR(100) NOT NULL,
   popis             VARCHAR(500),
   pracoviste        VARCHAR(200) NOT NULL,
   cislo_navstevy    INTEGER NOT NULL
);



-- SEED DATABASE

-- Pojišťovny
INSERT INTO pojistovny ( cislo_pojistovny, nazev, adresa )
   VALUES ( 111, 'Všeobecná zdravotní pojišťovna', 'Orlická 2020/4, Praha 3' );
INSERT INTO pojistovny ( cislo_pojistovny, nazev, adresa )
   VALUES ( 211, 'Zdravotní pojišťovna ministerstva vnitra ČR', 'Vinohradská 2577/178, Praha 3' );

-- Pacienti
INSERT INTO pacienti ( cislo_pacienta, jmeno, prijmeni, rodne_cislo, telefon, datum_narozeni, adresa, cislo_pojistovny )
   VALUES ( seq_pacienti.NEXTVAL, 'Karel', 'Novák', '800512/1234', '+420608123456', TO_DATE('1980-05-12','YYYY-MM-DD'), 'Brno, Hoblíkova 32', 111 );
INSERT INTO pacienti ( cislo_pacienta, jmeno, prijmeni, rodne_cislo, telefon, datum_narozeni, adresa, cislo_pojistovny )
   VALUES ( seq_pacienti.NEXTVAL, 'Jana', 'Nováková', '925821/5678', '+420721987654', TO_DATE('1992-08-21','YYYY-MM-DD'), 'Olomouc, Kmochova 17', 211 );

-- Registrovaní pacienti
INSERT INTO pacienti_registrovani ( cislo_pacienta, cislo_karty )
   VALUES ( 1, 10001 );

-- Výkony
INSERT INTO vykony ( typ_vykonu, nazev, popis )
   VALUES ( seq_vykony.NEXTVAL, 'Odběr krve', 'Standardní odběr' );
INSERT INTO vykony ( typ_vykonu, nazev, popis )
   VALUES ( seq_vykony.NEXTVAL, 'MRI', 'Magnetická rezonance' );

-- Pravidelné prohlídky
INSERT INTO pravidelne_prohlidky ( typ_prohlidky, nazev, popis, doba_frekvence )
   VALUES ( seq_pravidelne_prohlidky.NEXTVAL, 'Preventivní prohlídka', 'Vyšetření celkového stavu', 24 );

-- Typy očkování
INSERT INTO typy_ockovani ( typ_ockovani_id, nazev, popis, doba_ucinnosti )
   VALUES ( seq_typy_ockovani.NEXTVAL, 'FSME-IMMUN', 'Očkování proti klíšťové encefalitidě', 60 );

-- Léky
INSERT INTO leky ( cislo_leku, nazev, popis )
   VALUES ( seq_leky.NEXTVAL, 'Paralen', 'Lék proti bolesti' );

-- Návštěvy s automatickým generováním
INSERT INTO navstevy ( cislo_navstevy, datum_a_cas, typ_navstevy, cislo_pacienta, typ_prohlidky )
   VALUES ( NULL, TO_TIMESTAMP('2026-01-01 09:00:00','YYYY-MM-DD HH24:MI:SS'), 'planovana', 1, 1 );
INSERT INTO navstevy ( cislo_navstevy, datum_a_cas, typ_navstevy, cislo_pacienta )
   VALUES ( seq_navstevy.NEXTVAL, TO_TIMESTAMP('2026-01-01 10:30:00','YYYY-MM-DD HH24:MI:SS'), 'akutni', 2 );

-- Výkony během návštěvy
INSERT INTO navsteva_vykon ( cislo_navstevy, typ_vykonu )
   VALUES ( 1, 1 );

-- Očkování
INSERT INTO ockovani ( id_ockovani, datum_ockovani, popis, cislo_pacienta, cislo_navstevy, typ_ockovani_id )
   VALUES ( seq_ockovani.NEXTVAL, TO_DATE('2026-01-01','YYYY-MM-DD'), 'První dávka', 2, 2, 1 );

-- Předpisy
INSERT INTO predpisy ( cislo_predpisu, datum_vystaveni, davkovani, cislo_navstevy, cislo_leku )
   VALUES ( seq_predpisy.NEXTVAL, TO_DATE('2026-01-01','YYYY-MM-DD'), '1 tableta po 6 hodinách', 1, 1 );

-- Externí vyšetření
INSERT INTO externi_vysetreni ( id_ex_vysetreni, nazev, popis, pracoviste, cislo_navstevy )
   VALUES ( seq_externi_vysetreni.NEXTVAL, 'RTG Srdce a plíce', 'Snímek hrudníku', 'Fakultní nemocnice Brno', 1 );

COMMIT;

-- CONSTRAINTS

-- Primární klíče
ALTER TABLE pojistovny ADD CONSTRAINT PK_pojistovny PRIMARY KEY (cislo_pojistovny);
ALTER TABLE pacienti ADD CONSTRAINT PK_cislo_pacienta PRIMARY KEY (cislo_pacienta);
ALTER TABLE pacienti_registrovani ADD CONSTRAINT PK_cislo_reg_pacienta PRIMARY KEY (cislo_pacienta);
ALTER TABLE vykony ADD CONSTRAINT PK_typ_vykonu PRIMARY KEY (typ_vykonu);
ALTER TABLE typy_ockovani ADD CONSTRAINT PK_typ_ockovani_id PRIMARY KEY (typ_ockovani_id);
ALTER TABLE pravidelne_prohlidky ADD CONSTRAINT PK_typ_prohlidky PRIMARY KEY (typ_prohlidky);
ALTER TABLE leky ADD CONSTRAINT PK_cislo_leku PRIMARY KEY (cislo_leku);
ALTER TABLE navstevy ADD CONSTRAINT PK_cislo_navstevy PRIMARY KEY (cislo_navstevy);
ALTER TABLE navsteva_vykon ADD CONSTRAINT PK_navsteva_vykon PRIMARY KEY (cislo_navstevy, typ_vykonu);
ALTER TABLE ockovani ADD CONSTRAINT PK_id_ockovani PRIMARY KEY (id_ockovani);
ALTER TABLE predpisy ADD CONSTRAINT PK_cislo_predpisu PRIMARY KEY (cislo_predpisu);
ALTER TABLE externi_vysetreni ADD CONSTRAINT PK_externi_vysetreni PRIMARY KEY (id_ex_vysetreni);

-- Cizí klíče
ALTER TABLE pacienti ADD CONSTRAINT FK_pacienti_pojistovny FOREIGN KEY (cislo_pojistovny) REFERENCES pojistovny(cislo_pojistovny);
ALTER TABLE pacienti_registrovani ADD CONSTRAINT FK_registrovani_pacienti FOREIGN KEY (cislo_pacienta) REFERENCES pacienti(cislo_pacienta) ON DELETE CASCADE;
ALTER TABLE navstevy ADD CONSTRAINT FK_navstevy_pacienti FOREIGN KEY (cislo_pacienta) REFERENCES pacienti(cislo_pacienta) ON DELETE CASCADE;
ALTER TABLE navstevy ADD CONSTRAINT FK_navstevy_prohlidky FOREIGN KEY (typ_prohlidky) REFERENCES pravidelne_prohlidky(typ_prohlidky) ON DELETE SET NULL;
ALTER TABLE navsteva_vykon ADD CONSTRAINT FK_navvyk_navstevy FOREIGN KEY (cislo_navstevy) REFERENCES navstevy(cislo_navstevy) ON DELETE CASCADE;
ALTER TABLE navsteva_vykon ADD CONSTRAINT FK_navvyk_vykony FOREIGN KEY (typ_vykonu) REFERENCES vykony(typ_vykonu) ON DELETE CASCADE;
ALTER TABLE ockovani ADD CONSTRAINT FK_ockovani_pacienti FOREIGN KEY (cislo_pacienta) REFERENCES pacienti(cislo_pacienta) ON DELETE CASCADE;
ALTER TABLE ockovani ADD CONSTRAINT FK_ockovani_navstevy FOREIGN KEY (cislo_navstevy) REFERENCES navstevy(cislo_navstevy) ON DELETE CASCADE;
ALTER TABLE ockovani ADD CONSTRAINT FK_ockovani_typy FOREIGN KEY (typ_ockovani_id) REFERENCES typy_ockovani(typ_ockovani_id) ON DELETE CASCADE;
ALTER TABLE predpisy ADD CONSTRAINT FK_predpisy_navstevy FOREIGN KEY (cislo_navstevy) REFERENCES navstevy(cislo_navstevy) ON DELETE CASCADE;
ALTER TABLE predpisy ADD CONSTRAINT FK_predpisy_leky FOREIGN KEY (cislo_leku) REFERENCES leky(cislo_leku) ON DELETE CASCADE;
ALTER TABLE externi_vysetreni ADD CONSTRAINT FK_externi_navstevy FOREIGN KEY (cislo_navstevy) REFERENCES navstevy(cislo_navstevy) ON DELETE CASCADE;

-- Ostatní omezení
ALTER TABLE pacienti_registrovani ADD CONSTRAINT UQ_cislo_karty UNIQUE (cislo_karty);
ALTER TABLE pacienti ADD CONSTRAINT CHK_rodne_cislo CHECK ( REGEXP_LIKE ( rodne_cislo, '^[0-9]{2}(0[1-9]|1[0-2]|5[1-9]|6[0-2])(0[1-9]|[12][0-9]|3[01])\/?[0-9]{3,4}$' ) );
ALTER TABLE navstevy ADD CONSTRAINT CHK_typ_navstevy CHECK ( typ_navstevy IN ( 'planovana', 'akutni' ) );



-- =============================================================================
-- 3. ČÁST – DOTAZY SELECT
-- =============================================================================

-- Dotaz 1: Spojení dvou tabulek – pacienti a jejich pojišťovny
-- Vypíše jméno, příjmení a název pojišťovny každého pacienta.
-- Slouží například k přehledu pojišťoven registrovaných pacientů.
SELECT p.jmeno, p.prijmeni, po.nazev AS pojistovna
FROM pacienti p
JOIN pojistovny po ON p.cislo_pojistovny = po.cislo_pojistovny;


-- Dotaz 2: Spojení dvou tabulek – návštěvy a pacienti
-- Vypíše datum, typ návštěvy a jméno pacienta pro každou návštěvu.
-- Slouží k zobrazení přehledu návštěv seřazených dle data.
SELECT n.cislo_navstevy, n.datum_a_cas, n.typ_navstevy,
       p.jmeno || ' ' || p.prijmeni AS pacient
FROM navstevy n
JOIN pacienti p ON n.cislo_pacienta = p.cislo_pacienta
ORDER BY n.datum_a_cas;


-- Dotaz 3: Spojení tří tabulek – návštěvy, výkony, a jejich vazba
-- Vypíše datum návštěvy, jméno pacienta a název provedeného výkonu.
-- Slouží k přehledu provedených výkonů během každé návštěvy.
SELECT n.datum_a_cas, p.jmeno || ' ' || p.prijmeni AS pacient, v.nazev AS vykon
FROM navstevy n
JOIN pacienti p ON n.cislo_pacienta = p.cislo_pacienta
JOIN navsteva_vykon nv ON n.cislo_navstevy = nv.cislo_navstevy
JOIN vykony v ON nv.typ_vykonu = v.typ_vykonu
ORDER BY n.datum_a_cas;


-- Dotaz 4: GROUP BY s agregační funkcí – počet návštěv na pacienta
-- Vypíše celkový počet návštěv pro každého pacienta (jméno + příjmení).
-- Slouží lékaři k přehledu, kteří pacienti navštěvují ordinaci nejčastěji.
SELECT p.jmeno || ' ' || p.prijmeni AS pacient,
       COUNT(n.cislo_navstevy) AS pocet_navstev
FROM pacienti p
LEFT JOIN navstevy n ON p.cislo_pacienta = n.cislo_pacienta
GROUP BY p.jmeno, p.prijmeni
ORDER BY pocet_navstev DESC;


-- Dotaz 5: GROUP BY s agregační funkcí – počet předepsaných léků na návštěvu
-- Vypíše počet předepsaných léků pro každou návštěvu.
-- Slouží k analýze, při kterých návštěvách bylo předepsáno nejvíce léků.
SELECT n.cislo_navstevy, n.datum_a_cas,
       COUNT(pr.cislo_predpisu) AS pocet_predpisu
FROM navstevy n
LEFT JOIN predpisy pr ON n.cislo_navstevy = pr.cislo_navstevy
GROUP BY n.cislo_navstevy, n.datum_a_cas
ORDER BY pocet_predpisu DESC;


-- Dotaz 6: Predikát EXISTS – pacienti, kteří mají alespoň jedno očkování
-- Vypíše jméno a příjmení pacientů, pro které existuje záznam v tabulce ockovani.
-- Slouží k identifikaci pacientů, kteří byli očkováni.
SELECT p.jmeno, p.prijmeni
FROM pacienti p
WHERE EXISTS (
    SELECT 1
    FROM ockovani o
    WHERE o.cislo_pacienta = p.cislo_pacienta
);


-- Dotaz 7: Predikát IN s vnořeným SELECT – pacienti s plánovanou návštěvou
-- Vypíše jméno a příjmení pacientů, kteří mají nebo měli alespoň jednu plánovanou návštěvu.
-- Slouží sestře k rychlému přehledu, kteří pacienti jsou objednaní (nikoliv akutní).
SELECT p.jmeno, p.prijmeni
FROM pacienti p
WHERE p.cislo_pacienta IN (
    SELECT n.cislo_pacienta
    FROM navstevy n
    WHERE n.typ_navstevy = 'planovana'
);
