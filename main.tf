resource "random_password" "vm_password" {
  count  = var.vm_count
  length = 16
}

provider "aws" {
  region = "eu-central-1"  # Change this to your desired region
}

locals {
  vm_public_ips = [for i in range(var.vm_count) : aws_instance.vm[i].public_ip]
}

resource "aws_instance" "vm" {
  count         = var.vm_count
  ami           = var.vm_image
  instance_type = var.vm_flavor

  tags = {
    Name = "VM-${count.index}"
  }
}

resource "aws_security_group" "vm_sg" {
  name        = "vm_security_group"
  description = "Allow ping traffic between VMs"

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "null_resource" "run_ping_tests" {
  count = var.vm_count

  triggers = {
    vm_index = count.index
  }

  provisioner "local-exec" {
    command = "bash ping_test.sh ${var.vm_count} ${aws_instance.vm[*].id}"
  }

  depends_on = [aws_instance.vm]  # Ensure the instances are created before running the script
}

output "ping_results" {
  value = null_resource.run_ping_tests[*].triggers.vm_index
}

# Associate public IPs with instances after they are created
resource "null_resource" "associate_public_ips" {
  depends_on = [aws_instance.vm]

  provisioner "local-exec" {
    command = <<-EOT
      echo 'export VM_PUBLIC_IPS="${jsonencode(local.vm_public_ips)}"' > terraform.tfvars
    EOT
  }
}

# Use the associated public IPs in the connection block
resource "null_resource" "update_connection" {
  depends_on = [null_resource.associate_public_ips]

  provisioner "local-exec" {
    command = <<-EOT
      sed -i -e 's/host        = aws_instance.vm[count.index].public_ip/host        = element(jsondecode(var.VM_PUBLIC_IPS), count.index)/' main.tf
    EOT
  }
}
