{
  "name": "${datasource_name}",
  "type": "Elasticache",
  "host": "${elasticache_endpoint}",
  "port": ${elasticache_port},
  "application": "${application}",
  "description": "${datasource_description}",
  "user": "",
  "password": "${auth_token != null ? auth_token : ""}",
  "severity": "${severity_level}",
  "savePassword": ${auth_token != null ? 1 : 0},
  "useSSL": ${enable_tls ? 1 : 0},
  "importServerSSLcert": ${import_server_ssl_cert ? 1 : 0},
  "useKerberos": false,
  "useLDAP": false
}