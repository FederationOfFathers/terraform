provider "google" {
  credentials = "${file("${var.gcp_credentials_file_path}")}"
}

resource "google_project" "fof" {
    name = "Federation of Fathers"
    project_id = "federation-of-fathers"
}

resource "google_project_services" "fofservices" {
  project = "${google_project.fof.project_id}"
  services = [
    "serviceusage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "compute.googleapis.com",
    "oslogin.googleapis.com",

  ]
}

resource "google_project_iam_binding" "os-login-admin-users" {
  project = "${google_project.fof.project_id}"
  members = [
    "user:cherian.benjamin@gmail.com"
  ]
  role = "roles/compute.osAdminLogin"
}


resource "google_compute_instance" "main_vm" {
  project = "${google_project.fof.project_id}"
  machine_type = "f1-micro"
  zone = "us-east1-b"
  name = "fof-main-vm"
  allow_stopping_for_update = true

  metadata {
    enable-oslogin = "TRUE"
  }
  "boot_disk" {
    auto_delete = true

    initialize_params {
      size = 30
      type = "pd-standard"
      image = "centos-7-v20190213"
    }
  }

  "network_interface" {
    network="default"
    access_config {

    }

  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "${var.gcp_user}"
//      agent = false
      private_key = "${file("${var.gcp_private_key}")}"
      timeout = "120s"
    }
    inline = [
      "sudo yum -y update",
      "sudo yum -y install yum-utils device-mapper-persistent-data lvm2",
      "sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo", // systemctl daemon-reload
      "sudo yum -y install docker-ce docker-ce-cli containerd.io",
      "sudo systemctl start docker",
      "sudo docker swarm init"
    ]
  }
}