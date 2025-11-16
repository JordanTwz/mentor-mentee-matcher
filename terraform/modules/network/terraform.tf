terraform {
  required_providers {
    aws = {
      // this is useless because the actual provider is injected from /providers.tf
      source                = "hashicorp/aws"
      configuration_aliases = [aws.local]
    }
  }
}