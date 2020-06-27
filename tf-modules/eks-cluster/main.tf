provider "kubernetes" {	
 
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "1.11.3"
}



module "eks_cluster" {
      source          = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=tags/v12.0.0"
      
      cluster_name    = var.cluster_name
      
      cluster_version = var.cluster_version

      subnets         = var.subnets 

      vpc_id          = var.vpc_id

      worker_groups = var.worker_groups
      # worker_groups = [
      #   # {
      #   #   name                = "${var.cluster_name}-v1-on-demand-1"
      #   #   instance_type       = "m4.large"
      #   #   asg_max_size        = 1
      #   #   asg_desired_capacity  = 1
      #   #   kubelet_extra_args  = "--node-labels=node.kubernetes.io/lifecycle=normal"
      #   #   suspended_processes = ["AZRebalance"]
      #   #   additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
      #   #   additional_userdata           = "echo working"
  
      #   # },

      # {
      #   name          = "${var.cluster_name}-ng-spot-1"
      #   instance_type = "t2.2xlarge"
      #   asg_max_size  = 1
      #   asg_min_size  = 1
      #   asg_desired_capacity  = 1
      #   kubelet_extra_args  = "--node-labels=node.kubernetes.io/lifecycle=spot"
      #   suspended_processes = ["AZRebalance"]
      #   additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
      #   public_ip               = true
      #   tags = [
      #     {
      #       "key"                 = "k8s.io/cluster-autoscaler/enabled"
      #       "propagate_at_launch" = "false"
      #       "value"               = "true"
      #     },
      #     {
      #       "key"                 = "k8s.io/cluster-autoscaler/${var.cluster_name}-v1-on-demand-1"
      #       "propagate_at_launch" = "false"
      #       "value"               = "true"
      #     }
      #   ]
      #  }
      # ]  


      config_output_path =var.config_output_path
      write_kubeconfig=var.write_kubeconfig
    }