variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 3
}

variable "vm_flavor" {
  description = "VM flavor"
  type        = string
  default     = "t2.micro"
}

variable "vm_image" {
  description = "VM image"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"  # Change this to your desired AMI
}