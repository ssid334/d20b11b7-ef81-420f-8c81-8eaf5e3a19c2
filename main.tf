provider "google" {
  credentials = var.credential_file
  project = var.project
  region  = "us-east1"
  zone    = "us-central1-c"
}


resource "google_project_service" "project" {
  project = var.project

  for_each = toset([
         "appengine.googleapis.com"
        ,"cloudfunctions.googleapis.com"
        ,"pubsub.googleapis.com"
        ,"cloudscheduler.googleapis.com"
	,"cloudresourcemanager.googleapis.com"
	,"compute.googleapis.com"
  ])

  service = each.key
  disable_dependent_services=true
}


resource "google_app_engine_application" "app" {
  project     = var.project
  location_id = "us-central"
}

resource "random_id" "instance_id" {
 byte_length = 8
}


resource "google_compute_instance" "default" {
 name         = "vm-autodisabletest-${random_id.instance_id.hex}"
 machine_type = "f1-micro"
 zone         = "us-central1-c"
 labels       = {"instance-scheduler" = var.label_value }

 boot_disk {
   initialize_params {
     image = "debian-cloud/debian-9"
   }
 }

 network_interface {
   network = "default"

   access_config {
     // Include this section to give the VM an external ip address
   }
 }
 depends_on = [google_project_service.project]
}


resource "google_storage_bucket" "bucket" {
  name = var.scheduler_function_bucket
}

resource "google_storage_bucket_object" "archive" {
  name   = "gfunc.zip"
  bucket = google_storage_bucket.bucket.name
  source = "gfunc/gfunc.zip"
}

resource "google_pubsub_topic" "topic_start" {
  // name = "instance-scheduler-topic"
  name = "startvm-topic"
  depends_on = [google_project_service.project]
}

resource "google_pubsub_topic" "topic_stop" {
  name = "stopvm-topic"
  depends_on = [google_project_service.project]
}

resource "google_cloudfunctions_function" "function_start_vm" {
  name                  = "function_startvm"
  description           = "startvm"
  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.archive.name
  runtime               = "python37"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.topic_start.name
    failure_policy {
      retry = false
    }
  }

  timeout               = 120
  entry_point           = "scheduler_start"

  environment_variables = {
    PROJECT     = var.project
    LABEL_KEY   = var.label_key
    LABEL_VALUE = var.label_value
  }
 depends_on = [google_project_service.project]
}

resource "google_cloudfunctions_function" "function_stop_vm" {
  name                  = "function_stopvm"
  description           = "startvm"
  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.archive.name
  runtime               = "python37"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.topic_stop.name
    failure_policy {
      retry = false
    }
  }

  timeout               = 120
  entry_point           = "scheduler_stop"

  environment_variables = {
    PROJECT     = var.project
    LABEL_KEY   = var.label_key
    LABEL_VALUE = var.label_value
  }
 depends_on = [google_project_service.project]
}

resource "google_cloud_scheduler_job" "job_stop" {
  name        = "scheduler-stopper"
  description = "stops vm at the given time"
  schedule    = var.pattern_stop
  time_zone   = var.timezone
  region      = "us-central1"

  pubsub_target {
    topic_name = google_pubsub_topic.topic_stop.id
    data       = base64encode("scheduler says stop")
  }
 depends_on = [google_project_service.project]
}

resource "google_cloud_scheduler_job" "job_start" {
  name        = "scheduler-starter"
  description = "starts vm at the given time"
  schedule    = var.pattern_start
  time_zone   = var.timezone
  region      = "us-central1"

  pubsub_target {
    topic_name = google_pubsub_topic.topic_start.id
    data       = base64encode("scheduler says start")
  }
 depends_on = [google_project_service.project]
}

