terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

# S3 bucket creation

resource "aws_s3_bucket" "pianosite_static" {
  bucket = "collincornelius.com"
  acl    = "public-read"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::collincornelius.com/*"
        }
    ]
}
EOF

  website {
    index_document = "index.html"
    error_document = "error.html"

  }
}

# DNS zone creation

resource "aws_route53_zone" "primary" {
  name = "collincornelius.com"
}

# Alias record creation


data "aws_s3_bucket" "selected" {
  bucket = aws_s3_bucket.pianosite_static.bucket
}

data "aws_route53_zone" "root_domain" {
  name = aws_route53_zone.primary.name
}

resource "aws_route53_record" "root_alias" {
  zone_id = data.aws_route53_zone.root_domain.id
  type    = "A"
  name    = ""

  alias {
    name                   = data.aws_s3_bucket.selected.website_domain
    zone_id                = data.aws_s3_bucket.selected.hosted_zone_id
    evaluate_target_health = false
  }
}
