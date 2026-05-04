-- ============================================================================
-- Manual Oracle VA User Setup Script
-- ============================================================================
-- This script creates the sqlguard user and grants necessary privileges
-- for Guardium Vulnerability Assessment
--
-- Run this as the admin user (DBA privileges required)
-- ============================================================================

-- Create the sqlguard user
CREATE USER sqlguard IDENTIFIED BY "SqlGuard456!";

-- Grant basic connection privileges
GRANT CREATE SESSION TO sqlguard;
GRANT CONNECT TO sqlguard;

-- Grant SELECT privileges on DBA views (required for VA)
GRANT SELECT ANY DICTIONARY TO sqlguard;
GRANT SELECT_CATALOG_ROLE TO sqlguard;

-- Grant specific DBA view access
GRANT SELECT ON DBA_USERS TO sqlguard;
GRANT SELECT ON DBA_ROLES TO sqlguard;
GRANT SELECT ON DBA_ROLE_PRIVS TO sqlguard;
GRANT SELECT ON DBA_SYS_PRIVS TO sqlguard;
GRANT SELECT ON DBA_TAB_PRIVS TO sqlguard;
GRANT SELECT ON DBA_PROFILES TO sqlguard;
GRANT SELECT ON DBA_OBJECTS TO sqlguard;
GRANT SELECT ON DBA_TABLES TO sqlguard;
GRANT SELECT ON DBA_VIEWS TO sqlguard;
GRANT SELECT ON DBA_SEQUENCES TO sqlguard;
GRANT SELECT ON DBA_SYNONYMS TO sqlguard;
GRANT SELECT ON DBA_CONSTRAINTS TO sqlguard;
GRANT SELECT ON DBA_INDEXES TO sqlguard;
GRANT SELECT ON DBA_TRIGGERS TO sqlguard;
GRANT SELECT ON DBA_SOURCE TO sqlguard;
GRANT SELECT ON DBA_PROCEDURES TO sqlguard;
GRANT SELECT ON DBA_AUDIT_TRAIL TO sqlguard;
GRANT SELECT ON DBA_AUDIT_POLICIES TO sqlguard;
GRANT SELECT ON V_$DATABASE TO sqlguard;
GRANT SELECT ON V_$INSTANCE TO sqlguard;
GRANT SELECT ON V_$VERSION TO sqlguard;
GRANT SELECT ON V_$PARAMETER TO sqlguard;

-- Verify user creation
SELECT username, account_status, created 
FROM dba_users 
WHERE username = 'SQLGUARD';

-- Show granted privileges
SELECT * FROM dba_sys_privs WHERE grantee = 'SQLGUARD';
SELECT * FROM dba_role_privs WHERE grantee = 'SQLGUARD';

COMMIT;

-- Made with Bob
