terraform {
  backend "s3" {
    bucket         = "aws-state-s3"
    key            = "hcl-usecase-1/terraform.tfstate"
    access_key     = "AKIAXGZALZKIY2YTMIO2"
    secret_key     = "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"
    region         = "ap-south-1"                
    encrypt        = true                         
  }
}