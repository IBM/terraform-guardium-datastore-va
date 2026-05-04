#!/bin/bash
# Check if IAM PassRole permission has been added

echo "Checking IAM PassRole permission for aws_gi_dev role..."
echo ""

# Check if the specific policy exists
if aws iam get-role-policy --role-name aws_gi_dev --policy-name AllowPassRoleForLambda 2>/dev/null; then
    echo "✅ SUCCESS: PassRole permission has been added!"
    echo ""
    echo "You can now uncomment the Lambda module and run terraform apply"
else
    echo "❌ NOT FOUND: PassRole permission has not been added yet"
    echo ""
    echo "Ask your admin to run:"
    echo "aws iam put-role-policy --role-name aws_gi_dev --policy-name AllowPassRoleForLambda --policy-document file://IAM_PASSROLE_POLICY.json"
fi

# Made with Bob
