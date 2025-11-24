{
  "name": "${datasource_name}",
  "type": "${datasource_type}",
  "host": "${datasource_hostname}",
  "port": ${datasource_port},
  "application": "${application}",
  %{ if datasource_description != "" }
  "description": "${datasource_description}",
  %{ endif }
  %{ if service_name != "" }
  "serviceName": "${service_name}",
  %{ endif }
  %{ if connection_username != "" }
  "user": "${connection_username}",
  %{ endif }
  %{ if connection_password != "" }
  "password": "${connection_password}",
  %{ endif }
  %{ if severity_level != "" }
  "severity": "${severity_level}",
  %{ endif }
  %{ if shared_datasource != "" }
  "shared": "${shared_datasource}",
  %{ endif }
  %{ if connection_properties != "" }
  "conProperty": "${connection_properties}",
  %{ endif }
  %{ if compatibility_mode != "" }
  "compatibilityMode": "${compatibility_mode}",
  %{ endif }
  %{ if custom_url != "" }
  "customURL": "${custom_url}",
  %{ endif }
  %{ if kerberos_config_name != "" }
  "KerberosConfigName": "${kerberos_config_name}",
  %{ endif }
  %{ if external_password_type_name != "" }
  "externalPasswordTypeName": "${external_password_type_name}",
  %{ endif }
  %{ if cyberark_config_name != "" }
  "cyberarkConfigName": "${cyberark_config_name}",
  %{ endif }
  %{ if cyberark_object_name != "" }
  "cyberarkObjectName": "${cyberark_object_name}",
  %{ endif }
  %{ if hashicorp_config_name != "" }
  "hashicorpConfigName": "${hashicorp_config_name}",
  %{ endif }
  %{ if hashicorp_path != "" }
  "hashicorpPath": "${hashicorp_path}",
  %{ endif }
  %{ if hashicorp_role != "" }
  "hashicorpRole": "${hashicorp_role}",
  %{ endif }
  %{ if hashicorp_child_namespace != "" }
  "hashicorpChildNamespace": "${hashicorp_child_namespace}",
  %{ endif }
  %{ if aws_secrets_manager_config_name != "" }
  "awsSecretsManagerConfigName": "${aws_secrets_manager_config_name}",
  %{ endif }
  %{ if region != "" }
  "region": "${region}",
  %{ endif }
  %{ if secret_name != "" }
  "secretName": "${secret_name}",
  %{ endif }
  %{ if db_instance_account != "" }
  "dbInstanceAccount": "${db_instance_account}",
  %{ endif }
  %{ if db_instance_directory != "" }
  "dbInstanceDirectory": "${db_instance_directory}",
  %{ endif }
  "savePassword": ${save_password ? 1 : 0},
  "useSSL": ${use_ssl ? 1 : 0},
  "importServerSSLcert": ${import_server_ssl_cert ? 1 : 0},
  "useKerberos": ${use_kerberos ? 1 : 0},
  "useLDAP": ${use_ldap ? 1 : 0},
  "useExternalPassword": ${use_external_password ? 1 : 0}
}
