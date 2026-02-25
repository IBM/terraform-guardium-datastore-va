#!/bin/bash
set -e

echo "Building Neptune VA Lambda function package..."

# Create a temporary directory for packaging
mkdir -p package

# Install dependencies for Lambda environment (Python 3.9 on Linux)
echo "Installing dependencies for Lambda environment (Python 3.9 on Linux)..."
python3 -m pip install --platform manylinux2014_x86_64 --target ./package \
    --implementation cp --python-version 39 --only-binary=:all: --upgrade \
    boto3 gremlinpython aiohttp typing-extensions --quiet

# Copy the Lambda function code
echo "Copying Lambda function code..."
cp index.py package/

# Create the zip file
echo "Creating zip file..."
cd package
zip -r ../lambda_function.zip . -q
cd ..

# Clean up
echo "Cleaning up..."
rm -rf package

echo "Lambda package created successfully: lambda_function.zip"
ls -lh lambda_function.zip
