terraform {
  backend "s3" {
    bucket         = "aws-state-s3"
    key            = "hcl-usecase-1/terraform.tfstate"
    # access_keyy     = ""
    # secret_keyy     = ""
    region         = "ap-south-1"                
    encrypt        = true                         
  }
}