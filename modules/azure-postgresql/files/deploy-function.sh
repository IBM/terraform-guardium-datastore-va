#!/bin/bash
#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#
# Safe function deployment script with proper argument handling

set -euo pipefail

# Validate arguments
if [ $# -ne 3 ]; then
  echo "ERROR: Usage: $0 <resource_group> <function_name> <zip_file>"
  exit 1
fi

RESOURCE_GROUP="$1"
FUNCTION_NAME="$2"
ZIP_FILE="$3"

# Validate Azure CLI is installed
if ! command -v az &> /dev/null; then
  echo "ERROR: Azure CLI not installed"
  exit 1
fi

# Validate authentication
if ! az account show &> /dev/null; then
  echo "ERROR: Not authenticated to Azure. Run 'az login' first."
  exit 1
fi

# Validate zip file exists
if [ ! -f "$ZIP_FILE" ]; then
  echo "ERROR: Zip file not found: $ZIP_FILE"
  exit 1
fi

# Wait for function app to be ready (max 5 minutes)
echo "Waiting for function app to be ready..."
for i in {1..30}; do
  if az functionapp show --resource-group "$RESOURCE_GROUP" --name "$FUNCTION_NAME" &> /dev/null; then
    echo "Function app is ready"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "ERROR: Function app not ready after 5 minutes"
    exit 1
  fi
  echo "Waiting... ($i/30)"
  sleep 10
done

# Deploy function code
echo "Deploying function code..."
az functionapp deployment source config-zip \
  --resource-group "$RESOURCE_GROUP" \
  --name "$FUNCTION_NAME" \
  --src "$ZIP_FILE" \
  --build-remote true

echo "Function deployment completed successfully"
