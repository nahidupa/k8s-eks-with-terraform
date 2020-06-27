variable "cluster_name" {
  default= "eks-cluster-default-name"
}

variable "cluster_version" {
  default= "1.14"
}

variable "subnets" {
     type    = list(string)
}

variable "vpc_id" {
     type    = string
}
variable "config_output_path"{

}
variable "write_kubeconfig"{
  default = false
}

variable "worker_groups"{
  type        = any
  default     = []
}


