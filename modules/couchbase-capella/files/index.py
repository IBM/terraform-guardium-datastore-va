import os
import boto3
import json
import logging
import requests
import certifi
from datetime import datetime
from requests.auth import HTTPBasicAuth
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from urllib.parse import quote

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

SECRETS_MANAGER_SECRET_ID = os.environ['SECRETS_MANAGER_SECRET_ID']
AWS_REGION = os.environ.get('SECRETS_REGION', 'us-east-1')
DATASOURCE_TYPE = os.environ.get('DATASOURCE_TYPE', 'Couchbase Capella')

def get_session_with_retries():
    """Create a requests session with retry logic"""
    session = requests.Session()
    retry_strategy = Retry(
        total=3,
        backoff_factor=1,
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=["HEAD", "GET", "PUT", "DELETE", "OPTIONS", "TRACE"]
    )
    adapter = HTTPAdapter(max_retries=retry_strategy)
    session.mount("https://", adapter)
    session.mount("http://", adapter)
    return session

def get_couchbase_credentials():
    """Retrieve Couchbase Capella credentials from AWS Secrets Manager"""
    try:
        logger.info(f"Retrieving Couchbase Capella credentials from Secrets Manager: {SECRETS_MANAGER_SECRET_ID}")

        # Create a Secrets Manager client
        session = boto3.session.Session()
        secrets_client = session.client(
            service_name='secretsmanager',
            region_name=AWS_REGION
        )

        # Get the secret value
        get_secret_value_response = secrets_client.get_secret_value(
            SecretId=SECRETS_MANAGER_SECRET_ID
        )

        logger.debug(f"Starting credential request from Secrets Manager: {SECRETS_MANAGER_SECRET_ID}")
        
        # Parse the secret JSON with validation
        try:
            secret = json.loads(get_secret_value_response['SecretString'])
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON in secret: {e}")
            raise ValueError(f"Secret contains invalid JSON: {e}")
        
        # Validate required fields
        required_fields = [
            'username', 'password', 'cluster_endpoint', 'rest_api_endpoint',
            'port', 'bucket_name', 'connection_string', 'tls_enabled',
            'sqlguard_username', 'sqlguard_password'
        ]
        missing_fields = [f for f in required_fields if f not in secret]
        if missing_fields:
            raise ValueError(f"Secret missing required fields: {', '.join(missing_fields)}")

        logger.debug(f"Completed credential request from Secrets Manager: {SECRETS_MANAGER_SECRET_ID}")
        logger.info("Successfully retrieved Couchbase Capella credentials")

        return {
            'username': secret['username'],
            'password': secret['password'],
            'cluster_endpoint': secret['cluster_endpoint'],
            'rest_api_endpoint': secret['rest_api_endpoint'],
            'port': secret['port'],
            'bucket_name': secret['bucket_name'],
            'connection_string': secret['connection_string'],
            'tls_enabled': secret['tls_enabled'],
            'sqlguard_username': secret['sqlguard_username'],
            'sqlguard_password': secret['sqlguard_password'],
            'guardium_hostname': secret.get('guardium_hostname', '')
        }
    except Exception as e:
        logger.error(f"Error retrieving Couchbase Capella credentials: {e}")
        raise

def verify_connection(credentials):
    """Verify connection to Couchbase Capella cluster"""
    try:
        endpoint = credentials['rest_api_endpoint']
        auth = HTTPBasicAuth(credentials['username'], credentials['password'])
        
        logger.info(f"Verifying connection to Couchbase Capella at {endpoint}")
        
        # Create session with retry logic
        session = get_session_with_retries()
        
        # Test connection by getting cluster info
        response = session.get(
            f"{endpoint}/pools/default",
            auth=auth,
            verify=certifi.where(),
            timeout=30
        )
        
        if response.status_code == 200:
            logger.info("Successfully connected to Couchbase Capella cluster")
            return True
        else:
            logger.error(f"Failed to connect to Couchbase Capella: HTTP {response.status_code}")
            # Don't log response.text as it may contain sensitive information
            return False
            
    except requests.exceptions.RequestException as e:
        logger.error(f"Connection error to Couchbase Capella: {e}")
        return False

def get_user(credentials, username):
    """Check if a user exists in Couchbase Capella"""
    try:
        endpoint = credentials['rest_api_endpoint']
        auth = HTTPBasicAuth(credentials['username'], credentials['password'])
        
        # Sanitize username to prevent path traversal
        safe_username = quote(username, safe='')
        
        logger.info(f"Checking if user exists (sanitized)")
        
        # Create session with retry logic
        session = get_session_with_retries()
        
        # Get user details
        response = session.get(
            f"{endpoint}/settings/rbac/users/local/{safe_username}",
            auth=auth,
            verify=certifi.where(),
            timeout=30
        )
        
        if response.status_code == 200:
            logger.info(f"User exists")
            return response.json()
        elif response.status_code == 404:
            logger.info(f"User does not exist")
            return None
        else:
            logger.warning(f"Unexpected response when checking user: HTTP {response.status_code}")
            # Don't log response.text as it may contain sensitive information
            return None
            
    except requests.exceptions.RequestException as e:
        logger.error(f"Error checking user existence: {e}")
        return None

