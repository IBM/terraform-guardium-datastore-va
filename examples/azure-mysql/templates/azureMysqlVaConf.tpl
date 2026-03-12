{
  "name": "${datasource_name}",
  "type": "MySQL",
  "host": "${datasource_hostname}",
  "port": ${datasource_port},
  "application": "${application}",
  "description": "${datasource_description}",
  "severity": "${severity_level}",
  "shared": "Not Shared",
%{if use_ssl }
  "importServerSSLcert": ${import_server_ssl_cert ? 1 : 0},
  "useSSL": 1,
%{ else }
  "useSSL": 0,
%{ endif }
%{ if use_external_password }
  "useExternalPassword": 1,
  "externalPasswordTypeName": "${external_password_type_name}",
  "azureKeyVaultConfigName": "${azure_key_vault_config_name}",
  "keyVaultName": "${key_vault_name}",
  "secretName": "${secret_name}"
%{ else }
  "savePassword": 1,
  "useExternalPassword": 0,
  "user": "${sqlguard_username}",
  "password": "${sqlguard_password}"
%{ endif }
}