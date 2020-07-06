locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  
  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract out common variables for reuse
  env = local.environment_vars.locals.environment
  account_name = local.account_vars.locals.account_name
  account_id   = local.account_vars.locals.aws_account_id
  aws_region   = local.region_vars.locals.aws_region

  sensitive_vars = yamldecode(file("${find_in_parent_folders("sensitive-vars.yaml")}"))
}


# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "git::https://github.com/nahidupa/terraform-shared-modules.git//modules/kubernetes_namespace?ref=v0.0.4"
}


# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}



dependencies {
  paths = ["../eks-cluster"]
}

dependency "eks-cluster" {
  config_path = "../eks-cluster"
}


# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  

aws_eks_cluster_auth_cluster_token= dependency.eks-cluster.outputs.aws_eks_cluster_auth_cluster_token
aws_eks_cluster_cluster_certificate_authority_data= dependency.eks-cluster.outputs.aws_eks_cluster_cluster_certificate_authority_data
cluster_endpoint= dependency.eks-cluster.outputs.cluster_endpoint
namespace_name = "istio-inject-blue-green"
namespace_labels = {
  "istio-injection" = "enabled"
  }

}
