provider "aws" {
  region = "us-east-1" 
}

include "variables.tf"
include "data.tf"
include "locals.tf"
include "outputs.tf"
include "resources.tf"
