variable "pve_insecure" {
    type        = bool
    description = "Enable insecure connexion"
    default     = true
}

variable "pve_endpoint" {
    type        = string
    description = "API endpoint URL"
}

variable "pve_password" {
    type        = string
    description = "Password"
}

variable "pve_username" {
    type        = string
    description = "Username"
}
variable "pve_node" {
    type        = string
    description = "Node where install elements"
    default     = ""
}
variable "debian_image_url" {
    type        = string
    description = "The URL for the latest Debian 12 Bookworm qcow2 image"
    default     = ""
}
variable "debian_image_checksum_algorithm" {
    type        = string
    description = "Checksum algo used by image"
    default      = "sha512"
}

variable "debian_image_checksum" {
    type        = string
    description = "SHA Digest of the image"
    default     = ""
}
