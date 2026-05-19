{
  "name": "${datasource_name}",
  "type": "Amazon Elasticache (Redis OSS)",
  "host": "${elasticache_endpoint}",
  "port": ${elasticache_port},
  "user": "",
  "password": "${auth_token != null ? auth_token : ""}",
  "application": "${application}",
  "description": "${datasource_description}",
  "severity": "${severity_level}",
  "savePassword": ${auth_token != null ? 1 : 0},
  "useSSL": ${enable_tls ? 1 : 0},
  "importServerSSLcert": ${import_server_ssl_cert ? 1 : 0},
  "region": "${aws_region}",
  "awsSecretsManagerConfigName": "${aws_secrets_manager_config_name}",
  "useKerberos": false,
  "useLDAP": false
}