def create_or_update_va_user(credentials):
    """Create or update the VA user in Couchbase Capella with appropriate permissions"""
    start_time = datetime.now()
    operation_details = []
    
    try:
        endpoint = credentials['rest_api_endpoint']
        auth = HTTPBasicAuth(credentials['username'], credentials['password'])
        username = credentials['sqlguard_username']
        password = credentials['sqlguard_password']
        bucket_name = credentials['bucket_name']
        
        # Sanitize username to prevent path traversal
        safe_username = quote(username, safe='')
        
        logger.info(f"Configuring VA user for bucket '{bucket_name}'")
        
        # Check if user exists
        existing_user = get_user(credentials, username)
        
        # Define roles for VA user
        # Couchbase Capella roles for read-only access and query capabilities
        roles = [
            f"data_reader[{bucket_name}]",      # Read data from bucket
            f"query_select[{bucket_name}]",     # Execute SELECT queries
            f"query_system_catalog",             # Access system catalog for metadata
        ]
        
        # Prepare user data
        user_data = {
            'password': password,
            'roles': ','.join(roles),
            'name': f'Guardium VA User for {bucket_name}'
        }
        
        if existing_user:
            logger.info(f"Updating existing VA user")
            operation = "updated"
        else:
            logger.info(f"Creating new VA user")
            operation = "created"
        
        # Create session with retry logic
        session = get_session_with_retries()
        
        # Create or update user via REST API
        response = session.put(
            f"{endpoint}/settings/rbac/users/local/{safe_username}",
            auth=auth,
            data=user_data,
            verify=certifi.where(),
            timeout=30
        )
        
        if response.status_code in [200, 201]:
            logger.info(f"Successfully {operation} VA user")
            operation_details.append(f"Successfully {operation} VA user with roles: {', '.join(roles)}")
            
            # Verify user creation/update
            verify_user = get_user(credentials, username)
            if verify_user:
                logger.info(f"Verified VA user configuration")
                operation_details.append(f"Verified user configuration")
            else:
                logger.warning(f"Could not verify VA user after {operation}")
                operation_details.append(f"Warning: Could not verify user after {operation}")
            
            end_time = datetime.now()
            duration = (end_time - start_time).total_seconds()
            
            return {
                'success': True,
                'message': f'VA user configuration completed successfully',
                'operations': operation_details,
                'duration_seconds': duration,
                'timestamp': datetime.utcnow().isoformat(),
                'bucket': bucket_name,
                'roles': roles
            }
        else:
            logger.error(f"Failed to {operation} VA user: HTTP {response.status_code}")
            # Don't log response.text as it may contain the password
            return {
                'success': False,
                'error': f"Failed to {operation} VA user: HTTP {response.status_code}",
                'operations': operation_details
            }
            
    except requests.exceptions.RequestException as e:
        logger.error(f"Request error during VA user configuration: {e}")
        return {
            'success': False,
            'error': f"Request error: {str(e)}",
            'operations': operation_details
        }
    except Exception as e:
        logger.error(f"Error configuring VA user: {e}")
        return {
            'success': False,
            'error': str(e),
            'operations': operation_details
        }

def handler(event, context):
    """Lambda handler function"""
    logger.info("Starting Couchbase Capella VA configuration")
    logger.info(f"Event: {json.dumps(event)}")
    logger.info(f"Datasource Type: {DATASOURCE_TYPE}")
    
    try:
        # Get credentials from Secrets Manager
        credentials = get_couchbase_credentials()
        
        # Verify connection to Couchbase Capella
        if not verify_connection(credentials):
            return {
                'statusCode': 500,
                'body': json.dumps({
                    'success': False,
                    'error': 'Failed to connect to Couchbase Capella cluster'
                })
            }
        
        # Configure VA user
        result = create_or_update_va_user(credentials)
        
        if result['success']:
            logger.info("Couchbase Capella VA configuration completed successfully")
            return {
                'statusCode': 200,
                'body': json.dumps(result)
            }
        else:
            logger.error(f"Couchbase Capella VA configuration failed: {result.get('error')}")
            return {
                'statusCode': 500,
                'body': json.dumps(result)
            }
            
    except Exception as e:
        logger.error(f"Unexpected error in Lambda handler: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'success': False,
                'error': str(e)
            })
        }