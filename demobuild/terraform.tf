terraform {
  backend "s3" {
    bucket         = "${var.statebucket}"
    key            = "${var.statekey}"
    region         = "${var.aws_region}"
    dynamodb_table = "${var.dynamostatetable}"
  }
}