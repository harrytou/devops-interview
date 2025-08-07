# ------------------------------------------------------------------------------
# General / GCP Project Variables
# ------------------------------------------------------------------------------

variable "project_id" {
  description = "The GCP project ID where resources will be deployed."
  type        = string
}

variable "zone" {
  description = "The GCP zone for zonal resources (used for single instance deployments if MIG size is 1 and no autoscaler, otherwise region is primary)."
  type        = string
  # Example: "us-central1-a"
}

# ------------------------------------------------------------------------------
# Naming & Identification Variables
# ------------------------------------------------------------------------------

variable "prefix" {
  description = "A prefix often used for naming resources uniquely."
  type        = string
  default     = "hume-tf"
}

variable "service_name" {
  description = "The logical name of the service being deployed (used in naming)."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., 'dev', 'staging', 'prod') (used in naming)."
  type        = string
}

# ------------------------------------------------------------------------------
# Networking Variables
# ------------------------------------------------------------------------------

variable "vpc_name" {
  description = "The name of the VPC network to use."
  type        = string
  default     = "default"
}

variable "subnet_name" {
  description = "The name of the subnet within the VPC to deploy resources in."
  type        = string
}

variable "network_tags" {
  description = "A list of network tags to apply to the instances."
  type = list(string)
  default = []
}

variable "assign_static_external_ip" {
  description = "Whether to assign a static external IP address to the instance(s). Usually false if using a Load Balancer or Regional MIG."
  type        = bool
  default     = false
}

# ------------------------------------------------------------------------------
# Compute Instance Variables
# ------------------------------------------------------------------------------

variable "machine_type" {
  description = "The machine type for the Compute Engine instance(s)."
  type        = string
  # Example: "e2-medium"
}

variable "image_family" {
  description = "Family for the instance boot disk image. Can be an image family (e.g., 'cos-stable') or a specific image path."
  type        = string
  default     = "cos-stable" # Defaulting to Container-Optimized OS stable family
}

variable "image_project_id" {
  description = "The project ID where the boot disk image resides. Required if image_family is not a globally known family like 'cos-stable'."
  type        = string
  default     = "cos-cloud" # Project for Container-Optimized OS
}

variable "is_preemptible_machine" {
  description = "Whether the VM instances should be preemptible (Spot VMs)."
  type        = bool
  default     = false
}

variable "metadata_startup_script" {
  description = "A startup script to run when the instance boots (before container starts)."
  type        = string
  default     = ""
}

variable "boot_disk_size_gb" {
  description = "The size of the boot disk in GB."
  type        = number
  default     = 50
}

variable "boot_disk_type" {
  description = "The type of the boot disk (e.g., 'pd-standard', 'pd-balanced', 'pd-ssd')."
  type        = string
  default     = "pd-balanced"
}

variable "additional_disks" {
  description = "List of additional data disks to attach to the instance(s)."
  type = list(object({
    device_name = string # Required, e.g., "data-disk-1"
    disk_size_gb = number # Required
    disk_type = string # Optional, defaults based on zone
    labels = map(string)
    auto_delete = bool
  }))
  default = []
}

# ------------------------------------------------------------------------------
# Container Specification Variables (for gce-container-declaration)
# ------------------------------------------------------------------------------

variable "container_name" {
  description = "The name assigned to the container within the VM spec."
  type        = string
  default     = "app-container"
}

variable "container_image" {
  description = "The full path to the container image (e.g., Artifact Registry URL)."
  type        = string
}

variable "container_command" {
  description = "Optional command override for the container's entrypoint (list of strings)."
  type = list(string)
  default     = null # Use null to indicate using the image's default entrypoint
}

variable "container_args" {
  description = "Optional arguments for the container's command (list of strings)."
  type = list(string)
  default     = null # Use null to indicate using the image's default cmd/args
}

variable "container_ports" {
  description = "Informational list of ports the container exposes (used for MIG named ports)."
  type = list(number)
  default = [] # Default to empty list
}

variable "container_restart_policy" {
  description = "Restart policy for the container (e.g., 'Always', 'OnFailure', 'Never')."
  type        = string
  default     = "Always"
}

# ------------------------------------------------------------------------------
# Container Environment & Secrets Variables
# ------------------------------------------------------------------------------

variable "container_env" {
  description = "Map of environment variables to set in the container (KEY = Value)."
  type = map(string)
  default = {}
}

variable "container_secrets" {
  description = "Secrets to be mounted into the container."
  type = list(object({
    env_var_name = string
    secret_value = string
  }))

  sensitive = true
  default = []
}

# ------------------------------------------------------------------------------
# Container Volume Variables
# ------------------------------------------------------------------------------

variable "container_volumes" {
  description = <<-EOT
    List of volumes available to be mounted (e.g., hostPath, emptyDir).
    Secrets defined in 'container_secrets_from_sm' are handled separately via 'secret_mount_path'.
    Example for hostPath: { name = "config-vol", hostPath = { path = "/path/on/host" } }
    Example for emptyDir: { name = "cache-vol", emptyDir = {} }
  EOT
  type = list(object({
    name = string
    hostPath = optional(object({ path = string }))
    emptyDir = optional(object({}))
  }))
  default = []
}

variable "container_volume_mounts" {
  description = <<-EOT
    List of volume mounts for the container. References volumes defined in 'container_volumes'.
    Secret mounts are handled automatically via 'container_secrets_from_sm' and 'secret_mount_path'.
    Example: { name = "config-vol", mountPath = "/etc/app/config" }
  EOT
  type = list(object({
    name      = string
    mountPath = string
    readOnly = optional(bool, false)
  }))
  default = []
}

variable "create_backend_service" {
  description = "Whether to create Load Balancer Backend Service components (requires health check info)."
  type        = bool
  default     = true
}

variable "health_check_port" {
  description = "The port on the instance to use for health checks. Required if create_backend_service is true or auto-healing is desired."
  type        = number
  default     = null
}

variable "health_check_endpoint" {
  description = "The HTTP request path for health checks. Required for HTTP health checks."
  type        = string
  default     = "/health"
}

variable "enable_drive_access" {
  description = "Whether to enable Google Drive access for the instance(s)."
  type        = bool
  default     = false
}

variable "url_subpath_name" {
  description = "The subpath for the URL to access the service"
  type        = string
  default     = ""
}