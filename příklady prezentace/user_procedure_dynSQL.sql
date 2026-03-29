-- Ukázka použití uložené procedury s pøíkazy dynamického SQL pro vytvoøení uživatele (úètu)
-- Je potøeba mít právo vytváøet úèty, tj. práva administrátora

DROP USER "xstudent" CASCADE;
DROP ROLE studentrole;    -- Nepoužijeme pøi vytváøení uvozovky (pro ilustraci dopadu)

-- Vytvoøení role
CREATE ROLE studentrole;  -- V systémovém katalobu bude jako STUDENTROLE

-- Pøiøazení pøeddefinované role RESOURCE a systémového práva CREATE SESSION;
GRANT RESOURCE, CREATE SESSION TO Studentrole;

-- Pøi vytváøení uložené procedury lze pøidat AUTHID CURRENT_USER øíká, že pøi spuštìní 
-- má procedura bìžet s právy uživatele, který ji spouští a ne vlastníka (implicitnì). 
-- V pøípadì práv vlastníka se uplatòují jen privilegia pøiøazená pøímo, nikoliv pøiøazením rolí.
CREATE OR REPLACE PROCEDURE create_user (login IN VARCHAR, passwd IN VARCHAR) AUTHID CURRENT_USER
IS
  user_login VARCHAR(128);
  user_passwd VARCHAR(4000);
BEGIN
  user_login:=login;
  user_passwd:=passwd;
  IF (user_passwd IS NULL) THEN
    user_passwd:=login;
  ELSE user_passwd:=passwd;
  END IF; 
-- vytvoøení uživatele
  EXECUTE IMMEDIATE 'CREATE USER "'||user_login||'" PROFILE "DEFAULT" IDENTIFIED BY "'||user_passwd||'" 
  DEFAULT TABLESPACE USERS
  QUOTA 10 M ON USERS
  ACCOUNT UNLOCK';
  -- pøiøazeni role uživateli  
  EXECUTE IMMEDIATE 'GRANT "STUDENTROLE" TO "'||user_login||'"';
 END;
/
show errors;

-- Volání uložené procedury -> vytvoøení uživatele 'xstudent' ne 'STUDENT'
EXECUTE create_user ('xstudent',NULL);  

-- Výpis uživatelù, vèetnì "xstudent"
SELECT * FROM ALL_USERS;

-- Výpis jemu pøiøazených rolí
SELECT * FROM DBA_ROLE_PRIVS WHERE grantee = 'xstudent';
-- Výpis jemu pøímo pøiøazených systémových práv
SELECT * FROM DBA_SYS_PRIVS WHERE grantee = 'xstudent';
-- Výpis jemu pøímo pøiøazených práv k objektùm
SELECT * FROM DBA_TAB_PRIVS WHERE grantee = 'xstudent';
-- Výpis pøímo pøiøazených systémových práv roli STUDENTROLE 
SELECT * FROM DBA_SYS_PRIVS WHERE grantee = 'STUDENTROLE';

----------------------------------------------------------------------------
-- Následující pøíkazy je potøeba provést v rámci pøipojení student/xstudent,
-- napø. vytvoøením nového spojení v SQL Developeru a pøepnutím na nìj nebo
-- použitím pøíkazù DISCONNECT a CONNECT xstudent/xstudent v SQL Plus

-- Takto lze zjistit pøihlášeného uživatele
SELECT USER FROM dual;

-- Vytvoøení tabulky ve schématu nového uživatele, vložení øádku a pøeètení
CREATE TABLE t (c INTEGER);
INSERT INTO t VALUES(1);
SELECT * FROM t;

-- Výpis rolí pøiøazených pøihlášenému uživateli (xstudent)
SELECT * FROM USER_ROLE_PRIVS;
-- Výpis jemu pøímo pøiøazených systémových práv
SELECT * FROM USER_SYS_PRIVS;
-- Výpis jemu pøímo pøiøazených práv k objektùm
SELECT * FROM USER_SYS_PRIVS;

