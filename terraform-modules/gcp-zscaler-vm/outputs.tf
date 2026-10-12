output "public_ip_allowlist_cidrs" {
  value = {
    for k, v in google_compute_address.public :
    k => "${v.address}/32"
  }
}
