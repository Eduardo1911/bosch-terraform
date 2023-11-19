resource "random_password" "vm_password" {
  count  = var.vm_count
  length = var.password_length
}

provider "aws" {
  region = "eu-central-1"  # Change this to your desired region
}

# resource "null_resource" "store_public_ips" {
#   count = var.vm_count

#   triggers = {
#     public_ip = aws_instance.vm[count.index].public_ip
#   }

#   provisioner "local-exec" {
#     command = "echo 'export VM_PUBLIC_IP_${count.index}=${aws_instance.vm[count.index].public_ip}' >> terraform.tfvars"
#   }
# }

resource "aws_instance" "vm" {
  count         = var.vm_count
  ami           = var.vm_image
  instance_type = var.vm_flavor
  key_name = "gh-runner-key"
  iam_instance_profile = "bosch-vm-roles"

  tags = {
    Name = "VM-${count.index}"
  }
  
  user_data = <<-EOF
            #!/bin/bash
            echo "VM-${count.index}" | sudo tee /etc/hostname
            sudo hostnamectl set-hostname "VM-${count.index}"
            EOF
  vpc_security_group_ids = [aws_security_group.vm_sg.id]
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${path.module}/ssh_key.pem")
    host        = self.public_ip
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update &> ~/apt_update.log",
      "sudo apt-get install -y iputils-ping awscli &> ~/apt_install.log",
      "sudo usermod --password $(openssl passwd -1 '${element(random_password.vm_password.*.result, count.index)}|tee -a ~/pass') ubuntu &> ~/usermod.log",
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
    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# resource "null_resource" "run_ping_tests" {
#   count = var.vm_count

#   triggers = {
#     vm_index = count.index
#   }

#   provisioner "local-exec" {
#     command = "bash ping_test.sh ${var.vm_count} ${join(" ", aws_instance.vm[*].id)}"
#   }

#   depends_on = [aws_instance.vm]  # Ensure the instances are created before running the script
# }

resource "null_resource" "run_ping_tests" {
  count = var.vm_count

  triggers = {
    vm_index = count.index
  }

  provisioner "file" {
    source      = "${path.module}/ping_test.sh"
    destination = "/tmp/ping_test.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/ssh_key.pem")
      host        = element(aws_instance.vm[*].public_ip, count.index)
    }
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y awscli",
      "chmod +x /tmp/ping_test.sh",  # Ensure the script is executable
      "/tmp/ping_test.sh ${var.vm_count} ${join(" ", aws_instance.vm[*].private_ip)} > /tmp/ping_results.txt",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/ssh_key.pem")
      host        = element(aws_instance.vm[*].public_ip, count.index)
    }
 }

  depends_on = [aws_instance.vm]  # Ensure the instances are created before running the script
}

output "ping_results" {
  value = join("\n", [for idx in range(var.vm_count) : fileexists("/tmp/ping_results.txt") ? file("/tmp/ping_results.txt") : ""])
}

