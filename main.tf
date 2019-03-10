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

resource "google_compute_network" "main-vm-nw" {
  project = "${google_project.fof.project_id}"
  name = "main-vm-nw"
  auto_create_subnetworks = "true"
}

resource "google_compute_firewall" "docker-machine-ssh" {
  name = "docker-machine-ssh"
  project = "${google_project.fof.project_id}"
  network = "${google_compute_network.main-vm-nw.name}"
  priority = 65530
  allow {
    protocol = "tcp"
    ports = ["22"]

  }
  source_ranges = ["0.0.0.0/0"]
//  source_ranges = ["${chomp("${data.http.icanhazip.body}")}/32"]
  depends_on = ["google_compute_network.main-vm-nw"]
}

resource "google_compute_firewall" "main-vm-http" {
  name = "main-vm-http"
  project = "${google_project.fof.project_id}"
  network = "${google_compute_network.main-vm-nw.name}"
  priority = 65530
  allow {
    protocol = "tcp"
    ports = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
  depends_on = ["google_compute_network.main-vm-nw"]
}

resource "google_compute_firewall" "docker-machine-tcp" {
  name = "docker-machine-tcp"
  project = "${google_project.fof.project_id}"
  network = "${google_compute_network.main-vm-nw.name}"
  priority = 65530
  allow {
    protocol = "tcp"
    ports = ["${var.docker_remote_port}"]

  }
  source_ranges = ["${chomp("${data.http.icanhazip.body}")}/32"]
  depends_on = ["google_compute_network.main-vm-nw"]
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

  depends_on = ["google_compute_network.main-vm-nw"]

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
    network="${google_compute_network.main-vm-nw.name}"
    access_config {

    }

  }

  provisioner "file" {
    connection {
      type = "ssh"
      user = "${var.gcp_user}"
      private_key = "${file("${var.gcp_private_key}")}"
      timeout = "120s"
    }
    source = "resources/docker.service.conf"
    destination = "~/docker.service.conf"
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "${var.gcp_user}"
      private_key = "${file("${var.gcp_private_key}")}"
      timeout = "120s"
    }
    inline = [
      "sudo yum -y update",
      "sudo yum -y install yum-utils device-mapper-persistent-data lvm2",
      "sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo", //
      "sudo yum -y install docker-ce docker-ce-cli containerd.io",
      "sudo mkdir /etc/systemd/system/docker.service.d",
      "sudo cp ~/docker.service.conf /etc/systemd/system/docker.service.d/override.conf",
      "sudo systemctl daemon-reload",
      "sudo systemctl start docker", // /etc/systemd/system/docker.service.d/override.conf. https://docs.docker.com/install/linux/linux-postinstall/#configure-where-the-docker-daemon-listens-for-connections, systemctl daemon-reload
      "sudo systemctl enable docker",
      "sudo docker swarm init"
    ]
  }
}

provider "docker" {
  host = "tcp://${google_compute_instance.main_vm.network_interface.0.access_config.0.nat_ip}:${var.docker_remote_port}"
//  depends_on = "google_compute_instance.main_vm"
}

resource "docker_container" "nginx" {
  image = "${docker_image.nginx.latest}"
  name = "nginx"
}

resource "docker_image" "nginx" {
  name = "nginx:alpine"
}

resource "docker_service" "fof-nginx" {
  name = "fof-nginx"

  task_spec {
    "container_spec" {
      image = "${docker_image.nginx.name}"
    }
  }

  endpoint_spec {
    ports {
      target_port = 80
      published_port = 80
    }
  }
}