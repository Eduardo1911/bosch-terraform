# main.tf
provider "aws" {
  region = "us-east-1"  # Change this to your desired region
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
    command = <<EOT
      VM_COUNT=${var.vm_count}
      VM_IDS=(${aws_instance.vm[*].id})
      SOURCE=${VM_IDS[${count.index}]}
      for DESTINATION in "${VM_IDS[@]}"; do
        ping -c 1 -W 1 $(aws_instance.${DESTINATION}.public_ip) > /dev/null 2>&1
        if [ $? -eq 0 ]; then
          echo "Ping from ${SOURCE} to ${DESTINATION}: PASS"
        else
          echo "Ping from ${SOURCE} to ${DESTINATION}: FAIL"
        fi
      done
    EOT
  }
}

output "ping_results" {
  value = [for idx in range(var.vm_count) : null_resource.run_ping_tests[idx].stdout]
}
