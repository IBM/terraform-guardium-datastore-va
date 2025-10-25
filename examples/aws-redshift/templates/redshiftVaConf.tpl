{
  "name": "${datasource_name}",
  "type": "Amazon Redshift",
  "host": "${datasource_hostname}",
  "port": ${datasource_port},
  "application": "${application}",
  "description": "${datasource_description}",
  "dbName": "${datasource_database}",
  "user": "${connection_username}",
  "password": "${connection_password}",
  "severity": "${severity_level}",
  "shared": "${shared_datasource}",
  "savePassword": ${save_password ? 1 : 0},
  "useSSL": ${use_ssl ? 1 : 0},
  "importServerSSLcert": ${import_server_ssl_cert ? 1 : 0},
  "useKerberos": ${use_kerberos ? 1 : 0},
  "useLDAP": ${use_ldap ? 1 : 0},
  "useExternalPassword": ${use_external_password ? 1 : 0}
}