# random hex value for bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# s3 bucket
resource "aws_s3_bucket" "avatars" {
  bucket = "grocerymate-avatars-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "grocerymate-avatars"
    Environment = "Dev"
  }
}

#s3 create avatar folder
resource "aws_s3_object" "folder" {
  bucket = aws_s3_bucket.avatars.id
  key    = "avatars/"
}

resource "aws_s3_object" "default_avatar" {
  bucket = aws_s3_bucket.avatars.id
  key    = "avatars/user_default.png"
  source = "${path.module}/../backend/avatar/user_default.png"
  content_type = "image/png"
}
