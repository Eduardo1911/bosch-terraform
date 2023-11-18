resource "random_password" "vm_password" {
  count  = var.vm_count
  length = var.password_length
}

provider "aws" {
  region = "eu-central-1"  # Change this to your desired region
}

resource "null_resource" "store_public_ips" {
  count = var.vm_count

  triggers = {
    public_ip = aws_instance.vm[count.index].public_ip
  }

  provisioner "local-exec" {
    command = "echo 'export VM_PUBLIC_IP_${count.index}=${aws_instance.vm[count.index].public_ip}' >> terraform.tfvars"
  }
}

resource "aws_instance" "vm" {
  count         = var.vm_count
  ami           = var.vm_image
  instance_type = var.vm_flavor

  tags = {
    Name = "VM-${count.index}"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("${path.module}/ssh_key.pem")
    host        = element([for ip in var.VM_PUBLIC_IPS : ip], count.index)
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y iputils-ping",
      "sudo usermod --password $(openssl passwd -1 ${element(random_password.vm_password.*.result, count.index)}) ec2-user",
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
