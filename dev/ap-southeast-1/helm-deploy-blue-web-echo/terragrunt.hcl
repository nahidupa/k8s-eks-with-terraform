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
  source = "git::https://github.com/nahidupa/terraform-shared-modules.git//modules/helm3-local-chart?ref=v0.0.4"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}





# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {

  charts = "${find_in_parent_folders("charts")}/blue-green/blue-green-web-echo"

  name = "blue-web-echo"

  k8s_config_path = "~/.kube/eks-cluster-dev-v1"

  namespace= "istio-inject-blue-green"

  chart-values= file("values/values.yaml")
 
}

