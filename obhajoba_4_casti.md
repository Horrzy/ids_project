# Kompletní podklady pro obhajobu projektu IDS (Části 1–4)

Tento dokument slouží jako ucelený tahák a podklad pro finální obhajobu celého projektu před cvičícím. Detailně vysvětluje jednotlivé konstrukce napříč celým SQL skriptem `xraskaj00_xzaoram00.sql`, abyste dokázali s jistotou obhájit, jak jste splnili zadání všech čtyř fází.

---

## ČÁST 1 a 2: Datový model, tabulky a integritní omezení

V této části se řešil samotný návrh databáze, převod z ER diagramu do relačního modelu a naplnění testovacími daty.

### 1. Generalizace a Specializace
*   **Kde je to v modelu:** Vztah mezi entitou `pacienti` (rodič/generalizace) a `pacienti_registrovani` (potomek/specializace). Dalším logickým podtypem jsou *akutní pacienti*, u kterých ale neevidujeme žádná dodatečná data.
*   **Jak je to implementováno:** Zvolili jsme metodu *samostatné tabulky pro každý podtyp*. V hlavní tabulce `pacienti` jsou uloženy všechny společné atributy (jméno, rodné číslo, adresa). Pokud se jedná o registrovaného pacienta, je pro něj vytvořen záznam v doplňující tabulce `pacienti_registrovani`, která se napojuje přes cizí klíč na primární klíč v `pacienti` a přidává dodatečný atribut `cislo_karty`.
*   **Co říct u obhajoby:** *"Generalizaci jsme převedli tak, že máme centrální tabulku `pacienti` pro sdílená data. Specifická data registrovaných pacientů ukládáme do oddělené tabulky propojené poměrem 1:1. Akutní pacienti vlastní tabulku nepotřebují, protože k nim neevidujeme žádné atributy navíc, stačí jim záznam v nadřazené tabulce."*

### 2. Speciální omezení hodnot (CHECK constraint)
*   **Kde je to implementováno:** Tabulka `pacienti`, sloupec `rodne_cislo`.
*   **Jak je to implementováno:** Omezení `CHK_rodne_cislo` s využitím regulárního výrazu: `REGEXP_LIKE(rodne_cislo, '^[0-9]{2}(0[1-9]|1[0-2]|5[1-9]|6[0-2])(0[1-9]|[12][0-9]|3[01])\/?[0-9]{3,4}$')`.
*   **Co říct u obhajoby:** *"Pro validaci rodného čísla jsme použili zabudovanou regulární funkci `REGEXP_LIKE`. Výraz dynamicky hlídá, že formát začíná dvojčíslím roku, měsíc obsahuje buď normální hodnotu (01-12) nebo přičteno 50 pro ženy (51-62). Následuje den, volitelné lomítko a na konci 3 až 4 číslice. Tím bráníme zápisu kompletních nesmyslů do databáze."*

### 3. Automatické generování primárního klíče
*   **Kde je to implementováno:** Tabulka `navstevy` (spouštěč `trg_navstevy_pk`).
*   **Jak je to implementováno:** Trigger nad tabulkou návštěv odchytí vkládání (INSERT). Pokud programátor v dotazu zapomněl definovat číslo návštěvy (vložil `NULL`), trigger si načte číslo ze sekvence `seq_navstevy` přes klauzuli `NEXTVAL` a IDčko automaticky dogeneruje.
*   **Co říct u obhajoby:** *"Splnili jsme to pomocí tzv. 'BEFORE INSERT' triggeru. Pokud se do sloupce primárního klíče posílá prázdná hodnota, náš trigger to zachytí a v řádku hodnotu nahradí novým platným unikátním číslem z připravené sekvence."*

---

## ČÁST 3: Pokročilé SQL dotazy (SELECT)

V této sekci jsme demonstrovali schopnost vytahovat z provázané databáze různorodé informace pomocí JOINů, agregací a vnořených poddotazů.

### 1. Dva dotazy se spojením 2 tabulek (JOIN)
*   **První dotaz:** Získá seznam pacientů a název jejich pojišťovny. Demonstruje základní propojení cizího klíče a primárního klíče.
*   **Druhý dotaz:** Spojí návštěvy a pacienty a vypíše hezky čitelný výstup (kdo a kdy měl návštěvu).

### 2. Dotaz se spojením 3 a více tabulek
*   **Jak funguje:** Spojuje celkem 4 tabulky - `navstevy`, `pacienti`, vazební `navsteva_vykon` a slovníkovou `vykony`.
*   **Co říct u obhajoby:** *"Tímto vícečetným vnitřním spojením (INNER JOIN) jsme dokázali vytáhnout jméno pacienta, datum konkrétní návštěvy a přes spojovací M:N tabulku dohledat přesný textový název lékařského výkonu, který se během návštěvy uskutečnil."*

