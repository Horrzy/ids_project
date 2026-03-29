begin
    null;
end;
/

declare
    a integer;
begin
    a:=20;
end;
/

select * from klient;

declare
    var1 varchar(20);
    var2 varchar(20);
begin
    var1 := 'Tomkova 34';
    select jmeno into var2 from klient where ulice = var1;
end;
/

declare
    var1 varchar(20);
    var2 klient.jmeno%type;
begin
    var1 := 'Tomkova 34';
    select jmeno into var2 from klient where ulice = var1;
    dbms_output.put_line (var2);
end;
/

set serveroutput on;

declare   
  v_sum     ucet.stav%TYPE; 
begin
  SELECT SUM(stav)  
  INTO v_sum
  FROM ucet
  WHERE	pobocka = 'Jánská';
  dbms_output.put_line (v_sum); 
end;
/

declare 
    type rectype is record (a int, b varchar(20));
    rec rectype;
begin
    rec.a := 120;
    rec.b := 'text';
    dbms_output.put_line (rec.a || '  ' || rec.b);
end;
/

declare
    rec klient%ROWTYPE;
begin
    select * into rec from klient where ulice = 'Tomkova 34';
    dbms_output.put_line (rec.r_cislo || '  ' || rec.jmeno  || '  ' || rec.ulice  || '  ' || rec.mesto);
end;
/

declare 
    cursor curs1 is select * from klient;
    rec klient%ROWTYPE;
begin
    open curs1;
    loop
        fetch curs1 into rec;
        exit when curs1%NOTFOUND;
        dbms_output.put_line (rec.r_cislo || '  ' || rec.jmeno  || '  ' || rec.ulice  || '  ' || rec.mesto);
    end loop;
    close curs1;
end;
/

declare 
    cursor curs1 is select * from klient;
    rec klient%ROWTYPE;
begin
    for rec in curs1 loop
        if (rec.mesto = 'Brno') then
            dbms_output.put_line (rec.r_cislo || '  ' || rec.jmeno  || '  ' || rec.ulice  || '  ' || rec.mesto);
        end if;
    end loop;
end;
/

declare 
    rec klient%ROWTYPE;
begin
    for rec in (select * from klient) loop
        if (rec.mesto = 'Brno') then
            dbms_output.put_line (rec.r_cislo || '  ' || rec.jmeno  || '  ' || rec.ulice  || '  ' || rec.mesto);
        end if;
    end loop;
end;
/

declare 
    a numeric(5,2);
begin
    a:=10/0;
exception 
    when zero_divide then dbms_output.put_line ('Deleni nulou!!!');
end;
/

declare
    var1 varchar(20);
    var2 klient.jmeno%type;
begin
    var1 := 'Tomkova 34';
    select jmeno into var2 from klient where ulice = var1;
    dbms_output.put_line (var2);
exception
    when no_data_found then dbms_output.put_line('Nenalezeno!');
end;
/

declare 
    e_invalid_client exception;
begin
    update klient set mesto = 'Praha'
    where jmeno = 'Jan Novák';
    if SQL%NOTFOUND then 
        RAISE e_invalid_client;
    end if;
    commit;
exception
    when e_invalid_client then dbms_output.put_line('Neplatny klient');
end;
/

begin
    raise_application_error (-20222, 'Nejaka chyba');
end;
/

CREATE OR REPLACE TRIGGER aktualizuj_pobocku
	AFTER UPDATE OF nazev ON Pobocka
	REFERENCING OLD AS puvodni NEW AS novy
	FOR EACH ROW
BEGIN
	UPDATE Ucet SET pobocka = :novy.nazev
	WHERE pobocka = :puvodni.nazev;
END;
/

update pobocka set nazev = 'Panska'
where nazev = 'Jánská';

select * from pobocka;
select * from ucet;



CREATE OR REPLACE FUNCTION get_stav (account IN NUMBER)
  RETURN INTEGER
  IS acc_bal NUMBER(11,2);
  BEGIN
    SELECT stav
    INTO acc_bal
    FROM ucet
    WHERE c_uctu = account;
    RETURN (acc_bal);
  END;
/

select * from ucet;

declare
    stav INTEGER;
begin
    select get_stav (4320286)
    into stav
    from dual;
    dbms_output.put_line (stav);
end;
/

CREATE OR REPLACE PROCEDURE remove_account (acc_id NUMBER) AS
BEGIN
	DELETE FROM ucet 
	WHERE ucet.c_uctu = remove_account.acc_id;
END;
/

begin
     remove_account(1182648);
end;
/
