provider "aws" {
  region = "us-east-1"
}

# S3 Bucket Data Source
data "aws_s3_bucket" "henoks_staging_bucket" {
  bucket = "henoks-staging-bucket"
}

# Ownership Controls (Read-only S3 buckets can't be modified with this)
# Commenting out unless you control the bucket directly
# resource "aws_s3_bucket_ownership_controls" "nextjs_bucket_ownership_controls" {
#   bucket = data.aws_s3_bucket.henoks_staging_bucket.id
#   rule {
#     object_ownership = "BucketOwnerPreferred"
#   }
# }

# Public Access Block (optional for existing bucket)
# resource "aws_s3_bucket_public_access_block" "nextjs_bucket_public_access_block" {
#   bucket = data.aws_s3_bucket.henoks_staging_bucket.id
#   block_public_acls       = false
#   block_public_policy     = false
#   ignore_public_acls      = false
#   restrict_public_buckets = false
# }

# Bucket Policy
resource "aws_s3_bucket_policy" "nextjs_bucket_policy" {
  bucket = data.aws_s3_bucket.henoks_staging_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${data.aws_s3_bucket.henoks_staging_bucket.arn}/*"
      }
    ]
  })
}

# Origin Access Identity for CloudFront
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Access identity for S3"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "nextjs_distribution" {
  origin {
    domain_name = data.aws_s3_bucket.henoks_staging_bucket.bucket_regional_domain_name
    origin_id   = "henoks-s3-bucket"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Next.js portfolio site"
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id       = "henoks-s3-bucket"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}
