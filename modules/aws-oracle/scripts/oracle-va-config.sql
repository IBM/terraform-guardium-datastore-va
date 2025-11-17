--==================================================================================================================================================
-- ------------------------------
-- Description
-- ------------------------------
-- Database Type: Oracle
--
-- This script creates a 'gdmmonitor' role required for Assessment on the Oracle autonomous services.
--
--
-- This script does not create a user.  You should grant the roles created in this script to any Oracle user(s) that you 
-- choose to perform security assessment scan.  If you choose to create a new user for this function, the syntax 
-- can be as simple as:  
--
--			create user <username> identified by some_Passw0rd;  
--                      grant connect to <username>;
--
--  To run this script using Oracle SQL Developer:
--
--	connect as the ADMIN account;
--	Run gdmmonitor-ora-autonomous.sql;
--	grant gdmmonitor to <username>;
--
-- ------------------------------
-- after running this script
-- ------------------------------
-- need to assign this role to user(s) using the following command:
--
--    GRANT gdmmonitor to <username>;
--
--
-- 20211021:  Create gdmmonitor-ora-autonomous.sql based on research and testing in Oracle 21c autonomous cloud.
--         :  It is important to grant READ instead of SELECT on various SYS objects.  ADMIN in most case cannot grant SELECT on SYS objects.
--==================================================================================================================================================

spool gdmmonitor-ora.log
set serveroutput on format wrapped size 1000000;
set linesize 80
set pagesize 44
clear scr

declare
	type RoleMembers is table of DBA_ROLE_PRIVS.GRANTEE%type;
	members RoleMembers;
	objectExists number;
	memberCount number;
	type Funs is table of varchar2(255);
	pwVerifyFuns Funs;
	pwVerifyFun varchar2(255);