### 3. Dva dotazy s agregační funkcí a klauzulí GROUP BY
*   **První agregace:** Počítá celkový počet návštěv pro každého pacienta přes `COUNT(n.cislo_navstevy)`.
    *   *Zajímavost pro obhajobu:* *"Záměrně používáme LEFT JOIN z pohledu tabulky pacientů. Díky tomu ve výpisu uvidíme i pacienty, kteří u nás ještě nikdy nebyli, s počtem návštěv 0."*
*   **Druhá agregace:** Obdobně počítá počet předepsaných léků v rámci konkrétní jedné historické návštěvy.

### 4. Dotaz s predikátem EXISTS
*   **Jak funguje:** Vyhledává pacienty, ke kterým už existuje záznam o aplikovaném očkování.
*   **Co říct u obhajoby:** *"EXISTS se zde skvěle hodí, protože funguje jako 'boolean'. Databáze nahlédne do tabulky očkování, a jakmile najde u daného pacienta první dávku, pacient jde hned na výstup. Databáze nemusí procházet další případné dávky daného pacienta, je to rychlejší než dělat velký JOIN."*

### 5. Dotaz s predikátem IN (vnořený SELECT)
*   **Jak funguje:** Filtruje pacienty, jejichž ID se nachází v dočasné množině hodnot generované vnořeným dotazem (najdi ID všech, co měli 'planovanou' návštěvu).
*   **Co říct u obhajoby:** *"Vnější dotaz se tak elegantně omezuje pouze na množinu ID pacientů naservírovanou zevnitř (subquery)."*

---

## ČÁST 4: Pokročilé objekty databáze

### 1. Databázové triggery (Spouštěče)

Zadání vyžadovalo dva netriviální triggery. Netriviální znamená, že nedělají jen primitivní věc jako generování sekvence (to už dělá váš první trigger ze 2. zadání).

### Trigger 1: `trg_kontrola_data_narozeni`
*   **Kdy se spouští:** `BEFORE INSERT OR UPDATE` nad tabulkou `pacienti`.
*   **Co dělá:** Kontroluje data na aplikační/logické úrovni. Zabudovaná podmínka hlídá, aby někdo omylem (nebo cíleně) nevytvořil pacienta s datem narození v budoucnosti (`> SYSDATE`).
*   **Co říct vyučujícímu:** *"Tento trigger zajišťuje sémantickou integritu – zabraňuje zadání pacienta z budoucnosti. Místo tichého selhání vrací vlastní uživatelskou chybu pomocí procedury `RAISE_APPLICATION_ERROR` (-20001)."*

### Trigger 2: `trg_kontrola_ockovani_vek`
*   **Kdy se spouští:** `BEFORE INSERT OR UPDATE` nad tabulkou `ockovani`.
*   **Co dělá:** Zajišťuje logiku vazby mezi dvěma tabulkami. Když přidáváte očkování pro pacienta, trigger si nejdřív dynamicky přesunul z tabulky `pacienti` (`SELECT datum_narozeni INTO v_datum_narozeni`) jeho narození. Poté ověří, zda datum očkování není starší než datum, kdy se pacient vůbec narodil.
*   **Co říct vyučujícímu:** *"Druhý trigger je složitější, protože kombinuje data z vkládaného řádku (`:NEW`) s dotazem do jiné tabulky, aby ověřil logickou provázanost entit."*

---

### 2. Uložené procedury (PL/SQL bloky)

Museli jsme předvést kurzor, ošetření výjimek a vázané datové typy (`%TYPE` nebo `%ROWTYPE`).

### Procedura 1: `proc_statistika_pacienta`
*   **Co dělá:** Vyhledá pacienta podle vstupního parametru `p_id_pacienta`, vytáhne si jeho jméno a sečte mu počet návštěv. Výsledek vypíše na obrazovku.
*   **Důležité prvky pro obhajobu:**
    *   Využívá `%TYPE` (např. `v_jmeno pacienti.jmeno%TYPE`), což znamená, že deklarujeme proměnnou přesně tak velkou a takového typu, jaká je definice sloupce `jmeno` v tabulce. Pokud někdy v budoucnu tabulku zvětšíme z `VARCHAR(50)` na `VARCHAR(100)`, procedura bude pořád fungovat a nespadne.
    *   Má ošetřenou výjimku `WHEN NO_DATA_FOUND THEN ...` – pokud zavoláte ID pacienta, který v databázi neexistuje, procedura nezkolabuje do Oracle erroru, ale elegantně vypíše "Pacient s ID X neexistuje."

