#!/bin/sh

# Generate KEY/PAIR to allow Github Actions use OCI CLI
openssl genrsa -out ~/oci_cli_api_key.pem 2048    
chmod go-rwx ~/oci_cli_api_key.pem                    
openssl rsa -pubout -in ~/oci_cli_api_key.pem -out ~/oci_cli_api_key_public.pem
GH_OCI_KEY_FINGERPRINT=$(oci iam user api-key upload --user-id $OCI_CLI_USER --key-file ~/oci_cli_api_key_public.pem --query data.fingerprint --raw-output)

# Set secrets in GH repo for GH Actions to use them
gh secret set OCI_CLI_USER --body "$OCI_CLI_USER"
gh secret set OCI_CLI_REGION --body "$OCI_REGION"
gh secret set OCI_CLI_TENANCY --body "$OCI_TENANCY"
gh secret set OCI_CLI_FINGERPRINT --body "$GH_OCI_KEY_FINGERPRINT"
gh secret set OCI_CLI_KEY_CONTENT < ~/oci_api_key.pem
gh variable set OCI_LZ_STACK_ID --body "$OCI_LZ_STACK_OCID"