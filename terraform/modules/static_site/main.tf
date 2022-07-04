resource "aws_s3_bucket" "this_s3_bucket" {
  bucket_prefix = var.bucket_name
}

resource "aws_s3_bucket_website_configuration" "this_s3_bucket_website_config" {
  bucket = aws_s3_bucket.this_s3_bucket.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "random_password" "this_s3_password" {
  length  = 16
  special = true
}

resource "aws_s3_bucket_policy" "this_s3_bucket_policy" {
  bucket = aws_s3_bucket.this_s3_bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "PolicyForCloudFrontPrivateContent",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": "s3:GetObject",
      "Principal": "*",
      "Resource": "${aws_s3_bucket.this_s3_bucket.arn}/*",
      "Condition": {
        "StringNotEquals": {
          "aws:UserAgent": "${random_password.this_s3_password.result}"
        }
      }
    }
  ]
}
POLICY
}

locals {
  s3_origin_id = "S3-Website-${aws_s3_bucket_website_configuration.this_s3_bucket_website_config.website_endpoint}"
}

resource "aws_cloudfront_distribution" "this_static_site_distribution" {
  origin {
    domain_name = aws_s3_bucket.this_s3_bucket.website_endpoint
    origin_id   = local.s3_origin_id

    custom_header {
      name  = "User-Agent"
      value = random_password.this_s3_password.result
    }

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
    }
  }

  enabled         = true
  is_ipv6_enabled = true

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
