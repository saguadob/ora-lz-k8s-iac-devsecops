# Lab 01 - Deploy a Landing Zone

## Goals
In this lab we are going to deploy a Landing Zone that a platform engineering team would deploy for other teams to use

### Intro
Besides our documentation, a good resource to get _hands-on_ started in OCI is the :octocat: Github repo [`oracle-devrel/technology-engineering`](https://github.com/oracle-devrel/technology-engineering). In this repo you can find a technical introduction to the different [Landing Zones developed by Oracle](https://github.com/oracle-devrel/technology-engineering/tree/main/landing-zones) and an explanation on when to use each one of them. For this workshop we are going to use the [CIS OCI Landing Zone](https://docs.oracle.com/en/solutions/cis-oci-benchmark/index.html).

## Task 1: Prepare your DevOps tools.
```sh
# Connect your Github account with OCI using a ORM VCS Provider
OCI_GIT_CONFIG_OCID=$(oci resource-manager configuration-source-provider create-github-access-token-provider --compartment-id "$OCI_TENANCY" --access-token "$(gh auth token)" --api-endpoint "https://github.com"  --display-name "gh-config-01" --query data.id --raw-output)
echo "export OCI_GIT_CONFIG_OCID=\"${OCI_GIT_CONFIG_OCID}\"" >> ~/.bashrc

# Create a Stack that points to where the Landing Zone is declared as IaC
OCI_LZ_STACK_OCID=$(oci resource-manager stack create-from-git-provider --compartment-id "$OCI_TENANCY" --config-source-configuration-source-provider-id "$OCI_GIT_CONFIG_OCID" --config-source-branch-name main --config-source-repository-url "$(gh repo view --json url -q .url)" --config-source-working-directory 'core-team/infra/lz' --display-name "stack-gh-oci-lz-01" --terraform-version "1.2.x" --variables "{\"tenancy_ocid\":\"$OCI_TENANCY\" , \"region\":\"$OCI_REGION\"}" --query data.id --raw-output)
echo "export OCI_LZ_STACK_OCID=\"${OCI_LZ_STACK_OCID}\"" >> ~/.bashrc
```
This startup script helps you to avoid doing a _click-ops_ approach to deploy the landing zone by creating a stack mapped to the repository you are working on.
```mermaid
flowchart LR
    subgraph GitHub
    Repo --> Net[Network TF Config]
    Repo --> App[App TF Config]
    Repo((Workshop repo )) --> LZ[LZ TF Config]
    end
    subgraph OCI
    ORM(Resource Manager) --> VCS_CONFIG[ORM Git Config]
    ORM --> LZ_STACK[LZ Stack]
    ORM --> NET_STACK[Network Stack]
    ORM --> APP_STACK[APP Stack]
    end
    VCS_CONFIG -->|GH TOKEN| Repo
    LZ_STACK --> |Map| LZ
```
## Task 2: Configure the LZ to your needs
Go to the file [`main.tf`](../../core-team/infra/lz/main.tf) and inspect it.
```HCL
module "lz" {
  source = "github.com/oracle-quickstart/oci-cis-landingzone-quickstart//config?ref=v2.6.2"

  region                              = var.region
  tenancy_ocid                        = var.tenancy_ocid
  use_enclosing_compartment           = true
  existing_enclosing_compartment_ocid = var.enclosing_compartment
  env_advanced_options                = true
  policies_in_root_compartment        = "USE" # Use "CREATE" when using in empty tenancy
  vcn_cidrs                           = ["10.0.1.0/24", "10.0.2.0/24"]
  exacs_vcn_cidrs                     = []
  hub_spoke_architecture              = true
  hs_advanced_options                 = true
  dmz_vcn_cidr                        = "10.0.0.0/24"
  public_src_bastion_cidrs            = []
  public_src_lbr_cidrs                = ["0.0.0.0/0"]
  public_dst_cidrs                    = []
  network_admin_email_endpoints       = ["example@example.com"]
  security_admin_email_endpoints      = ["example@example.com"]
  enable_cloud_guard                  = false
  service_label                       = # CHANGE ME!
}
```
At the beginning the vairables can be confusing, let's refer to the CIS Landing zone [repo](https://github.com/oracle-quickstart/oci-cis-landingzone-quickstart). Our goal is to deploy a Hub-Spoke architecture, where  the internet facing components are going to be placed in the Hub network and workloads are deployed in the spokes.

To illustrate what are going to deploy, let's use one of the reference deployments recommended in the landing zone

![cis-hub-spoke](https://github.com/oracle-quickstart/oci-cis-landingzone-quickstart/blob/main/images/Architecture_HS_VCN.png?raw=true)

## Task 2:  Deploy the landing zone
One the LZ is deployed to our liking, we can simply proceed to deploy it using ORM jobs
```sh
# Run a Terraform plan job in ORM
lz_first_plan_job_ocid=$(oci resource-manager job create-plan-job --stack-id "$OCI_LZ_STACK_OCID" --display-name "plan-lz-initial-job" --query data.id --raw-output)
# Apply the job using the plan output in ORM
oci resource-manager job create-apply-job --stack-id "$OCI_LZ_STACK_OCID" --execution-plan-strategy FROM_PLAN_JOB_ID --execution-plan-job-id "$lz_first_plan_job_ocid" --display-name "apply-deploy-lz-job-01"
```