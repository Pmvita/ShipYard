provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "ShipYard"
      ManagedBy = "terraform"
      Lab       = "devops-portfolio"
    }
  }
}
