resource "aws_acm_certificate" "acm-certificate" {
  domain_name               = var.domain_name
  key_algorithm             = "RSA_2048"
  subject_alternative_names = ["${var.domain_name}"]
  validation_method         = "DNS"
  options {
    certificate_transparency_logging_preference = "ENABLED"
  }
}


resource "aws_route53_record" "acm_record" {
  provider = aws.dns-account
  for_each = {
    for dvo in aws_acm_certificate.acm-certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  records = [each.value.record]
  ttl     = 300
  type    = each.value.type
  zone_id = "Z03263951KBGAAH0G98CC"
}

resource "aws_route53_record" "lb_record" {
  provider = aws.dns-account
  name     = var.domain_name
  # records                          = []
  #ttl                              = 300
  type    = "A"
  zone_id = "Z03263951KBGAAH0G98CC"
  alias {
    evaluate_target_health = true
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
  }
}
