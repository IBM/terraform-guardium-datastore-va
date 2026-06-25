#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

import logging
import json
import os
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
import psycopg2
from psycopg2 import sql

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('PostgreSQL VA Configuration function triggered.')

    try:
        # Get Key Vault name and secret name from environment variables
        key_vault_name = os.environ.get('KEY_VAULT_NAME')
        secret_name = os.environ.get('SECRET_NAME')
        
        if not key_vault_name or not secret_name:
            return func.HttpResponse(
                json.dumps({
                    "success": False,
                    "error": "KEY_VAULT_NAME or SECRET_NAME environment variable not set"
                }),
                status_code=500,
                mimetype="application/json"
            )

        # Retrieve credentials from Key Vault
        key_vault_uri = f"https://{key_vault_name}.vault.azure.net"
        credential = DefaultAzureCredential()
        secret_client = SecretClient(vault_url=key_vault_uri, credential=credential)
        
        logging.info(f"Retrieving secret '{secret_name}' from Key Vault '{key_vault_name}'")
        secret = secret_client.get_secret(secret_name)
        credentials = json.loads(secret.value)
        
        # Extract connection details
        db_host = credentials['endpoint']
        db_port = credentials['port']
        db_name = credentials['database']
        admin_user = credentials['username']
        admin_password = credentials['password']
        sqlguard_user = credentials['sqlguard_username']
        sqlguard_password = credentials['sqlguard_password']
        
        logging.info(f"Connecting to PostgreSQL server: {db_host}:{db_port}/{db_name}")
        
        # Connect to PostgreSQL as admin
        conn = psycopg2.connect(
            host=db_host,
            port=db_port,
            database=db_name,
            user=admin_user,
            password=admin_password,
            sslmode='require'
        )
        conn.autocommit = True
        cursor = conn.cursor()
        
        operations = []
        
        # Check if sqlguard user exists
        cursor.execute(
            "SELECT 1 FROM pg_roles WHERE rolname = %s",
            (sqlguard_user,)
        )
        user_exists = cursor.fetchone() is not None
        
        if user_exists:
            logging.info(f"User '{sqlguard_user}' already exists, updating password")
            cursor.execute(
                sql.SQL("ALTER USER {} WITH PASSWORD %s").format(
                    sql.Identifier(sqlguard_user)
                ),
                (sqlguard_password,)
            )
            operations.append({
                "operation": "update_sqlguard_password",
                "status": "success"
            })
        else:
            logging.info(f"Creating user '{sqlguard_user}'")
            cursor.execute(
                sql.SQL("CREATE USER {} WITH PASSWORD %s").format(
                    sql.Identifier(sqlguard_user)
                ),
                (sqlguard_password,)
            )
            operations.append({
                "operation": "create_sqlguard_user",
                "status": "success"
            })
        
        # Grant CONNECT privilege on database
        logging.info(f"Granting CONNECT on database '{db_name}'")
        cursor.execute(
            sql.SQL("GRANT CONNECT ON DATABASE {} TO {}").format(
                sql.Identifier(db_name),
                sql.Identifier(sqlguard_user)
            )
        )
        operations.append({
            "operation": "grant_connect",
            "status": "success"
        })
        
        # Grant USAGE on schema public
        logging.info("Granting USAGE on schema public")
        cursor.execute(
            sql.SQL("GRANT USAGE ON SCHEMA public TO {}").format(
                sql.Identifier(sqlguard_user)
            )
        )
        operations.append({
            "operation": "grant_usage_schema",
            "status": "success"
        })
        
        # Grant SELECT on all tables in schema public
        logging.info("Granting SELECT on all tables in schema public")
        cursor.execute(
            sql.SQL("GRANT SELECT ON ALL TABLES IN SCHEMA public TO {}").format(
                sql.Identifier(sqlguard_user)
            )
        )
        operations.append({
            "operation": "grant_select_tables",
            "status": "success"
        })
        
        # Grant SELECT on all sequences in schema public
        logging.info("Granting SELECT on all sequences in schema public")
        cursor.execute(
            sql.SQL("GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO {}").format(
                sql.Identifier(sqlguard_user)
            )
        )
        operations.append({
            "operation": "grant_select_sequences",
            "status": "success"
        })
        
        # Alter default privileges for future tables
        logging.info("Altering default privileges for future tables")
        cursor.execute(
            sql.SQL("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO {}").format(
                sql.Identifier(sqlguard_user)
            )
        )
        operations.append({
            "operation": "alter_default_privileges",
            "status": "success"
        })
        
        cursor.close()
        conn.close()
        
        logging.info("PostgreSQL VA configuration completed successfully")
        
        return func.HttpResponse(
            json.dumps({
                "success": True,
                "message": "VA configuration completed successfully",
                "operations": operations
            }),
            status_code=200,
            mimetype="application/json"
        )
        
    except psycopg2.Error as e:
        logging.error(f"PostgreSQL error: {str(e)}")
        return func.HttpResponse(
            json.dumps({
                "success": False,
                "error": f"PostgreSQL error: {str(e)}"
            }),
            status_code=500,
            mimetype="application/json"
        )
    except Exception as e:
        logging.error(f"Error configuring PostgreSQL VA: {str(e)}")
        return func.HttpResponse(
            json.dumps({
                "success": False,
                "error": str(e)
            }),
            status_code=500,
            mimetype="application/json"
        )