begin

	dbms_output.put_line('>>>==========================================================>>>');
	dbms_output.put_line('>>>  Creating the GDMMONITOR role...');
	dbms_output.put_line('>>>==========================================================>>>');

	-- Check whether the role already exists
	dbms_output.put_line('==> Checking whether role: "GDMMONITOR" already exists.');
	begin
		select 1 into objectExists
		from DBA_ROLES
		where ROLE = 'GDMMONITOR';
		exception
			when NO_DATA_FOUND then
				objectExists := 0;
	end;

	-- If the role exists, preserve the users and drop the role
	if (objectExists = 1) then
		dbms_output.put_line('==> Role: "GDMMONITOR" exists.');

		-- Get the count of members for later iteration
		select count(*) into memberCount
		from DBA_ROLE_PRIVS prv
		where prv.GRANTED_ROLE = 'GDMMONITOR';

		-- If we have members, capture them for later re-adding
		if (memberCount > 0) then
		  dbms_output.put_line('==> Preserving (' || memberCount || ') GDMMONITOR role members.');
		  select prv.GRANTEE bulk collect into members
		  from DBA_ROLE_PRIVS prv
		  where prv.GRANTED_ROLE = 'GDMMONITOR';
		end if;

		-- Drop the role
		dbms_output.put_line('==> Dropping role: "GDMMONITOR"');
		execute immediate 'drop role GDMMONITOR';
	end if;

	-- Create the role and grant privileges
	dbms_output.put_line('==> Creating role: "GDMMONITOR".');
	execute immediate 'create role GDMMONITOR';
	dbms_output.put_line('==> Granting CONNECT to GDMMONITOR');
	execute immediate 'grant CONNECT to GDMMONITOR';
	dbms_output.put_line('==> Granting SELECT_CATALOG_ROLE to GDMMONITOR');	
  	execute immediate 'grant SELECT_CATALOG_ROLE to GDMMONITOR';
  
  	-- Grant READ on DBA_USERS_WITH_DEFPWD if it exists
	begin
		select 1 into objectExists
		from ALL_OBJECTS
		where OWNER = 'SYS' and OBJECT_NAME = 'DBA_USERS_WITH_DEFPWD';
		exception
			when NO_DATA_FOUND then
				objectExists := 0;
				dbms_output.put_line('==>        ' || SQLERRM);
	end;

	if (objectExists = 1) then
		dbms_output.put_line('==> Granting READ on SYS.DBA_USERS_WITH_DEFPWD');
		begin
			execute immediate 'grant READ on SYS.DBA_USERS_WITH_DEFPWD to GDMMONITOR';
			exception when OTHERS then
			dbms_output.put_line('==> ERROR:   Could not grant SELECT on SYS.DBA_USERS_WITH_DEFPWD.');
			dbms_output.put_line('==>          Please make sure the script runner has sufficient privileges.');
			dbms_output.put_line('==>          ' || SQLERRM);
		end;
	end if;


  	-- Grant READ on AUDIT_UNIFIED_POLICIES if it exists
	begin
		select 1 into objectExists
		from ALL_OBJECTS
		where OWNER = 'SYS' and OBJECT_NAME = 'AUDIT_UNIFIED_POLICIES';
		exception
			when NO_DATA_FOUND then
				objectExists := 0;
				dbms_output.put_line('==>        ' || SQLERRM);
	end;

	if (objectExists = 1) then
		dbms_output.put_line('==> Granting READ on SYS.AUDIT_UNIFIED_POLICIES');
		begin
			execute immediate 'grant READ on SYS.AUDIT_UNIFIED_POLICIES to GDMMONITOR';
			exception when OTHERS then
			dbms_output.put_line('==> ERROR:   Could not grant SELECT on SYS.AUDIT_UNIFIED_POLICIES.');
			dbms_output.put_line('==>          Please make sure the script runner has sufficient privileges.');
			dbms_output.put_line('==>          ' || SQLERRM);
		end;
	end if;


  	-- Grant READ on AUDIT_UNIFIED_ENABLED_POLICIES if it exists
	begin
		select 1 into objectExists
		from ALL_OBJECTS
		where OWNER = 'SYS' and OBJECT_NAME = 'AUDIT_UNIFIED_ENABLED_POLICIES';
		exception
			when NO_DATA_FOUND then
				objectExists := 0;
				dbms_output.put_line('==>        ' || SQLERRM);
	end;

	if (objectExists = 1) then
		dbms_output.put_line('==> Granting READ on SYS.AUDIT_UNIFIED_ENABLED_POLICIES');
		begin
			execute immediate 'grant READ on SYS.AUDIT_UNIFIED_ENABLED_POLICIES to GDMMONITOR';
			exception when OTHERS then
			dbms_output.put_line('==> ERROR:   Could not grant SELECT on SYS.AUDIT_UNIFIED_ENABLED_POLICIES.');
			dbms_output.put_line('==>          Please make sure the script runner has sufficient privileges.');
			dbms_output.put_line('==>          ' || SQLERRM);
		end;
	end if;


	
	-- Grant the user password validation function
	select LIMIT bulk collect into pwVerifyFuns
	from DBA_PROFILES
	where RESOURCE_NAME = 'PASSWORD_VERIFY_FUNCTION'
	and LIMIT not in ('UNLIMITED', 'NULL', 'DEFAULT', 'FROM ROOT');

	-- Loop through potentially multiple functions and grant each of them
	for i in 1..pwVerifyFuns.count loop
		pwVerifyFun:=pwVerifyFuns(i);
		if (length(pwVerifyFun) > 0) then
			dbms_output.put_line('==> Granting EXECUTE on password verification function to gdmmonitor.');
			begin
				execute immediate 'grant EXECUTE on SYS.' || pwVerifyFun || ' TO gdmmonitor';
				exception when OTHERS then
					dbms_output.put_line('==> ERROR:   Could not grant execute on the password verify function.');
					dbms_output.put_line('==>          Please make sure the script runner has grant privileges.');
					dbms_output.put_line('==>          ' || SQLERRM);
			end;
		else
			dbms_output.put_line('==>  Password Verification Function was not found.');
		end if;
	end loop;

  -- Re-add existing members, if any
  if (memberCount > 0) then
    dbms_output.put_line('==> Restoring (' || memberCount || ') GDMMONITOR role members.');
    for i in 1..memberCount loop
      dbms_output.put_line('==>    Restoring member: ' || members(i) );
      execute immediate 'grant GDMMONITOR to ' || members(i);
    end loop;
  end if;

  dbms_output.put_line('<<<==========================================================<<<');
  dbms_output.put_line('<<<  ...Creation of the gdmmonitor role is complete!');
  dbms_output.put_line('<<<==========================================================<<<');
end;
/

spool off
