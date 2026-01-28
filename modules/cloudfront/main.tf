resource "aws_cloudfront_distribution" "this" {
  enabled = true
  is_ipv6_enabled = true
  
  price_class = var.price_class 

  origin {
    domain_name = var.alb_dns_name
    origin_id = "ALB-internal-id"

    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = var.origin_protocol_policy
      origin_ssl_protocols = var.origin_ssl_protocols
    }
  }

  default_cache_behavior {
    allowed_methods = var.allowed_methods
    cached_methods = ["GET", "HEAD"]
    target_origin_id = "ALB-internal-id"

    forwarded_values {
      query_string = true
      headers = ["*"]
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl = 0
    default_ttl = 0
    max_ttl = 86400
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