
// Backend

variable "env" {
  default = "dev"
}
variable "ami_id" {
  default = "ami-02df9ea15c1778c9c"
}

terraform {
  backend "s3" {
    bucket = "gkaskonas-terraform-state"
    key    = "rocketchat_state.tfstate"
    region = "eu-west-1"
  }
}

provider "aws" {
  profile = "default"
  region  = "eu-west-1"
}

variable "number_of_instances" {
  description = "Number of instances to create and attach to alb"
  default     = 2
}


data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = "${data.aws_vpc.default.id}"
}

resource "aws_route53_zone" "primary" {
  name = "example.co.uk"
}

resource "aws_route53_record" "rocketchat" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "rocketchat.example.co.uk"
  type    = "A"
  alias {
    name                   = "${module.cdn.domain_name}"
    zone_id                = "${module.cdn.hosted_zone_id}"
    evaluate_target_health = true
  }
}


module "cdn" {
  source      = "./modules/cdn/"
  domain_name = "${module.alb.dns_name}"
}


module "alb" {
  source = "./modules/alb/"

  number_of_instances = "${var.number_of_instances}"
  instance_ids        = "${module.rocketchat.id}"
  vpc_id              = "${data.aws_vpc.default.id}"
  sg_id               = ["${module.security_group.rocketchat_sg_id}"]
  subnet_ids          = "${data.aws_subnet_ids.all.ids}"
}

module "security_group" {
  source = "./modules/security_group"
  vpc_id = "${data.aws_vpc.default.id}"

}

module "efs" {
  source = "./modules/efs"
  subnet = element(tolist(data.aws_subnet_ids.all.ids), 0)
  sg     = "${module.security_group.efs_sg_id}"

}


module "mongo_db" {
  source         = "terraform-aws-modules/ec2-instance/aws"
  version        = "~> 2.0"
  instance_count = "${var.number_of_instances}"

  name                        = "mongodb"
  ami                         = "${var.ami_id}"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = ["${module.security_group.mongodb_sg_id}"]
  subnet_id                   = element(tolist(data.aws_subnet_ids.all.ids), 0)
  associate_public_ip_address = true
  user_data                   = "${file("scripts/install_mongo")}"
  key_name                    = "rocketchat"
}

module "rocketchat" {
  source         = "terraform-aws-modules/ec2-instance/aws"
  version        = "~> 2.0"
  instance_count = "${var.number_of_instances}"

  name                        = "rocketchat"
  ami                         = "${var.ami_id}"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = ["${module.security_group.rocketchat_sg_id}"]
  subnet_id                   = element(tolist(data.aws_subnet_ids.all.ids), 0)
  associate_public_ip_address = true
  user_data                   = "${file("scripts/install_rocketchat")}"
  key_name                    = "rocketchat"
}

output "mongo_hosts" {
  value = "${module.mongo_db.public_dns}"
}

output "rocketchat_hosts" {
  value = "${module.rocketchat.public_ip}"
}

output "efs_dns" {
  value = "${module.efs.efs_dns_name}"
}

