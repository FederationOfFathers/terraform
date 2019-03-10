
// should this be a env?
variable "gcp_credentials_file_path" {
  description = "Location of the credentials to use."
  default     = "~/.gcloud/Terraform.json"
}

variable "gcp_public_key" {
  description = "Location of the public SSH key used to connect via SSH"
  default = "~/.ssh/id_rsa_fof.pub"
}

variable "gcp_private_key" {
  description = "Location of the private SSH key used to connect via SSH"
  default = "~/.ssh/id_rsa_fof"
}

variable "gcp_user" {
  description = "Username for SSH access on remote GCP compute instance"
  default = "cherian_benjamin_gmail_com"
}

variable "docker_remote_port" {
  default = "2375"
}

data "http" "icanhazip" {
  url = "http://icanhazip.com"
}