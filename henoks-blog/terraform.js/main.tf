provider "aws" {
  region = "us-east-1"
}

data "aws_s3_bucket" "henoks-staging-bucket" {
  bucket = "henoks-staging-bucket"
}

#Ownership Control
resource "aws_s3_bucket_ownership_control" "nextjs_bucket_ownership_controls" {
  bucket = aws_s3_bucket.nextjs_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  
}

# Block Public Access

resource "aws_s3_bucket_public_access_block" "nextjs_bucket_public_access_block" {
  bucket = aws_s3_bucket.nextjs_bucket.id

  block_public_acls = false
  block_public_policy = false
  ignore_public_acls = false
  restrict_public_buckets = false

}

# Bucket ACL
resource "aws_s3_bucket_acl" "nextjs_bucket_acl" {
  
  depends_on = [
  aws_s3_bucket_ownership_control.nextjs_bucket_ownership_controls,
  aws_s3_bucket_public_access_block.nextjs_bucket_public_access_block
]

  bucket = aws_s3_bucket.nextjs_bucket.id
  acl = "public-read"
  
}

# Bucket Policy
resource "aws_s3_bucket_policy" "nextjs_bucket_policy" {
  bucket = data.aws_s3_henoks-staging-bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "PublicReadGetObject"
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${data.aws_s3_bucket.existing_bucket.arn}/*"
      }
    ]
  })
}
