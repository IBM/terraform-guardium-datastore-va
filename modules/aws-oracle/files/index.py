import os
import boto3
import json
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """Lambda function to create Oracle VA user and configure gdmmonitor role"""
    try:
        logger.info("Oracle VA configuration Lambda started")
        
        # Import oracledb here to catch import errors
        try:
            import oracledb
            logger.info("oracledb library imported successfully")
        except ImportError as e:
            logger.error(f"Failed to import oracledb: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps({'error': 'oracledb library not found in Lambda package'})
            }
        
        # Get credentials from Secrets Manager
        secrets_client = boto3.client('secretsmanager', region_name=os.environ['SECRETS_REGION'])
        secret = secrets_client.get_secret_value(SecretId=os.environ['SECRETS_MANAGER_SECRET_ID'])
        creds = json.loads(secret['SecretString'])
        
        logger.info(f"Retrieved credentials for host: {creds['host']}")
        logger.info(f"Service name: {creds['service_name']}")
        logger.info(f"Will create user: {creds['sqlguard_username']}")
        
        # Connect to Oracle using thin mode (pure Python, no Instant Client needed)
        logger.info("Connecting to Oracle database...")
        connection = oracledb.connect(
            user=creds['username'],
            password=creds['password'],
            host=creds['host'],
            port=int(creds['port']),
            service_name=creds['service_name']
        )
        logger.info("Connected to Oracle successfully")
        
        cursor = connection.cursor()
        
        # Check if gdmmonitor role exists
        logger.info("Checking if gdmmonitor role exists...")
        cursor.execute("SELECT COUNT(*) FROM dba_roles WHERE role = 'GDMMONITOR'")
        role_exists = cursor.fetchone()[0] > 0
        
        if role_exists:
            logger.info("gdmmonitor role already exists, dropping and recreating...")
            # Get existing members
            cursor.execute("SELECT GRANTEE FROM DBA_ROLE_PRIVS WHERE GRANTED_ROLE = 'GDMMONITOR'")
            members = [row[0] for row in cursor.fetchall()]
            logger.info(f"Preserving {len(members)} role members: {members}")
            
            # Drop the role
            cursor.execute("DROP ROLE gdmmonitor")
            logger.info("Dropped existing gdmmonitor role")
        
        # Create gdmmonitor role
        logger.info("Creating gdmmonitor role...")
        cursor.execute("CREATE ROLE gdmmonitor")
        logger.info("gdmmonitor role created")
        
        # Grant basic privileges
        logger.info("Granting basic privileges to gdmmonitor...")
        cursor.execute("GRANT CONNECT TO gdmmonitor")
        cursor.execute("GRANT SELECT_CATALOG_ROLE TO gdmmonitor")
        
        # Grant READ permissions on system tables
        system_tables = [
            'DBA_USERS',
            'DBA_ROLES', 
            'DBA_ROLE_PRIVS',
            'DBA_SYS_PRIVS',
            'DBA_TAB_PRIVS',
            'DBA_PROFILES',
            'DBA_OBJECTS',
            'DBA_TABLES',
            'DBA_VIEWS',
            'DBA_SYNONYMS',
            'DBA_SEQUENCES',
            'DBA_PROCEDURES',
            'DBA_TRIGGERS',
            'DBA_CONSTRAINTS',
            'DBA_INDEXES'
        ]
        
        for table in system_tables:
            try:
                cursor.execute(f"GRANT READ ON SYS.{table} TO gdmmonitor")
                logger.info(f"Granted READ on SYS.{table}")
            except Exception as e:
                logger.warning(f"Could not grant READ on SYS.{table}: {str(e)}")
        
        # Grant READ on optional tables if they exist
        optional_tables = [
            'DBA_USERS_WITH_DEFPWD',
            'AUDIT_UNIFIED_POLICIES',
            'AUDIT_UNIFIED_ENABLED_POLICIES'
        ]
        
        for table in optional_tables:
            try:
                cursor.execute(f"SELECT COUNT(*) FROM ALL_OBJECTS WHERE OWNER = 'SYS' AND OBJECT_NAME = '{table}'")
                if cursor.fetchone()[0] > 0:
                    cursor.execute(f"GRANT READ ON SYS.{table} TO gdmmonitor")
                    logger.info(f"Granted READ on SYS.{table}")
            except Exception as e:
                logger.warning(f"Could not grant READ on SYS.{table}: {str(e)}")
        
        # Grant EXECUTE on password verification functions
        logger.info("Granting EXECUTE on password verification functions...")
        cursor.execute("""
            SELECT LIMIT 
            FROM DBA_PROFILES 
            WHERE RESOURCE_NAME = 'PASSWORD_VERIFY_FUNCTION' 
            AND LIMIT NOT IN ('UNLIMITED', 'NULL', 'DEFAULT', 'FROM ROOT')
        """)
        
        for row in cursor.fetchall():
            func_name = row[0]
            try:
                cursor.execute(f"GRANT EXECUTE ON SYS.{func_name} TO gdmmonitor")
                logger.info(f"Granted EXECUTE on SYS.{func_name}")
            except Exception as e:
                logger.warning(f"Could not grant EXECUTE on SYS.{func_name}: {str(e)}")
        
        # Restore previous members if any
        if role_exists and members:
            logger.info(f"Restoring {len(members)} role members...")
            for member in members:
                try:
                    cursor.execute(f"GRANT gdmmonitor TO {member}")
                    logger.info(f"Restored member: {member}")
                except Exception as e:
                    logger.warning(f"Could not restore member {member}: {str(e)}")
        
        # Check if sqlguard user exists
        logger.info(f"Checking if {creds['sqlguard_username']} user exists...")
        cursor.execute(f"SELECT COUNT(*) FROM dba_users WHERE username = UPPER('{creds['sqlguard_username']}')")
        user_exists = cursor.fetchone()[0] > 0
        
        if user_exists:
            logger.info(f"User {creds['sqlguard_username']} already exists, updating password...")
            cursor.execute(f"ALTER USER {creds['sqlguard_username']} IDENTIFIED BY \"{creds['sqlguard_password']}\"")
        else:
            logger.info(f"Creating user {creds['sqlguard_username']}...")
            cursor.execute(f"CREATE USER {creds['sqlguard_username']} IDENTIFIED BY \"{creds['sqlguard_password']}\"")
        
        # Grant privileges to sqlguard user
        logger.info(f"Granting privileges to {creds['sqlguard_username']}...")
        cursor.execute(f"GRANT CONNECT TO {creds['sqlguard_username']}")
        cursor.execute(f"GRANT gdmmonitor TO {creds['sqlguard_username']}")
        
        # Commit all changes
        connection.commit()
        logger.info("All changes committed successfully")
        
        # Verify the setup
        logger.info("Verifying setup...")
        cursor.execute(f"SELECT USERNAME FROM DBA_USERS WHERE USERNAME = UPPER('{creds['sqlguard_username']}')")
        user = cursor.fetchone()
        logger.info(f"User verified: {user[0] if user else 'NOT FOUND'}")
        
        cursor.execute(f"SELECT GRANTED_ROLE FROM DBA_ROLE_PRIVS WHERE GRANTEE = UPPER('{creds['sqlguard_username']}')")
        roles = [row[0] for row in cursor.fetchall()]
        logger.info(f"Roles granted to user: {roles}")
        
        # Close connection
        cursor.close()
        connection.close()
        logger.info("Database connection closed")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Oracle VA configuration completed successfully',
                'user': creds['sqlguard_username'],
                'roles': roles,
                'host': creds['host'],
                'service_name': creds['service_name']
            })
        }
        
    except oracledb.Error as e:
        error_obj, = e.args
        logger.error(f"Oracle error: {error_obj.code} - {error_obj.message}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Oracle database error',
                'code': error_obj.code,
                'message': error_obj.message
            })
        }
    except Exception as e:
        logger.error(f"Error: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

