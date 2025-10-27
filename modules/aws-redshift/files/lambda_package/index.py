import os
import boto3
import json
import logging
import sys
import subprocess
from datetime import datetime

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Install psycopg2 at runtime
try:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "psycopg2-binary==2.9.5", "-t", "/tmp"])
    sys.path.append("/tmp")
    import psycopg2
except Exception as e:
    logger.error(f"Error installing psycopg2: {e}")
    # Try to import anyway in case it's already installed
    import psycopg2

def get_redshift_credentials():
    """Retrieve Redshift credentials from AWS Secrets Manager"""
    try:
        # Get environment variables
        redshift_secret_name = os.environ['REDSHIFT_SECRET_NAME']
        sqlguard_secret_name = os.environ['SQLGUARD_SECRET_NAME']
        aws_region = os.environ['SECRETS_REGION']
        
        logger.info(f"Retrieving Redshift credentials from Secrets Manager")
        
        # Create a Secrets Manager client
        session = boto3.session.Session()
        client = session.client(
            service_name='secretsmanager',
            region_name=aws_region
        )
        
        # Get the Redshift password
        redshift_secret_response = client.get_secret_value(SecretId=redshift_secret_name)
        redshift_password = redshift_secret_response['SecretString']
        
        # Get the sqlguard password
        sqlguard_secret_response = client.get_secret_value(SecretId=sqlguard_secret_name)
        sqlguard_password = sqlguard_secret_response['SecretString']
        
        logger.info("Successfully retrieved credentials from Secrets Manager")
        
        return {
            'redshift_host': os.environ['REDSHIFT_HOST'],
            'redshift_port': os.environ['REDSHIFT_PORT'],
            'redshift_database': os.environ['REDSHIFT_DATABASE'],
            'redshift_username': os.environ['REDSHIFT_USERNAME'],
            'redshift_password': redshift_password,
            'sqlguard_username': os.environ['SQLGUARD_USERNAME'],
            'sqlguard_password': sqlguard_password
        }
    except Exception as e:
        logger.error(f"Error retrieving credentials from Secrets Manager: {e}")
        return None

def connect_to_redshift(credentials):
    """Connect to Redshift cluster"""
    try:
        # Connect to Redshift
        logger.info(f"Connecting to Redshift at {credentials['redshift_host']}:{credentials['redshift_port']} as {credentials['redshift_username']}")
        
        conn = psycopg2.connect(
            host=credentials['redshift_host'],
            port=credentials['redshift_port'],
            dbname=credentials['redshift_database'],
            user=credentials['redshift_username'],
            password=credentials['redshift_password']
        )
        conn.autocommit = True
        
        logger.info("Successfully connected to Redshift")
        return conn
    except Exception as e:
        logger.error(f"Failed to connect to Redshift: {e}")
        return None

