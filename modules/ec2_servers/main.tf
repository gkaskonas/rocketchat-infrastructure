variable "servers_count" {}
variable "instance_type" {}
variable "ami" {}
variable "volume_size" {}
variable "delete_on_termination" {}
variable "vpc_security_group_ids" {}
variable "associate_public_ip_address" {}
variable "protect_termination" {}
variable "ebs_optimized" {}
variable "key_name" {}
variable "subnets" {}
variable "server_name" {}
variable "project_env" {}
variable "script_name" {}



resource "aws_instance" "this" {
  count         = "${var.servers_count}"
  instance_type = "${var.instance_type}"
  ami           = "${var.ami}"

  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.volume_size}"
    delete_on_termination = "${var.delete_on_termination}"
  }

  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${var.vpc_security_group_ids}"]
  subnet_id              = "${element(var.subnets, count.index % length(var.subnets))}"
  associate_public_ip_address = "${var.associate_public_ip_address}"
  disable_api_termination     = "${var.protect_termination}"
  ebs_optimized           = "${var.ebs_optimized}"

  tags = {
    Name = "${var.server_name}-${format("%02d", count.index + 1)}"
    Env  = "${var.project_env}"
  }

  user_data = "${var.script_name}"
  # provisioner "local-exec" {
  #       command = <<EOT
  #     echo Host ${self.public_dns} >> ${var.host_file_name};
  #     scripts/mongo_hosts
  #  EOT
  # }
 

  # provisioner "file" {
  #   source      = "${var.script_name}"
  #   destination = "/home/ec2-user/script.sh"
  # }
  
  # provisioner "remote-exec" {
  #   inline = [
  #     "chmod +x /home/ec2-user/script.sh",
  #     "sudo /home/ec2-user/script.sh",
  #   ]
  # }

  # connection {
  #   type     = "ssh"
  #   user     = "ec2-user"
  #   password = ""
  #   private_key = "${file("~/.ssh/rocketchat.pem")}"
  #   host     = "${self.public_ip}"
  # }
}

output "server_ips" {
  value = compact(coalescelist(aws_instance.this.*.public_ip, [""]))
}


