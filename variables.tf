variable "aws_region" {
  description = "Region for the VPC"
  default     = "eu-west-1"
}

variable "statebucket" {
  description = "S3 state bucket"
  default     = "mystatebucket"
}

variable "statekey" {
  description = "S3 state object key"
  default     = "myterraformapps/dev/terraform.tfstate"
}

variable "dynamostatetable" {
  description = "DynamoDB state table"
  default     = "terraformstate"
}

variable "keypair" {
  description = "Keypair for instances"
  default     = "IrelandKeyPair"
}
variable "vpc_cidr" {
  description = "CIDR for the VPC"
  default     = "20.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet"
  default     = "20.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR for the private subnet"
  default     = "20.0.2.0/24"
}

variable "availability_zones" {
  default = [
    "eu-west-1a",
    "eu-west-1b",
    "eu-west-1c",
  ]
  type = "list"
}

variable "ami" {
  description = "AMI for EC2"
  default     = "ami-0ea3405d2d2522162"
}


variable "key_path" {
  description = "SSH Public Key path"
  default     = "~/.ssh/gitreader.pem.pub"
}
