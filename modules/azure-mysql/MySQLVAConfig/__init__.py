import os
import json
import logging
from datetime import datetime
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
import pymysql

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables
KEY_VAULT_NAME = os.environ.get('KEY_VAULT_NAME')
SECRET_NAME = os.environ.get('SECRET_NAME')

# Required secret keys for validation
REQUIRED_SECRET_KEYS = [
    'sqlguard_username',
    'sqlguard_password',
    'endpoint',
    'port',
    'username',
    'password'
]

def validate_secret_schema(secret):
    """Validate that the secret contains all required keys."""
    missing_keys = [key for key in REQUIRED_SECRET_KEYS if key not in secret]
    if missing_keys:
        error_msg = f"Secret validation failed. Missing required keys: {', '.join(missing_keys)}"
        logger.error(error_msg)
        raise ValueError(error_msg)
    try:
        int(secret['port'])
    except (ValueError, TypeError) as e:
        error_msg = f"Secret validation failed. 'port' must be a valid integer, got: {secret.get('port')}"
        logger.error(error_msg)
        raise ValueError(error_msg)
    logger.info("Secret schema validation passed")
    return True

def get_mysql_credentials():
    """Retrieve MySQL credentials from Azure Key Vault"""
    try:
        logger.info(f"Retrieving MySQL credentials from Key Vault: {KEY_VAULT_NAME}")
        
        # Create Key Vault client using Managed Identity
        key_vault_uri = f"https://{KEY_VAULT_NAME}.vault.azure.net"
        credential = DefaultAzureCredential()
        client = SecretClient(vault_url=key_vault_uri, credential=credential)
        
        # Get the secret value
        logger.debug(f"Starting credential request from Key Vault: {SECRET_NAME}")
        secret = client.get_secret(SECRET_NAME)
        
        # Parse the secret JSON
        credentials = json.loads(secret.value)
        
        logger.debug(f"Completed credential request from Key Vault: {SECRET_NAME}")
        
        # Validate secret schema before proceeding
        validate_secret_schema(credentials)
        
        logger.info("Successfully retrieved and validated MySQL credentials")
        
        return {
            'sqlguard_username': credentials['sqlguard_username'],
            'sqlguard_password': credentials['sqlguard_password'],
            'endpoint': credentials['endpoint'],
            'port': int(credentials['port']),
            'username': credentials['username'],
            'password': credentials['password']
        }
    except Exception as e:
        logger.error(f"Error retrieving MySQL credentials: {e}")
        raise

def connect_to_mysql(credentials):
    """Connect to MySQL database with SSL"""
    try:
        logger.info(f"Connecting to MySQL at {credentials['endpoint']}:{credentials['port']} as {credentials['username']} with SSL")
        
        conn = pymysql.connect(
            host=credentials['endpoint'],
            port=credentials['port'],
            user=credentials['username'],
            password=credentials['password'],
            charset='utf8mb4',
            ssl={'ssl': True}
        )
        
        # Verify SSL connection
        cursor = conn.cursor()
        cursor.execute("SHOW STATUS LIKE 'Ssl_cipher'")
        ssl_status = cursor.fetchone()
        
        if ssl_status and ssl_status[1]:
            logger.info(f"SSL connection established with cipher: {ssl_status[1]}")
        else:
            logger.warning("SSL connection status could not be verified")
        
        cursor.close()
        logger.info("Successfully connected to MySQL")
        return conn
        
    except Exception as e:
        logger.error(f"Error connecting to MySQL: {e}")
        raise

