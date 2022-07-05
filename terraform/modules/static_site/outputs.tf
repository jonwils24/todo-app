output "website_bucket_name" {
  value = aws_s3_bucket.this_s3_bucket.id
}

output "cloudfront_id" {
  value = aws_cloudfront_distribution.this_static_site_distribution.id
}
