# Random hex value for bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket
resource "aws_s3_bucket" "avatars" {
  bucket        = "grocerymate-avatars-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "grocerymate-avatars"
    Environment = "Dev"
  }
}

# S3 - create avatar folder
resource "aws_s3_object" "folder" {
  bucket = aws_s3_bucket.avatars.id
  key    = "avatars/"
}

resource "aws_s3_object" "default_avatar" {
  bucket       = aws_s3_bucket.avatars.id
  key          = "avatars/user_default.png"
  source       = "${path.module}/../backend/avatar/user_default.png"
  content_type = "image/png"
}

# S3 versioning
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.avatars.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.avatars.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 public-access-block
resource "aws_s3_bucket_public_access_block" "default" {
  bucket                  = aws_s3_bucket.avatars.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}