def configure_va_user(conn, credentials):
    """Configure VA user with required permissions"""
    cursor = None
    operation_details = []
    start_time = datetime.now()
    
    try:
        cursor = conn.cursor()
        
        # Create or update sqlguard user
        logger.info(f"Creating/updating user {credentials['sqlguard_username']}")
        try:
            # Check if user exists
            check_user_sql = "SELECT User FROM mysql.user WHERE User = %s"
            cursor.execute(check_user_sql, (credentials['sqlguard_username'],))
            user_exists = cursor.fetchone()
            
            if user_exists:
                # Update existing user's password
                create_user_sql = "ALTER USER %s@'%%' IDENTIFIED BY %s"
                cursor.execute(create_user_sql, (credentials['sqlguard_username'], credentials['sqlguard_password']))
                logger.info(f"Updated password for existing user {credentials['sqlguard_username']}")
            else:
                # Create new user
                create_user_sql = "CREATE USER %s@'%%' IDENTIFIED BY %s"
                cursor.execute(create_user_sql, (credentials['sqlguard_username'], credentials['sqlguard_password']))
                logger.info(f"Created new user {credentials['sqlguard_username']}")
            
            operation_details.append({"operation": "create_sqlguard_user", "status": "success"})
        except Exception as e:
            logger.error(f"Failed to create/update user {credentials['sqlguard_username']}: {str(e)}")
            operation_details.append({"operation": "create_sqlguard_user", "status": "failed", "reason": str(e)})
            raise e
        
        # Grant SELECT on mysql.user to sqlguard
        logger.info(f"Granting SELECT on mysql.user to {credentials['sqlguard_username']}")
        try:
            grant_user_sql = "GRANT SELECT ON mysql.user TO %s@'%%'"
            cursor.execute(grant_user_sql, (credentials['sqlguard_username'],))
            operation_details.append({"operation": "grant_select_mysql_user", "status": "success"})
        except Exception as e:
            logger.error(f"Failed to grant SELECT on mysql.user: {str(e)}")
            operation_details.append({"operation": "grant_select_mysql_user", "status": "failed", "reason": str(e)})
            raise e
        
        # Grant SELECT on mysql.db to sqlguard
        logger.info(f"Granting SELECT on mysql.db to {credentials['sqlguard_username']}")
        try:
            grant_db_sql = "GRANT SELECT ON mysql.db TO %s@'%%'"
            cursor.execute(grant_db_sql, (credentials['sqlguard_username'],))
            operation_details.append({"operation": "grant_select_mysql_db", "status": "success"})
        except Exception as e:
            logger.error(f"Failed to grant SELECT on mysql.db: {str(e)}")
            operation_details.append({"operation": "grant_select_mysql_db", "status": "failed", "reason": str(e)})
            raise e
        
        # Grant SHOW DATABASES on *.* to sqlguard
        logger.info(f"Granting SHOW DATABASES on *.* to {credentials['sqlguard_username']}")
        try:
            grant_show_sql = "GRANT SHOW DATABASES ON *.* TO %s@'%%'"
            cursor.execute(grant_show_sql, (credentials['sqlguard_username'],))
            operation_details.append({"operation": "grant_show_databases", "status": "success"})
        except Exception as e:
            logger.error(f"Failed to grant SHOW DATABASES: {str(e)}")
            operation_details.append({"operation": "grant_show_databases", "status": "failed", "reason": str(e)})
            raise e
        
        # Apply the privileges
        logger.info("Flushing privileges")
        try:
            cursor.execute("FLUSH PRIVILEGES")
            operation_details.append({"operation": "flush_privileges", "status": "success"})
        except Exception as e:
            logger.error(f"Failed to flush privileges: {str(e)}")
            operation_details.append({"operation": "flush_privileges", "status": "failed", "reason": str(e)})
            raise e
        
        # Commit all changes
        conn.commit()
        logger.info("All operations committed successfully")
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        return {
            "status": "success",
            "duration_seconds": duration,
            "operations": operation_details
        }
        
    except Exception as e:
        logger.error(f"Error during VA user configuration: {str(e)}")
        logger.info("Attempting to rollback changes")
        try:
            conn.rollback()
            logger.info("Transaction rolled back successfully")
        except Exception as rb_error:
            logger.error(f"Failed to rollback transaction: {rb_error}")
        raise e
    finally:
        if cursor:
            cursor.close()

def main(req: func.HttpRequest) -> func.HttpResponse:
    """Azure Function entry point"""
    logger.info('Azure Function triggered for MySQL VA configuration')
    start_time = datetime.now()
    conn = None
    
    try:
        # Get MySQL credentials from Key Vault
        credentials = get_mysql_credentials()
        
        # Connect to MySQL
        conn = connect_to_mysql(credentials)
        
        # Configure VA user and permissions
        result = configure_va_user(conn, credentials)
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        response_body = {
            "success": True,
            "message": "VA configuration completed successfully",
            "timestamp": datetime.now().isoformat(),
            "duration_seconds": duration,
            "endpoint": credentials['endpoint'],
            "operations": result["operations"]
        }
        
        return func.HttpResponse(
            json.dumps(response_body, default=str),
            status_code=200,
            mimetype="application/json"
        )
        
    except Exception as e:
        logger.error(f"Function execution failed: {e}")
        
        error_body = {
            "success": False,
            "message": f"Function execution failed: {str(e)}",
            "timestamp": datetime.now().isoformat()
        }
        
        return func.HttpResponse(
            json.dumps(error_body),
            status_code=500,
            mimetype="application/json"
        )
        
    finally:
        # Always close the connection if it exists
        if conn:
            try:
                conn.close()
                logger.info("Closed MySQL connection")
            except Exception as close_error:
                logger.warning(f"Error closing MySQL connection: {str(close_error)}")

# Made with Bob