def configure_va_user(conn, credentials):
    """Configure VA user and permissions in Redshift"""
    start_time = datetime.now()
    operation_details = []
    cursor = None
    
    try:
        # Set autocommit to False for transaction control
        conn.autocommit = False
        cursor = conn.cursor()
        
        # Create gdmmonitor group if it doesn't exist
        logger.info("Creating gdmmonitor group if it doesn't exist")
        try:
            # Check if group exists first
            cursor.execute("SELECT 1 FROM pg_group WHERE groname = 'gdmmonitor';")
            if cursor.fetchone():
                logger.info("Group gdmmonitor already exists")
                operation_details.append({"operation": "create_gdmmonitor_group", "status": "skipped", "reason": "Group already exists"})
            else:
                cursor.execute("CREATE GROUP gdmmonitor;")
                operation_details.append({"operation": "create_gdmmonitor_group", "status": "success"})
        except Exception as e:
            logger.error(f"Failed to create gdmmonitor group: {str(e)}")
            operation_details.append({"operation": "create_gdmmonitor_group", "status": "failed", "reason": str(e)})
        
        logger.info(f"Creating user {credentials['sqlguard_username']} if it doesn't exist")
        try:
            # Check if user exists first
            cursor.execute(f"SELECT 1 FROM pg_user WHERE usename = '{credentials['sqlguard_username']}';")
            if cursor.fetchone():
                logger.info(f"User {credentials['sqlguard_username']} already exists")
                # Update password for existing user
                cursor.execute(f"ALTER USER {credentials['sqlguard_username']} PASSWORD '{credentials['sqlguard_password']}';")
                operation_details.append({"operation": "create_sqlguard_user", "status": "skipped", "reason": "User already exists, password updated"})
            else:
                cursor.execute(f"CREATE USER {credentials['sqlguard_username']} PASSWORD '{credentials['sqlguard_password']}';")
                operation_details.append({"operation": "create_sqlguard_user", "status": "success"})
        except Exception as e:
            logger.error(f"Failed to create/update user {credentials['sqlguard_username']}: {str(e)}")
            operation_details.append({"operation": "create_sqlguard_user", "status": "failed", "reason": str(e)})
        
        logger.info(f"Adding user {credentials['sqlguard_username']} to gdmmonitor group")
        try:
            # Just try to add the user to the group - if they're already a member, Redshift will handle it
            cursor.execute(f"ALTER GROUP gdmmonitor ADD USER {credentials['sqlguard_username']};")
            operation_details.append({"operation": "add_user_to_group", "status": "success"})
            logger.info(f"User {credentials['sqlguard_username']} added to gdmmonitor group")
        except Exception as e:
            logger.error(f"Failed to add user to group: {str(e)}")
            operation_details.append({"operation": "add_user_to_group", "status": "failed", "reason": str(e)})
        
        logger.info("Granting SELECT on public tables to gdmmonitor group")
        try:
            # First check if there are any tables in the public schema
            cursor.execute("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
            result = cursor.fetchone()
            table_count = result[0] if result else 0
            
            if table_count > 0:
                cursor.execute("GRANT SELECT ON ALL TABLES IN SCHEMA public TO GROUP gdmmonitor;")
                operation_details.append({"operation": "grant_select_public", "status": "success"})
            else:
                logger.info("No tables found in public schema")
                operation_details.append({"operation": "grant_select_public", "status": "skipped", "reason": "No tables in public schema"})
        except Exception as e:
            logger.error(f"Failed to grant SELECT on public tables: {str(e)}")
            operation_details.append({"operation": "grant_select_public", "status": "failed", "reason": str(e)})
        
        logger.info("Granting SELECT on system catalogs to gdmmonitor group")
        try:
            # Check if table exists first
            cursor.execute("SELECT 1 FROM pg_tables WHERE tablename = 'pg_database_info';")
            if cursor.fetchone():
                cursor.execute("GRANT SELECT ON TABLE pg_database_info TO GROUP gdmmonitor;")
                operation_details.append({"operation": "grant_select_pg_database_info", "status": "success"})
            else:
                logger.warning("Table pg_database_info does not exist")
                operation_details.append({"operation": "grant_select_pg_database_info", "status": "skipped", "reason": "Table does not exist"})
        except Exception as e:
            logger.error(f"Failed to grant SELECT on pg_database_info: {str(e)}")
            operation_details.append({"operation": "grant_select_pg_database_info", "status": "failed", "reason": str(e)})
        
        try:
            # Check if table exists first
            cursor.execute("SELECT 1 FROM pg_tables WHERE tablename = 'pg_user_info';")
            if cursor.fetchone():
                cursor.execute("GRANT SELECT ON TABLE pg_user_info TO GROUP gdmmonitor;")
                operation_details.append({"operation": "grant_select_pg_user_info", "status": "success"})
            else:
                logger.warning("Table pg_user_info does not exist")
                operation_details.append({"operation": "grant_select_pg_user_info", "status": "skipped", "reason": "Table does not exist"})
        except Exception as e:
            logger.error(f"Failed to grant SELECT on pg_user_info: {str(e)}")
            operation_details.append({"operation": "grant_select_pg_user_info", "status": "failed", "reason": str(e)})
        
        try:
            # Check if table exists first
            cursor.execute("SELECT 1 FROM pg_tables WHERE tablename = 'svv_user_info';")
            if cursor.fetchone():
                cursor.execute("GRANT SELECT ON TABLE svv_user_info TO GROUP gdmmonitor;")
                operation_details.append({"operation": "grant_select_svv_user_info", "status": "success"})
            else:
                logger.warning("Table svv_user_info does not exist")
                operation_details.append({"operation": "grant_select_svv_user_info", "status": "skipped", "reason": "Table does not exist"})
        except Exception as e:
            logger.error(f"Failed to grant SELECT on svv_user_info: {str(e)}")
            operation_details.append({"operation": "grant_select_svv_user_info", "status": "failed", "reason": str(e)})
        
        # Check if any operations failed
        failed_operations = [op for op in operation_details if op.get("status") == "failed"]
        if failed_operations:
            # If any operations failed, rollback the transaction
            conn.rollback()
            logger.warning(f"Transaction rolled back due to {len(failed_operations)} failed operations")
        else:
            # If all operations succeeded, commit the transaction
            conn.commit()
            logger.info("All operations committed successfully")
        
        if cursor:
            cursor.close()
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        return {
            "status": "success",
            "duration_seconds": duration,
            "operations": operation_details
        }
    except Exception as e:
        logger.error(f"Error configuring VA user: {e}")
        
        # Try to rollback if possible
        try:
            if conn and not conn.closed:
                conn.rollback()
                logger.info("Transaction rolled back")
        except Exception as rollback_err:
            logger.error(f"Error rolling back transaction: {rollback_err}")
        
        return {
            "status": "failed",
            "error": str(e),
            "operations": operation_details
        }
    finally:
        # Make sure to close the cursor if it's still open
        if cursor:
            try:
                if not cursor.closed:
                    cursor.close()
                    logger.info("Cursor closed")
            except Exception as cursor_err:
                logger.warning(f"Error closing cursor: {cursor_err}")

def handler(event, context):
    """Lambda function entry point"""
    execution_id = context.aws_request_id if context and hasattr(context, 'aws_request_id') else "local-execution"
    logger.info(f"Starting Lambda execution with ID: {execution_id}")
    start_time = datetime.now()
    conn = None
    
    try:
        # Get Redshift credentials from Secrets Manager
        credentials = get_redshift_credentials()
        if credentials is None:
            return {
                "statusCode": 500,
                "body": json.dumps({
                    "success": False,
                    "message": "Failed to retrieve credentials",
                    "timestamp": datetime.now().isoformat(),
                    "execution_id": execution_id
                })
            }
        
        # Connect to Redshift
        conn = connect_to_redshift(credentials)
        if conn is None:
            return {
                "statusCode": 500,
                "body": json.dumps({
                    "success": False,
                    "message": "Failed to connect to Redshift",
                    "timestamp": datetime.now().isoformat(),
                    "execution_id": execution_id
                })
            }
        
        # Configure VA user and permissions
        result = configure_va_user(conn, credentials)
        
        if result.get("status") == "failed":
            return {
                "statusCode": 500,
                "body": json.dumps({
                    "success": False,
                    "message": f"Failed to configure VA user: {result.get('error', 'Unknown error')}",
                    "timestamp": datetime.now().isoformat(),
                    "execution_id": execution_id,
                    "operations": result.get("operations", [])
                })
            }
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        return {
            "statusCode": 200,
            "body": json.dumps({
                "success": True,
                "message": "VA configuration completed successfully",
                "timestamp": datetime.now().isoformat(),
                "duration_seconds": duration,
                "execution_id": execution_id,
                "database": credentials['redshift_database'],
                "endpoint": credentials['redshift_host'],
                "operations": result["operations"]
            }, default=str)
        }
    except Exception as e:
        logger.error(f"Lambda execution failed: {e}")
        # Close the connection if it exists
        if conn:
            try:
                conn.close()
                logger.info("Closed Redshift connection after error")
            except Exception as close_error:
                logger.warning(f"Error closing Redshift connection: {str(close_error)}")
                
        return {
            "statusCode": 500,
            "body": json.dumps({
                "success": False,
                "message": f"Lambda execution failed: {str(e)}",
                "timestamp": datetime.now().isoformat(),
                "execution_id": execution_id
            })
        }
    finally:
        # Always close the connection if it exists
        if conn:
            try:
                conn.close()
                logger.info("Closed Redshift connection")
            except Exception as close_error:
                logger.warning(f"Error closing Redshift connection: {str(close_error)}")

# For local testing
if __name__ == "__main__":
    # Configure basic logging
    logging.basicConfig(level=logging.INFO)
    
    # Set environment variables for local testing
    # Replace these with your own values or load from a local config file
    os.environ['REDSHIFT_HOST'] = 'localhost'
    os.environ['REDSHIFT_PORT'] = '5439'
    os.environ['REDSHIFT_DATABASE'] = 'dev'
    os.environ['REDSHIFT_USERNAME'] = 'admin'
    os.environ['REDSHIFT_SECRET_NAME'] = 'redshift-secret'
    os.environ['SQLGUARD_USERNAME'] = 'sqlguard'
    os.environ['SQLGUARD_SECRET_NAME'] = 'sqlguard-secret'
    os.environ['SECRETS_REGION'] = 'us-east-1'
    
    # NOTE: For security in production, never hardcode credentials
    # These values are for local testing only
    
    # Mock the Secrets Manager client for local testing
    import unittest.mock
    with unittest.mock.patch('boto3.session.Session') as mock_session:
        mock_client = unittest.mock.MagicMock()
        mock_session.return_value.client.return_value = mock_client
        mock_client.get_secret_value.side_effect = [
            {'SecretString': 'admin_password'},
            {'SecretString': 'sqlguard_password'}
        ]
        
        # Call the handler
        try:
            result = handler({}, None)
            print("Result:", result)
            
            # Check if execution was successful
            if result and result.get("statusCode") == 200:
                print("Local test execution successful")
            else:
                print("Local test execution failed")
                if result and "body" in result:
                    try:
                        body = json.loads(result["body"])
                        if "message" in body:
                            print(f"Error message: {body['message']}")
                        if "operations" in body:
                            print("Operations details:")
                            for op in body["operations"]:
                                print(f"  - {op['operation']}: {op['status']}")
                                if op['status'] == 'failed' and 'reason' in op:
                                    print(f"    Reason: {op['reason']}")
                    except json.JSONDecodeError as json_err:
                        print(f"Could not parse response body: {str(json_err)}")
                    except Exception as parse_err:
                        print(f"Error processing response: {str(parse_err)}")
        except Exception as e:
            print(f"Error during local testing: {e}")

