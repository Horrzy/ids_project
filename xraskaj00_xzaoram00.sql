
-- Téma: Ordinace praktického lékaře
-- Autor: Jan Raška (xraskaj00), Matěj Zaoral (xzaoram00)

-- DROP PROCEDURES A MATERIALIZED VIEWS

DROP PROCEDURE proc_statistika_pacienta;
DROP PROCEDURE proc_vypis_planovanych_navstev;
DROP MATERIALIZED VIEW mv_pacienti_statistika;

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




-- SELECT DOTAZY

-- Spojení dvou tabulek – pacienti a jejich pojišťovny
-- Vypíše jméno, příjmení a název pojišťovny každého pacienta.
SELECT p.jmeno, p.prijmeni, po.nazev AS pojistovna
FROM pacienti p
JOIN pojistovny po ON p.cislo_pojistovny = po.cislo_pojistovny;


-- Spojení dvou tabulek – návštěvy a pacienti
-- Vypíše datum, typ návštěvy a jméno pacienta pro každou návštěvu.
SELECT n.cislo_navstevy, n.datum_a_cas, n.typ_navstevy,
       p.jmeno || ' ' || p.prijmeni AS pacient
FROM navstevy n
JOIN pacienti p ON n.cislo_pacienta = p.cislo_pacienta
ORDER BY n.datum_a_cas;


-- Spojení tří tabulek – návštěvy, výkony, a jejich vazba
-- Vypíše datum návštěvy, jméno pacienta a název provedeného výkonu.
SELECT n.datum_a_cas, p.jmeno || ' ' || p.prijmeni AS pacient, v.nazev AS vykon
FROM navstevy n
JOIN pacienti p ON n.cislo_pacienta = p.cislo_pacienta
JOIN navsteva_vykon nv ON n.cislo_navstevy = nv.cislo_navstevy
JOIN vykony v ON nv.typ_vykonu = v.typ_vykonu
ORDER BY n.datum_a_cas;


-- GROUP BY s agregační funkcí – počet návštěv na pacienta
-- Vypíše celkový počet návštěv pro každého pacienta (jméno + příjmení).
SELECT p.jmeno || ' ' || p.prijmeni AS pacient,
       COUNT(n.cislo_navstevy) AS pocet_navstev
FROM pacienti p
LEFT JOIN navstevy n ON p.cislo_pacienta = n.cislo_pacienta
GROUP BY p.jmeno, p.prijmeni
ORDER BY pocet_navstev DESC;


-- GROUP BY s agregační funkcí – počet předepsaných léků na návštěvu
-- Vypíše počet předepsaných léků pro každou návštěvu.
SELECT n.cislo_navstevy, n.datum_a_cas,
       COUNT(pr.cislo_predpisu) AS pocet_predpisu
FROM navstevy n
LEFT JOIN predpisy pr ON n.cislo_navstevy = pr.cislo_navstevy
GROUP BY n.cislo_navstevy, n.datum_a_cas
ORDER BY pocet_predpisu DESC;


-- Predikát EXISTS – pacienti, kteří mají alespoň jedno očkování
-- Vypíše jméno a příjmení pacientů, pro které existuje záznam v tabulce ockovani.
SELECT p.jmeno, p.prijmeni
FROM pacienti p
WHERE EXISTS (
    SELECT 1
    FROM ockovani o
    WHERE o.cislo_pacienta = p.cislo_pacienta
);


-- Predikát IN s vnořeným SELECT – pacienti s plánovanou návštěvou
-- Vypíše jméno a příjmení pacientů, kteří mají nebo měli alespoň jednu plánovanou návštěvu.
SELECT p.jmeno, p.prijmeni
FROM pacienti p
WHERE p.cislo_pacienta IN (
    SELECT n.cislo_pacienta
    FROM navstevy n
    WHERE n.typ_navstevy = 'planovana'
);

SET SERVEROUTPUT ON;


-- Trigger 1: Kontrola věku pacienta při vkládání (datum narození nesmí být v budoucnosti)
CREATE OR REPLACE TRIGGER trg_kontrola_data_narozeni
BEFORE INSERT OR UPDATE ON pacienti
FOR EACH ROW
BEGIN
    IF :NEW.datum_narozeni > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20001, 'Datum narození nemůže být v budoucnosti!');
    END IF;
