# main.tf
provider "aws" {
  region = "eu-central-1"  # Change this to your desired region
}

resource "aws_instance" "vm" {
  count         = var.vm_count
  ami           = var.vm_image
  instance_type = var.vm_flavor

  tags = {
    Name = "VM-${count.index}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y iputils-ping",
    ]
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