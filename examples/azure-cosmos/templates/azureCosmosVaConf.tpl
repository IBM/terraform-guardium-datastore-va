{
  "name": "${datasource_name}",
  "type": "Azure CosmosDB",
  "host": "${datasource_hostname}",
  "port": ${datasource_port},
  "application": "${application}",
  "description": "${datasource_description}",
  "severity": "${severity_level}",
%{if use_ssl }
  "useSSL": 1,
%{ else }
  "useSSL": 0,
%{ endif }
  "savePassword": 1,
  "user": "${cosmos_username}",
  "password": "${cosmos_password}"
}