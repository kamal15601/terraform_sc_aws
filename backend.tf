terraform {
  backend "s3" {
    bucket = "terraform-bucket1703"
    key    = "projects/terraform.tfstate"
    region = "ap-south-1"
  }
}