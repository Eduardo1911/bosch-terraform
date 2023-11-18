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
  default     = "ami-0bf34e885a84149e6"  # Change this to your desired AMI
}

# variable "VM_PUBLIC_IPS" {
#   type    = list(string)
#   default = []
# }

variable "password_length" {
  description = "The length of the randomly generated passwords"
  type        = number
  default     = 16
}