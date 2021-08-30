output "DNS_NSs" {
  description = "Outputs the nameservers"
  value       = aws_route53_zone.primary.name_servers
}
