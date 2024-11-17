# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# --- networking_account/provider.tf ---

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

# Provider definitios for Oregon Region
provider "aws" {
  region = var.aws_regions.oregon
  alias  = "awsoregon"
}

# Provider definitios for Ireland Region
provider "aws" {
  region = var.aws_regions.ireland
  alias  = "awsireland"
}