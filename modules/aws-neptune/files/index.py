import os
import boto3
import json
import logging
from datetime import datetime
from gremlin_python.driver import client, serializer
from gremlin_python.driver.protocol import GremlinServerError
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
from urllib.parse import urlparse

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Debug: Test aiohttp import
try:
    import aiohttp
    logger.info(f"aiohttp imported successfully, version: {aiohttp.__version__}")
    from gremlin_python.driver.aiohttp.transport import AiohttpTransport
    logger.info("AiohttpTransport imported successfully")
except ImportError as e:
    logger.error(f"Import error: {e}")
    import sys
    logger.error(f"Python path: {sys.path}")
    logger.error(f"Python version: {sys.version}")
SECRETS_MANAGER_SECRET_ID = os.environ['SECRETS_MANAGER_SECRET_ID']
AWS_REGION = os.environ.get('SECRETS_REGION', 'us-east-1')
USE_IAM_AUTH = os.environ.get('USE_IAM_AUTH', 'true').lower() == 'true'

def get_neptune_credentials():
    """Retrieve Neptune credentials from AWS Secrets Manager"""
    try:
        logger.info(f"Retrieving Neptune credentials from Secrets Manager: {SECRETS_MANAGER_SECRET_ID}")

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
        # Parse the secret JSON
        secret = json.loads(get_secret_value_response['SecretString'])

        logger.debug(f"Completed credential request from Secrets Manager: {SECRETS_MANAGER_SECRET_ID}")
        logger.info("Successfully retrieved Neptune credentials")

        return {
            'sqlguard_username': secret['sqlguard_username'],
            'sqlguard_password': secret['sqlguard_password'],
            'endpoint': secret['endpoint'],
            'port': secret['port'],
            'username': secret['username'],
            'password': secret['password'],
            'cluster_identifier': secret['cluster_identifier']
        }
    except Exception as e:
        logger.error(f"Error retrieving Neptune credentials: {e}")
        raise

def get_iam_token(endpoint, port, region):
    """Generate IAM authentication token for Neptune"""
    try:
        session = boto3.Session()
        credentials = session.get_credentials()
        
        # Create the request to sign
        url = f"https://{endpoint}:{port}/"
        request = AWSRequest(method='GET', url=url)
        
        # Sign the request with SigV4
        SigV4Auth(credentials, 'neptune-db', region).add_auth(request)
        
        # Extract the authorization header
        return request.headers.get('Authorization', '')
    except Exception as e:
        logger.error(f"Failed to generate IAM token: {e}")
        raise

def connect_to_neptune(credentials):
    """Connect to Neptune database using Gremlin with IAM or password auth"""
    try:
        # Neptune uses WebSocket connection for Gremlin
        neptune_endpoint = f"wss://{credentials['endpoint']}:{credentials['port']}/gremlin"
        
        logger.info(f"Connecting to Neptune at {neptune_endpoint}")
        logger.info(f"Using IAM authentication: {USE_IAM_AUTH}")
        
        # Create Gremlin client with appropriate authentication
        if USE_IAM_AUTH:
            # For IAM authentication, Neptune uses IAM database authentication
            # The Lambda execution role must have neptune-db:connect permission
            logger.info("Using IAM authentication for Neptune")
            gremlin_client = client.Client(
                neptune_endpoint,
                'g',
                message_serializer=serializer.GraphSONSerializersV2d0()
            )
        else:
            # For password-based authentication (if enabled on cluster)
            logger.info("Using password authentication for Neptune")
            gremlin_client = client.Client(
                neptune_endpoint,
                'g',
                username=credentials.get('username'),
                password=credentials.get('password'),
                message_serializer=serializer.GraphSONSerializersV2d0()
            )
        
        logger.info("Successfully connected to Neptune")
        return gremlin_client
    except Exception as e:
        logger.error(f"Failed to connect to Neptune: {e}")
        return None

def configure_va_user(gremlin_client, credentials):
    """Configure VA user in Neptune
    
    Note: Neptune is a graph database and doesn't have traditional SQL users.
    This function creates metadata about the VA configuration that can be used
    by Guardium for vulnerability assessment.
    """
    start_time = datetime.now()
    operation_details = []
    
    try:
        username = credentials['sqlguard_username']
        
        logger.info(f"Configuring VA metadata for user {username}")
        
        # Neptune doesn't have traditional user management like SQL databases
        # Instead, we'll create a vertex to store VA configuration metadata
        # This can be used by Guardium to track VA setup
        
        # Check if VA config vertex exists
        check_query = f"g.V().hasLabel('va_config').has('username', '{username}').count()"
        result = gremlin_client.submit(check_query).all().result()
        exists = result[0] > 0
        
        if not exists:
            logger.info(f"Creating VA configuration metadata for {username}")
            create_query = f"""
            g.addV('va_config')
             .property('username', '{username}')
             .property('configured_at', '{datetime.utcnow().isoformat()}')
             .property('purpose', 'guardium_vulnerability_assessment')
             .property('cluster_identifier', '{credentials['cluster_identifier']}')
            """
            gremlin_client.submit(create_query).all().result()
            operation_details.append(f"Created VA configuration metadata for {username}")
        else:
            logger.info(f"VA configuration metadata already exists for {username}")
            # Update the timestamp
            update_query = f"""
            g.V().hasLabel('va_config').has('username', '{username}')
             .property('last_updated', '{datetime.utcnow().isoformat()}')
            """
            gremlin_client.submit(update_query).all().result()
            operation_details.append(f"Updated VA configuration metadata for {username}")
        
        # Verify the configuration
        verify_query = f"g.V().hasLabel('va_config').has('username', '{username}').valueMap()"
        config = gremlin_client.submit(verify_query).all().result()
        logger.info(f"VA configuration verified: {config}")
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        return {
            'success': True,
            'message': 'VA configuration completed successfully',
            'operations': operation_details,
            'duration_seconds': duration,
            'timestamp': datetime.utcnow().isoformat()
        }
        
    except GremlinServerError as e:
        logger.error(f"Gremlin server error during VA configuration: {e}")
        return {
            'success': False,
            'error': str(e),
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
    logger.info("Starting Neptune VA configuration")
    logger.info(f"Event: {json.dumps(event)}")
    
    try:
        # Get credentials from Secrets Manager
        credentials = get_neptune_credentials()
        
        # Connect to Neptune
        gremlin_client = connect_to_neptune(credentials)
        if not gremlin_client:
            return {
                'statusCode': 500,
                'body': json.dumps({
                    'success': False,
                    'error': 'Failed to connect to Neptune'
                })
            }
        
        # Configure VA user
        result = configure_va_user(gremlin_client, credentials)
        
        # Close the connection
        gremlin_client.close()
        
        if result['success']:
            logger.info("Neptune VA configuration completed successfully")
            return {
                'statusCode': 200,
                'body': json.dumps(result)
            }
        else:
            logger.error(f"Neptune VA configuration failed: {result.get('error')}")
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