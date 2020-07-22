

variable "subnet" {}
variable "sg" {}

resource "aws_efs_file_system" "rocketchat-efs" {
   creation_token = "rocketchat-efs"
   performance_mode = "generalPurpose"
   throughput_mode = "bursting"
   encrypted = "true"
    tags = {
        Name = "EfsExample"
    }

  lifecycle_policy {
    transition_to_ia = "AFTER_14_DAYS"
  }
}


resource "aws_efs_mount_target" "efs-mt-example" {
   file_system_id  = "${aws_efs_file_system.rocketchat-efs.id}"
   subnet_id = "${var.subnet}"
   security_groups = ["${var.sg}"]
 }


 output "efs_dns_name" {
  value = "${aws_efs_file_system.rocketchat-efs.dns_name}"
}