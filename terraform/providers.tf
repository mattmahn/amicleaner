provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      managed_by = "terraform"
      vcs_repo   = "amicleaner"
    }
  }
}
