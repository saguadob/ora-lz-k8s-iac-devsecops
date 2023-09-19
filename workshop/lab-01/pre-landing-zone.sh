#!/bin/sh

# Connect your Github account with OCI using a ORM VCS Provider
OCI_GIT_CONFIG_OCID=$(oci resource-manager configuration-source-provider create-github-access-token-provider --compartment-id "$OCI_TENANCY" --access-token "$(gh auth token)" --api-endpoint "https://github.com"  --display-name "gh-config-01" --query data.id --raw-output)
echo "export OCI_GIT_CONFIG_OCID=\"${OCI_GIT_CONFIG_OCID}\"" >> ~/.bashrc

# Create a Stack that points to where the Landing Zone is declared as IaC
OCI_LZ_STACK_OCID=$(oci resource-manager stack create-from-git-provider --compartment-id "$OCI_TENANCY" --config-source-configuration-source-provider-id "$OCI_GIT_CONFIG_OCID" --config-source-branch-name main --config-source-repository-url "$(gh repo view --json url -q .url)" --config-source-working-directory 'core-team/infra/lz' --display-name "stack-gh-oci-lz-01" --terraform-version "1.2.x" --variables "{\"tenancy_ocid\":\"$OCI_TENANCY\" , \"region\":\"$OCI_REGION\"}" --query data.id --raw-output)
echo "export OCI_LZ_STACK_OCID=\"${OCI_LZ_STACK_OCID}\"" >> ~/.bashrc

# Run a Terraform plan job in ORM
lz_first_plan_job_ocid=$(oci resource-manager job create-plan-job --stack-id "$OCI_LZ_STACK_OCID" --display-name "plan-lz-initial-job" --query data.id --raw-output)
# Apply the job using the plan output in ORM
oci resource-manager job create-apply-job --stack-id "$OCI_LZ_STACK_OCID" --execution-plan-strategy FROM_PLAN_JOB_ID --execution-plan-job-id "$lz_first_plan_job_ocid" --display-name "apply-deploy-lz-job-01"