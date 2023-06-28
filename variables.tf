variable "region" {
    default = "ap-south-1"
    description = "AWS Region to deploy to"
}

variable "common-name-value" {
    default = "sns-sqs-lab-"
    description = "Common naming convention for all Terraform created resources"
}

variable "account"{
    default = ""
}

variable "environment"{
    default = "dev"
}

variable "suffix"{
    default = "source"
}

