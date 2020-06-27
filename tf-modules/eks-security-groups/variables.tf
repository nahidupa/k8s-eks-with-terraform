variable "vpc_id"{

}

variable "ingress_worker_group_mgmt_one"{
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}