# AWS Redshift with Vulnerability Assessment Example

This example demonstrates how to configure an existing AWS Redshift cluster for vulnerability assessment with IBM Guardium Data Protection.

## Architecture

This example configures an existing AWS Redshift cluster for vulnerability assessment:

1. **Uses Existing AWS Redshift Cluster**: References your existing Redshift cluster
2. **Vulnerability Assessment Configuration**: Grants necessary permissions for Guardium to perform vulnerability assessments
3. **Guardium Data Source Registration**: Registers the Redshift cluster as a data source in Guardium Data Protection

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0.0
- Access to a Guardium Data Protection instance

## Usage

1. The `terraform.tfvars` file has been pre-populated with your existing Redshift cluster details. Review and update any values as needed:

```bash
# Verify the existing Redshift cluster details
cat terraform.tfvars
```

2. Update the following required variables in `terraform.tfvars`:
   - `sqlguard_password`: Password for the Guardium VA user
   - `gdp_ssh_privatekeypath`: Path to SSH private key for Guardium

3. Run Terraform directly:

```bash
terraform init
terraform apply
```

Note: The provider configuration has been updated to use the values from terraform.tfvars directly. You will no longer be prompted for the host and port values, as they are now explicitly set in the provider configuration. However, you may still be prompted for username, password, client_id, and client_secret if there are issues with the local-exec provisioner.

If you are still prompted for values, you can set the environment variables manually:

```bash
export GUARDIUM_USERNAME="your_username"
export GUARDIUM_PASSWORD="your_password"
export GUARDIUM_CLIENT_ID="your_client_id"
export GUARDIUM_CLIENT_SECRET="your_client_secret"
```

## Vulnerability Assessment Configuration

This example configures the Redshift cluster for vulnerability assessment using the `aws-redshift` VA configuration module, which:

1. Creates a `gdmmonitor` group in Redshift
2. Creates a `sqlguard` user and adds it to the `gdmmonitor` group
3. Grants necessary permissions to the `gdmmonitor` group:
   ```sql
   GRANT SELECT ON ALL TABLES IN SCHEMA public TO GROUP gdmmonitor;
   GRANT SELECT ON TABLE pg_database_info TO GROUP gdmmonitor;
   GRANT SELECT ON TABLE pg_user_info TO GROUP gdmmonitor;
   GRANT SELECT ON TABLE svv_user_info TO GROUP gdmmonitor;
   ```
4. Registers the Redshift cluster as a data source in Guardium with:
   - Hostname, port, and database name from your existing Redshift cluster
   - Username and password for the `sqlguard` user
   - Credential type set to "Assign credentials" (save_password = true)
5. Configures vulnerability assessment schedules and notifications

The module uses AWS Lambda to execute the SQL commands, which eliminates the need for local PostgreSQL client installation. The Lambda function:

1. Creates secrets in AWS Secrets Manager to securely store credentials
2. Connects to the Redshift cluster using the provided credentials
3. Executes the SQL commands to create the user, group, and grant permissions
4. Handles errors gracefully and reports the results

## Customization

You can customize this example by modifying the following variables:

- **VA Configuration**: Adjust assessment schedule, notification settings, etc.
- **Guardium Connection**: Update Guardium server details, credentials, etc.
- **Data Source Registration**: Modify data source name, description, severity level, etc.
- **Lambda Configuration**: Configure the Lambda function for VA:
  ```hcl
  # Resource naming
  name_prefix = "guardium"
  
  # Network configuration for Lambda
  vpc_id = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]
  ```

## Cleanup

To destroy all resources created by this example:

```bash
terraform destroy
```

## Notes

- This example is designed to work with an existing Redshift cluster
- Store sensitive information like passwords in a secure location (e.g., AWS Secrets Manager)
- Consider using AWS IAM roles for authentication instead of passwords