END;
/

-- Trigger 2: Kontrola očkování (datum očkování nesmí předcházet datu narození pacienta)
CREATE OR REPLACE TRIGGER trg_kontrola_ockovani_vek
BEFORE INSERT OR UPDATE ON ockovani
FOR EACH ROW
DECLARE
    v_datum_narozeni pacienti.datum_narozeni%TYPE;
BEGIN
    SELECT datum_narozeni INTO v_datum_narozeni
    FROM pacienti
    WHERE cislo_pacienta = :NEW.cislo_pacienta;

    IF :NEW.datum_ockovani < v_datum_narozeni THEN
        RAISE_APPLICATION_ERROR(-20002, 'Datum očkování nemůže být před datem narození pacienta!');
    END IF;
END;
/

-- Předvedení triggerů:
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- TEST TRIGGERŮ ---');
    -- Test Triggeru 1: Pacient narozený v budoucnosti
    BEGIN
        INSERT INTO pacienti (cislo_pacienta, jmeno, prijmeni, rodne_cislo, datum_narozeni, cislo_pojistovny)
        VALUES (seq_pacienti.NEXTVAL, 'Cestovatel', 'Včase', '991231/9999', SYSDATE + 100, 111);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Zachycena chyba z trg_kontrola_data_narozeni: ' || SQLERRM);
    END;

    -- Test Triggeru 2: Očkování před narozením
    BEGIN
        INSERT INTO ockovani (id_ockovani, datum_ockovani, cislo_pacienta, cislo_navstevy, typ_ockovani_id)
        VALUES (seq_ockovani.NEXTVAL, TO_DATE('1970-01-01', 'YYYY-MM-DD'), 1, 1, 1);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Zachycena chyba z trg_kontrola_ockovani_vek: ' || SQLERRM);
    END;
END;
/

-- Procedura 1: Vyhledá statistiky pacienta podle ID a vypíše je
CREATE OR REPLACE PROCEDURE proc_statistika_pacienta (p_id_pacienta IN INTEGER)
AS
    v_jmeno pacienti.jmeno%TYPE;
    v_prijmeni pacienti.prijmeni%TYPE;
    v_pocet_navstev INTEGER;
BEGIN
    SELECT jmeno, prijmeni INTO v_jmeno, v_prijmeni
    FROM pacienti
    WHERE cislo_pacienta = p_id_pacienta;

    SELECT COUNT(*) INTO v_pocet_navstev
    FROM navstevy
    WHERE cislo_pacienta = p_id_pacienta;

    DBMS_OUTPUT.PUT_LINE('Pacient ' || v_jmeno || ' ' || v_prijmeni || ' měl celkem ' || v_pocet_navstev || ' návštěv(y).');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Chyba: Pacient s ID ' || p_id_pacienta || ' neexistuje.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Neznámá chyba: ' || SQLERRM);
END;
/

-- Procedura 2: Vypíše všechny pacienty, kteří mají plánovanou návštěvu pomocí kurzoru
CREATE OR REPLACE PROCEDURE proc_vypis_planovanych_navstev
AS
    CURSOR c_navstevy IS
        SELECT p.jmeno, p.prijmeni, n.datum_a_cas
        FROM pacienti p
        JOIN navstevy n ON p.cislo_pacienta = n.cislo_pacienta
        WHERE n.typ_navstevy = 'planovana'
        ORDER BY n.datum_a_cas;
        
    v_zaznam c_navstevy%ROWTYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Seznam plánovaných návštěv ---');
    OPEN c_navstevy;
    LOOP
        FETCH c_navstevy INTO v_zaznam;
        EXIT WHEN c_navstevy%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Pacient: ' || v_zaznam.jmeno || ' ' || v_zaznam.prijmeni || ' -> Termín: ' || TO_CHAR(v_zaznam.datum_a_cas, 'YYYY-MM-DD HH24:MI:SS'));
    END LOOP;
    CLOSE c_navstevy;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Chyba při výpisu návštěv: ' || SQLERRM);
        IF c_navstevy%ISOPEN THEN
            CLOSE c_navstevy;
        END IF;
END;
/

-- Předvedení procedur:
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- TEST PROCEDUR ---');
    -- Volání s existujícím ID
    proc_statistika_pacienta(1);
    -- Volání s neexistujícím ID (test výjimky)
    proc_statistika_pacienta(999);
    
    -- Volání výpisu z kurzoru
    proc_vypis_planovanych_navstev;
