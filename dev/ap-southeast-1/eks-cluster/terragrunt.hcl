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
  source = "git::https://github.com/nahidupa/terraform-shared-modules.git//modules/eks-cluster?ref=v0.0.3"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}


dependencies {
  paths = ["../eks-security-groups"]
}

dependency "eks-security-groups" {
  config_path = "../eks-security-groups"
}


# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  
  environment = "${local.env}"

  cluster_name = "eks-cluster-${local.env}-v1"

  cluster_version = "1.16"

  vpc_id = local.sensitive_vars.vpc_id

  subnets = local.sensitive_vars.vpc_subnets

  write_kubeconfig  = true

  config_output_path = "${get_terragrunt_dir()}/eks-cluster-${local.env}-v1" //~/.kube/eks-cluster-${local.env}-v1


  worker_groups = [
      {
        name          = "eks-cluster-${local.env}-v1-ng-spot-1"
        instance_type = "t2.2xlarge"
        asg_max_size  = 1
        asg_min_size  = 1
        asg_desired_capacity  = 1
        kubelet_extra_args  = "--node-labels=node.kubernetes.io/lifecycle=spot"
        suspended_processes = ["AZRebalance"]
        additional_security_group_ids = [dependency.eks-security-groups.outputs.additional_security_group_ids]
        public_ip               = true
        tags = [
          {
            "key"                 = "k8s.io/cluster-autoscaler/enabled"
            "propagate_at_launch" = "false"
            "value"               = "true"
          },
          {
            "key"                 = "k8s.io/cluster-autoscaler/eks-cluster-${local.env}-v1-on-demand-1"
            "propagate_at_launch" = "false"
            "value"               = "true"
          }
        ]
       }]  

}

