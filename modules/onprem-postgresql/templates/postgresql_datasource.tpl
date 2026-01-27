{
  "name": "${datasource_name}",
  "type": "PostgreSQL",
  "host": "${datasource_hostname}",
  "port": ${datasource_port},
  "dbName": "${db_name}",
  "application": "${application}",
  "description": "${datasource_description}",
  "severity": "${severity_level}",
%{if use_ssl }
  "importServerSSLcert": ${import_server_ssl_cert ? 1 : 0},
  "useSSL": 1,
%{ else }
  "useSSL": 0,
%{ endif }
%{ if use_external_password }
  "useExternalPassword": 1,
  "externalPasswordTypeName": "${external_password_type_name}",
  "awsSecretsManagerConfigName": "${aws_secrets_manager_config_name}",
  "region": "${region}",
  "secretName": "${secret_name}"
%{ else }
  "savePassword": 1,
  "useExternalPassword": 0,
  "user": "${sqlguard_username}",
  "password": "${sqlguard_password}"
%{ endif }
}