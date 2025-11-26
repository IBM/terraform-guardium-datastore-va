{
  "name": "${datasource_name}",
  "type": "MS SQL SERVER (DataDirect)",
  "host": "${datasource_hostname}",
  "port": ${datasource_port},
  "application": "${application}",
  "description": "${datasource_description}",
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
  "user": "${db_username}",
  "password": "${db_password}"
%{ endif }
}