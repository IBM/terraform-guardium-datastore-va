{
  "name": "${datasource_name}",
  "type": "Amazon DocumentDB",
  "host": "${datasource_hostname}",
  "port": ${datasource_port},
  "application": "${application}",
  "description": "${datasource_description}",
  "severity": "${severity_level}",
  "dbName": "${db_name}",
  "user": "${sqlguard_username}",
  "password": "${sqlguard_password}",
  "savePassword": ${save_password ? 1 : 0},
  "useSSL": ${use_ssl ? 1 : 0},
  "importServerSSLcert": ${import_server_ssl_cert ? 1 : 0}%{if aws_secrets_manager_config_name != ""},%{endif}
%{if aws_secrets_manager_config_name != ""}
  "awsSecretsManagerConfigName": "${aws_secrets_manager_config_name}"%{if region != ""},%{endif}
%{endif}
%{if region != ""}
  "region": "${region}"
%{endif}
}