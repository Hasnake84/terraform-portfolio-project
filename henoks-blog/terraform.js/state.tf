terraform {
  backend "s3" {
    bucket = "henoks-s3-bucket"
    key = "global/s3/terraform.tfstate"
    region = "us-east-1"
    use_lockfile = "true"
  }
}