# RDS PostgreSQL Vulnerability Assessment Configuration Module

This module configures an AWS RDS PostgreSQL database for Guardium Vulnerability Assessment (VA). It creates the necessary users and permissions required for Guardium to perform security assessments and entitlement reports.

## Features

- Creates a `sqlguard` user with the necessary permissions
- Creates a `gdmmonitor` group and adds the `sqlguard` user to it
- Grants the required permissions for Guardium VA to work properly
- Executes the VA configuration script from the Guardium documentation
- Supports both local execution and execution via an EC2 instance

## Prerequisites

- PostgreSQL version 10.x or above
- The user executing the script must have superuser privileges
- The database must be accessible from the machine running the script
- If using EC2 execution, the SSH key pair must exist in AWS and locally

## Usage

### Basic Usage (Local Execution)

```hcl
module "postgresql_va_config" {
  source = "path/to/modules/datastore-va-config/aws-rds-postgresql"

  db_host     = "your-postgresql-instance.rds.amazonaws.com"
  db_port     = 5432
  db_name     = "postgres"
  db_username = "postgres"
  db_password = "your-password"
}
```

### Using EC2 Instance for Execution

```hcl
module "postgresql_va_config" {
  source = "path/to/modules/datastore-va-config/aws-rds-postgresql"

  db_host     = "your-postgresql-instance.rds.amazonaws.com"
  db_port     = 5432
  db_name     = "postgres"
  db_username = "postgres"
  db_password = "your-password"
  
  use_local_exec     = false
  create_ec2_instance = true
  vpc_id             = "vpc-12345678"
  subnet_id          = "subnet-12345678"
  ec2_key_name       = "your-key-pair"
}
```

### Custom sqlguard User

```hcl
module "postgresql_va_config" {
  source = "path/to/modules/datastore-va-config/aws-rds-postgresql"

  db_host          = "your-postgresql-instance.rds.amazonaws.com"
  db_port          = 5432
  db_name          = "postgres"
  db_username      = "postgres"
  db_password      = "your-password"
  
  sqlguard_username = "custom_guard"
  sqlguard_password = "custom-password"
}
```

## Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| db_host | Hostname or IP address of the PostgreSQL database | string | (required) |
| db_port | Port for the PostgreSQL database | number | 5432 |
| db_name | Name of the PostgreSQL database | string | (required) |
| db_username | Username for the PostgreSQL database (must have superuser privileges) | string | (required) |
| db_password | Password for the PostgreSQL database | string | (required) |
| sqlguard_username | Username for the Guardium user | string | sqlguard |
| sqlguard_password | Password for the sqlguard user | string | Guardium123! |
| create_ec2_instance | Whether to create an EC2 instance for connecting to the PostgreSQL database | bool | false |
| ec2_key_name | Name of the key pair to use for the EC2 instance | string | kieran-test-key-pair |
| ec2_instance_type | Instance type for the EC2 instance | string | t3.micro |
| vpc_id | ID of the VPC where the EC2 instance will be created | string | "" |
| subnet_id | ID of the subnet where the EC2 instance will be created | string | "" |
| aws_region | AWS region where resources will be created | string | us-east-1 |
| use_local_exec | Whether to use local-exec provisioner (false means EC2 will be used) | bool | true |

## Outputs

| Name | Description |
|------|-------------|
| sqlguard_username | Username for the Guardium user |
| sqlguard_password | Password for the sqlguard user (sensitive) |
| ec2_instance_id | ID of the EC2 instance created for VA configuration (if enabled) |
| ec2_public_ip | Public IP of the EC2 instance created for VA configuration (if enabled) |
| security_group_id | ID of the security group created for the EC2 instance (if enabled) |
| va_config_completed | Whether the VA configuration has been completed |

## Notes

- The module requires the PostgreSQL client to be installed on the machine running Terraform if using local execution.
- If using EC2 execution, the module will install the PostgreSQL client on the EC2 instance.
- The module will create a security group for the EC2 instance if one is not provided.
- The module will wait for the EC2 instance to be ready before executing the VA configuration script.