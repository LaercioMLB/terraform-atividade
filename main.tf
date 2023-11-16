provider "aws" {
  region = "us-east-1" 
}

module "eks_vpc" {
  source          = "./modules/eks_vpc"
  vpc_block       = "192.168.0.0/16" 
  public_subnet1  = "192.168.0.0/18"
  public_subnet2  = "192.168.64.0/18"
  private_subnet1 = "192.168.128.0/18"
  private_subnet2 = "192.168.192.0/18"
}
