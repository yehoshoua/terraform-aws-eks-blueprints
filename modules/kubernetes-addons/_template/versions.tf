terraform {
  required_version = ">= 1.0.0"

  required_providers {
    # Add/remove providers as needed based on resources used in `main.tf`
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.72"
    }
  }
}
