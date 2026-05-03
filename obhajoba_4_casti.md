# Podklady pro obhajobu 4. části projektu IDS

Tento dokument je připravený pro vás jako tahák a podklad pro obhajobu před cvičícím. Detailně vysvětluje vše, co bylo vytvořeno ve druhé polovině skriptu `xraskaj00_xzaoram00.sql`, abyste dokázali s jistotou odpovědět na dotazy, proč a jak byly dané prvky implementovány.

---

## 1. Databázové triggery (Spouštěče)

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

## 2. Uložené procedury (PL/SQL bloky)

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

## 3. EXPLAIN PLAN a Indexy

Toto je nejdůležitější část pro obhajobu, protože se na to učitelé hodně ptají.

*   **Původní stav (Bez indexu):** Máme agregační dotaz spojující `navstevy` s `predpisy`. Protože děláme `JOIN` přes `cislo_navstevy`, Oracle musí prohledávat tabulku `predpisy`, jestli dané číslo existuje. Z výroby (v Oraclu) se na cizí klíče automaticky *nevytváří* index. To znamená, že při velkém množství dat Oracle dělal sekvenční prohledávání celé tabulky předpisů, tzv. `TABLE ACCESS FULL`.
*   **Přidání indexu:** Založíme index `CREATE INDEX idx_predpisy_navsteva ON predpisy(cislo_navstevy);`.
*   **Nový stav (S indexem):** Když zavoláme `EXPLAIN PLAN` po vytvoření indexu, v exekučním plánu uvidíte u spojování tabulky předpisů strategii **`INDEX RANGE SCAN`**.
*   **Co říct vyučujícímu:** *"Indexem nad cizím klíčem v tabulce predpisy zamezujeme prohledávání celé tabulky z bodu A do bodu B (Full Table Scan). Oracle si díky vytvořenému B-Tree indexu ukáže rovnou na adresy správných řádků. Takto jsme náš JOIN optimalizovali."*

---

## 4. Přístupová práva (GRANT) a Materializovaný pohled

*   **GRANT:** Příkazy `GRANT ALL ON ... TO xzaoram00` zajišťují definici přístupových oprávnění (pokud jste s kolegou odevzdávali práce ze stejného db systému).
*   **Materializovaný pohled (`mv_pacienti_statistika`):** Běžný pohled (VIEW) je jen "uložený dotaz" a spouští se pokaždé znovu, když se ho ptáte. Materializovaný pohled fyzicky předpočítá a uloží svá data na disk jako klasická tabulka.
*   **K čemu je to dobré:** Osvědčuje se pro velmi těžké a složité analytické dotazy, které dlouho trvají a zatěžují systém. My zde agregujeme návštěvy. Aby v něm byla čerstvá data, tak se musí provádět tzv. Refresh (obnova). Zde jsme zvolili `REFRESH COMPLETE ON DEMAND`, protože data chceme případně počítat až manuálně dle naší poptávky.

---

## 5. Komplexní dotaz s klauzulí WITH a CASE

*   **Co dotaz zjišťuje:** Vrací nám přehlednou "nálepku" pro každého pacienta na základě jeho historické aktivity (kolik výkonů mu u nás bylo celkově provedeno).
*   **Jak to funguje uvnitř:**
    1.  **`WITH PacientVykonStat AS (...)`**: Slouží jako takzvaný Common Table Expression (CTE) - virtuální mezipohled platný jen pro tento jeden dotaz. Spočítejme si zde nejdříve čistou matematiku (pacient a jeho `COUNT(výkonů)`). Díky tomu je zbytek dotazu úhledný a přehledný.
    2.  **`CASE ... WHEN ... END`**: Přebírá hodnoty spočítané ve `WITH` bloku. Analyzuje je jako programátorský `switch`/`if-else` a na základě počtů přiřadí text, čímž vznikne dynamicky generovaný sloupec `kategorie_pece`.
*   **Co říct vyučujícímu:** *"Tento dotaz rozdělí pacienty do věrnostních a časově náročných skupin pro účely manažerského reportingu. Vyhnuli jsme se zbytečně složitým subselectům přímo ve FROMech, protože používáme přehledný blok WITH, na který se hlavní blok odkáže."*
