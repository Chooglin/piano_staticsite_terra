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

resource "aws_s3_bucket" "pianosite_test_bucket" {
  bucket = "collincornelius.com"
  acl    = "private"

  tags = {
    Name = "pianotest_static_bucket"
  }
}

# Create origin access identity
resource "aws_cloudfront_origin_access_identity" "pianosite_test_oai" {
  comment = "Origin access identity for pianosite_test"
}


# Update policy for cloudflare origin access

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.pianosite_test_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.pianosite_test_oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "pianosite_test_policy" {
  bucket = aws_s3_bucket.pianosite_test_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

locals {
  s3_origin_id = "myS3Origin"
}


resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.pianosite_test_bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.pianosite_test_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "This is for testing terraform bucket creation"
  default_root_object = "index.html"



  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
