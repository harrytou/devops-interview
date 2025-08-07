data "google_compute_image" "this" {
  family      = var.image_family
  project     = var.image_project_id
  most_recent = true
}
