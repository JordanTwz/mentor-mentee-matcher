terraform {
  backend "s3" {
    bucket       = "asp-proj-terraform-state"
    key          = "prod/root/terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
  }
}