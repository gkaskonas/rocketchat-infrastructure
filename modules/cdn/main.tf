variable "domain_name" {
  
}

resource "aws_cloudfront_distribution" "rocketchat_distribution" {
  origin {
    domain_name = "${var.domain_name}"
    origin_id   = "rocketchat"
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }  
    }

  enabled             = true
  comment             = "CDN for Rocketchat"
  default_root_object = "index.html"
  aliases = ["rocketchat.toastedbuns.co.uk"]
  wait_for_deployment = false

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "rocketchat"

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

    price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-east-1:770895255011:certificate/ae4bb638-6a83-489d-b3ab-825b132a5bd6"
    ssl_support_method = "sni-only"
  }
}

output "domain_name" {
  value = "${aws_cloudfront_distribution.rocketchat_distribution.domain_name}"
}

output "hosted_zone_id" {
  value = "${aws_cloudfront_distribution.rocketchat_distribution.hosted_zone_id}"
}