END;
/


-- EXPLAIN PLAN BEZ INDEXU
EXPLAIN PLAN FOR
SELECT n.cislo_navstevy, n.datum_a_cas, COUNT(pr.cislo_predpisu) AS pocet_predpisu
FROM navstevy n
LEFT JOIN predpisy pr ON n.cislo_navstevy = pr.cislo_navstevy
GROUP BY n.cislo_navstevy, n.datum_a_cas;

-- Výpis plánu provedení bez indexu
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Vytvoření indexu pro urychlení spojení podle cislo_navstevy v tabulce predpisy
CREATE INDEX idx_predpisy_navsteva ON predpisy(cislo_navstevy);

-- EXPLAIN PLAN S INDEXEM
EXPLAIN PLAN FOR
SELECT n.cislo_navstevy, n.datum_a_cas, COUNT(pr.cislo_predpisu) AS pocet_predpisu
FROM navstevy n
LEFT JOIN predpisy pr ON n.cislo_navstevy = pr.cislo_navstevy
GROUP BY n.cislo_navstevy, n.datum_a_cas;

-- Výpis plánu provedení s indexem (zde si na obhajobě všimněte přístupu přes INDEX RANGE SCAN namísto TABLE ACCESS FULL)
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);


-- Práva pro druhého člena týmu
GRANT ALL ON pacienti TO xzaoram00;
GRANT ALL ON navstevy TO xzaoram00;
GRANT ALL ON vykony TO xzaoram00;
GRANT ALL ON navsteva_vykon TO xzaoram00;
GRANT EXECUTE ON proc_statistika_pacienta TO xzaoram00;
GRANT EXECUTE ON proc_vypis_planovanych_navstev TO xzaoram00;

-- Materializovaný pohled agregující počty akutních a plánovaných návštěv pacienta.
-- V zadání se píše, že patří druhému členovi a používá tabulky prvního. 
-- Zde jej definujeme přímo, jako by skript spouštěl xzaoram00, ale dáváme práva k čtení druhému.
CREATE MATERIALIZED VIEW mv_pacienti_statistika
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT p.cislo_pacienta, p.jmeno, p.prijmeni,
       SUM(CASE WHEN n.typ_navstevy = 'planovana' THEN 1 ELSE 0 END) AS pocet_planovanych,
       SUM(CASE WHEN n.typ_navstevy = 'akutni' THEN 1 ELSE 0 END) AS pocet_akutnich
FROM pacienti p
LEFT JOIN navstevy n ON p.cislo_pacienta = n.cislo_pacienta
GROUP BY p.cislo_pacienta, p.jmeno, p.prijmeni;

GRANT SELECT ON mv_pacienti_statistika TO xraskaj00;

-- Demonstrace materializovaného pohledu
SELECT * FROM mv_pacienti_statistika;

-- Následující dotaz získá informace o aktivitě a nákladech na výkony pacientů.
-- Používá:
-- 1. WITH (dočasný pohled 'PacientVykonStat' pro zjištění celkového počtu výkonů na pacienta)
-- 2. CASE (rozdělení pacientů do logických kategorií na základě jejich aktivity)
WITH PacientVykonStat AS (
    SELECT p.cislo_pacienta,
           p.jmeno,
           p.prijmeni,
           COUNT(nv.typ_vykonu) as pocet_vykonu
    FROM pacienti p
    LEFT JOIN navstevy n ON p.cislo_pacienta = n.cislo_pacienta
    LEFT JOIN navsteva_vykon nv ON n.cislo_navstevy = nv.cislo_navstevy
    GROUP BY p.cislo_pacienta, p.jmeno, p.prijmeni
)
SELECT cislo_pacienta,
       jmeno,
       prijmeni,
       pocet_vykonu,
       CASE
           WHEN pocet_vykonu = 0 THEN 'Bez zásahů (preventivní režim)'
           WHEN pocet_vykonu BETWEEN 1 AND 2 THEN 'Běžná péče'
           ELSE 'Zvýšená zdravotní péče (aktivní pacient)'
       END AS kategorie_pece
FROM PacientVykonStat
ORDER BY pocet_vykonu DESC;