### Procedura 2: `proc_vypis_planovanych_navstev`
*   **Co dělá:** Demonstruje použití kurzoru. Vytiskne do konzole seznam všech lidí, u kterých evidujeme návštěvu s typem "planovana".
*   **Důležité prvky pro obhajobu:**
    *   Kurzor (`c_navstevy`) načte kompletní výsledek SELECT dotazu a drží ho v paměti.
    *   Následně pomocí struktury `%ROWTYPE` a cyklu `LOOP` záznamy jeden po druhém sekvenčně projdeme a vypíšeme. Podmínka `EXIT WHEN c_navstevy%NOTFOUND` zajistí bezpečné ukončení cyklu, jakmile kurzor vyčerpá data.

---

### 3. EXPLAIN PLAN a Indexy

Toto je nejdůležitější část pro obhajobu, protože se na to učitelé hodně ptají.

*   **Původní stav (Bez indexu):** Máme agregační dotaz spojující `navstevy` s `predpisy`. Protože děláme `JOIN` přes `cislo_navstevy`, Oracle musí prohledávat tabulku `predpisy`, jestli dané číslo existuje. Z výroby (v Oraclu) se na cizí klíče automaticky *nevytváří* index. To znamená, že při velkém množství dat Oracle dělal sekvenční prohledávání celé tabulky předpisů, tzv. `TABLE ACCESS FULL`.
*   **Přidání indexu:** Založíme index `CREATE INDEX idx_predpisy_navsteva ON predpisy(cislo_navstevy);`.
*   **Nový stav (S indexem):** Když zavoláme `EXPLAIN PLAN` po vytvoření indexu, v exekučním plánu uvidíte u spojování tabulky předpisů strategii **`INDEX RANGE SCAN`**.
*   **Co říct vyučujícímu:** *"Indexem nad cizím klíčem v tabulce predpisy zamezujeme prohledávání celé tabulky z bodu A do bodu B (Full Table Scan). Oracle si díky vytvořenému B-Tree indexu ukáže rovnou na adresy správných řádků. Takto jsme náš JOIN optimalizovali."*

---

### 4. Přístupová práva (GRANT) a Materializovaný pohled

*   **GRANT:** Příkazy `GRANT ALL ON ... TO xzaoram00` zajišťují definici přístupových oprávnění (pokud jste s kolegou odevzdávali práce ze stejného db systému).
*   **Materializovaný pohled (`mv_pacienti_statistika`):** Běžný pohled (VIEW) je jen "uložený dotaz" a spouští se pokaždé znovu, když se ho ptáte. Materializovaný pohled fyzicky předpočítá a uloží svá data na disk jako klasická tabulka.
*   **K čemu je to dobré:** Osvědčuje se pro velmi těžké a složité analytické dotazy, které dlouho trvají a zatěžují systém. My zde agregujeme návštěvy. Aby v něm byla čerstvá data, tak se musí provádět tzv. Refresh (obnova). Zde jsme zvolili `REFRESH COMPLETE ON DEMAND`, protože data chceme případně počítat až manuálně dle naší poptávky.

---

### 5. Komplexní dotaz s klauzulí WITH a CASE

*   **Co dotaz zjišťuje:** Vrací nám přehlednou "nálepku" pro každého pacienta na základě jeho historické aktivity (kolik výkonů mu u nás bylo celkově provedeno).
*   **Jak to funguje uvnitř:**
    1.  **`WITH PacientVykonStat AS (...)`**: Slouží jako takzvaný Common Table Expression (CTE) - virtuální mezipohled platný jen pro tento jeden dotaz. Spočítejme si zde nejdříve čistou matematiku (pacient a jeho `COUNT(výkonů)`). Díky tomu je zbytek dotazu úhledný a přehledný.
    2.  **`CASE ... WHEN ... END`**: Přebírá hodnoty spočítané ve `WITH` bloku. Analyzuje je jako programátorský `switch`/`if-else` a na základě počtů přiřadí text, čímž vznikne dynamicky generovaný sloupec `kategorie_pece`.
*   **Co říct vyučujícímu:** *"Tento dotaz rozdělí pacienty do věrnostních a časově náročných skupin pro účely manažerského reportingu. Vyhnuli jsme se zbytečně složitým subselectům přímo ve FROMech, protože používáme přehledný blok WITH, na který se hlavní blok odkáže."*
