terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Optional remote state for CI. Leave commented for a first local apply;
  # then create a bucket and uncomment (or pass -backend-config).
  # backend "s3" {
  #   bucket = "YOUR_TF_STATE_BUCKET"
  #   key    = "shipyard/terraform.tfstate"
  #   region = "ca-central-1"
  # }
}
