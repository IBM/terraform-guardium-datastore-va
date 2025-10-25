#!/bin/bash
yum update -y
yum install -y postgresql jq

# Create the VA config script
cat > /home/ec2-user/aws-rds-postgres-va-config.sql << 'SCRIPT'
${va_config_script}
SCRIPT

# Create a helper script to run the VA config
cat > /home/ec2-user/run_va_config.sh << 'HELPER'
#!/bin/bash

# Setup sqlguard user and permissions
PGPASSWORD="${db_password}" psql -h ${db_host} -p ${db_port} -d ${db_name} -U ${db_username} << EOF
${sqlguard_setup_script}
EOF

# Run the VA config script
PGPASSWORD="${db_password}" psql -h ${db_host} -p ${db_port} -d ${db_name} -U ${db_username} -f /home/ec2-user/aws-rds-postgres-va-config.sql
HELPER

chmod +x /home/ec2-user/run_va_config.sh
chown ec2-user:ec2-user /home/ec2-user/*.sh /home/ec2-user/*.sql