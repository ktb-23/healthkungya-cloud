provider "aws" {
  region = "ap-northeast-2"
  default_tags {
    tags = {
      Environment = "development"
      Team        = "ktb-23"
      ProjectName = "healthkungya"
    }
  }
}

# S3
resource "aws_s3_bucket" "storage" {
  bucket = "ktb-23-healthkungya-fe"
}

locals {
  s3_origin_id                      = "ktb-23-healthkungya-fe-origin-id"
  target_domain_url                 = "healthkungya.ktb23team.link"
  target_domain_acm_certificate_arn = "arn:aws:acm:us-east-1:471112681394:certificate/ed41d486-6e48-4596-890a-3d57002b732e"
  route53_hosted_zone_id            = "Z054447238YXX7HFB7YZA"
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "ktb-23-healthkungya-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "storage_distribution" {
  origin {
    domain_name              = aws_s3_bucket.storage.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "KTB Team 23 HealthKungya Project Frontend Distribution"
  default_root_object = "index.html"

  aliases = [local.target_domain_url]


  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
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
    acm_certificate_arn      = local.target_domain_acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

}

resource "aws_s3_bucket_policy" "storage_policy" {
  bucket = aws_s3_bucket.storage.bucket

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action   = "s3:GetObject",
        Resource = ["${aws_s3_bucket.storage.arn}/*"],
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.storage_distribution.arn
          }
        }
      }
    ]
  })

  depends_on = [aws_cloudfront_distribution.storage_distribution]
}

resource "aws_route53_record" "www_health_kungya" {
  zone_id = local.route53_hosted_zone_id
  name    = local.target_domain_url
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.storage_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.storage_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
