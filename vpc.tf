locals {
  tags = {
    company    = "move-nearshore"
    GithubRepo = "terraform-aws-vpc"
    GithubOrg  = "terraform-aws-modules"
  }

  s3_bucket_name = "vpc-flow-logs-to-s3-move-ns"
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  name = "shared-vpc-1"
  cidr = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets  = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
  enable_dns_hostnames = true
  enable_dns_support   = true
  ######
  create_database_subnet_route_table = true
  ###### 
  enable_flow_log = true
  flow_log_destination_type = "s3"
  flow_log_file_format = "parquet"
  flow_log_destination_arn = module.s3_bucket.s3_bucket_arn
  vpc_flow_log_tags = local.tags
  ######
  private_subnet_tags = {
    
    # Tags subnets for alb-controller auto-discovery
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    
    # Tags subnets for Karpenter auto-discovery
    "karpenter.sh/discovery" = var.cluster_name
  }

  public_subnet_tags = {

    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    
  }


  tags = {
    Environment = "staging"
  }
}


module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id = module.vpc.vpc_id

  # create_security_group      = true
  # security_group_name_prefix = "${local.name}-vpc-endpoints-"
  # security_group_description = "VPC endpoint security group"
  # security_group_rules = {
  #   ingress_https = {
  #     description = "HTTPS from VPC"
  #     cidr_blocks = [module.vpc.vpc_cidr_block]
  #   }
  # }

  endpoints = {
    s3 = {
      service = "s3"
      tags    = { Name = "s3-vpc-endpoint" }
      # private_dns_enabled = true
      subnet_ids          = module.vpc.database_subnets
      # policy              = data.aws_iam_policy_document.generic_endpoint_policy.json
      # security_group_ids  = [aws_security_group.rds.id]

    },
    # sns = {
    #   service    = "sns"
    #   subnet_ids = ["subnet-12345678", "subnet-87654321"]
    #   tags       = { Name = "sns-vpc-endpoint" }
    # },
    # sqs = {
    #   service             = "sqs"
    #   private_dns_enabled = true
    #   security_group_ids  = ["sg-987654321"]
    #   subnet_ids          = ["subnet-12345678", "subnet-87654321"]
    #   tags                = { Name = "sqs-vpc-endpoint" }
    # },
    # rds = {
    #   service             = "rds"
    #   private_dns_enabled = true
    #   subnet_ids          = module.vpc.private_subnets
    #   security_group_ids  = [aws_security_group.rds.id]
    # },
  }

  tags =  {
    Project  = "Secret"
    Endpoint = "true"
  }
}

## S3 Bucket
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket        = local.s3_bucket_name
  policy        = data.aws_iam_policy_document.flow_log_s3.json
  force_destroy = true
  block_public_acls = false

  tags = local.tags
}

data "aws_iam_policy_document" "flow_log_s3" {
  statement {
    sid = "AWSLogDeliveryWrite"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = ["arn:aws:s3:::${local.s3_bucket_name}/AWSLogs/*"]
  }

  statement {
    sid = "AWSLogDeliveryAclCheck"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = ["s3:GetBucketAcl"]

    resources = ["arn:aws:s3:::${local.s3_bucket_name}"]
  }
}


# resource "aws_security_group" "rds" {
#   name_prefix = "${local.name}-rds"
#   description = "Allow PostgreSQL inbound traffic"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     description = "TLS from VPC"
#     from_port   = 5432
#     to_port     = 5432
#     protocol    = "tcp"
#     cidr_blocks = [module.vpc.vpc_cidr_block]
#   }

#   tags = local.tags
# }


# data "aws_iam_policy_document" "generic_endpoint_policy" {
#   statement {
#     effect    = "Deny"
#     actions   = ["*"]
#     resources = ["*"]

#     principals {
#       type        = "*"
#       identifiers = ["*"]
#     }

#     condition {
#       test     = "StringNotEquals"
#       variable = "aws:SourceVpc"

#       values = [module.vpc.vpc_id]
#     }
#   }
# }

