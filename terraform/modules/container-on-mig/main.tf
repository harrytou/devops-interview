resource "google_compute_instance_group_manager" "this" {
  name               = local.base_resource_name
  base_instance_name = local.base_resource_name
  target_size        = 1
  zone               = var.zone

  update_policy {
    type                           = "PROACTIVE"
    minimal_action                 = "REPLACE"
    most_disruptive_allowed_action = "REPLACE"
    max_surge_fixed                = 0
    max_unavailable_fixed          = 1
    replacement_method             = "RECREATE"
  }

  version {
    instance_template = google_compute_instance_template.this.self_link
  }

  dynamic "stateful_external_ip" {
    for_each = var.assign_static_external_ip ? [1] : []

    content {
      delete_rule    = "NEVER"
      interface_name = try(google_compute_instance_template.this.network_interface[0].name, null)
    }
  }

  dynamic "stateful_disk" {
    for_each = var.additional_disks
    content {
      device_name = stateful_disk.value.device_name
      delete_rule = "NEVER"
    }
  }

  dynamic "named_port" {
    for_each = var.container_ports
    content {
      name = "tcp-${named_port.value}"
      port = named_port.value
    }
  }

  lifecycle {
    ignore_changes = [target_size]
  }
}

resource "google_compute_instance_template" "this" {
  name_prefix  = "${local.base_resource_name}-"
  description  = "Instance template for the ${local.base_resource_name} service"
  machine_type = var.machine_type

  # Boot disk configuration
  disk {
    auto_delete  = true
    boot         = true
    device_name  = "boot-disk"
    disk_type    = var.boot_disk_type
    disk_size_gb = var.boot_disk_size_gb
    source_image = data.google_compute_image.this.self_link
  }

  scheduling {
    preemptible       = var.is_preemptible_machine
    automatic_restart = !var.is_preemptible_machine
  }

  # Persistent disk configuration
  dynamic "disk" {
    for_each = var.additional_disks
    content {
      auto_delete  = disk.value.auto_delete
      device_name  = disk.value.device_name
      disk_size_gb = disk.value.disk_size_gb
      disk_type    = disk.value.disk_type
      labels       = disk.value.labels
    }
  }

  # Network configuration
  network_interface {
    subnetwork = var.subnet_name
  }

  # Metadata and startup script (if needed)
  metadata = {
    enable-oslogin            = "TRUE"
    gce-container-declaration = yamlencode(local.container_spec)
  }

  # Optional startup script
  metadata_startup_script = <<-EOT
    ${var.metadata_startup_script}
  EOT

  # Enable service account with necessary permissions. Using "cloud-platform" scope enables us to actually use IAM
  # policies to restrict access to specific resources.
  service_account {
    email  = google_service_account.this.email
    scopes = var.enable_drive_access
  }

  # Extra labels on top of the default labels defined in the provider block
  labels = {}

  # Enable Shielded VM features for additional security (optional)
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }


  # Configure tags if needed for network firewall rules
  tags = local.effective_network_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_service_account" "this" {
  account_id   = local.base_resource_name
  display_name = "Service Account for ${local.base_resource_name}"
}
