/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  cluster_type           = "kiwonlee-autopilot-public"
  network_name           = "kiwonlee-autopilot-public-network"
  subnet_name            = "kiwonlee-autopilot-public-subnet"
  master_auth_subnetwork = "kiwonlee-autopilot-public-master-subnet"
  pods_range_name        = "ip-range-pods-kiwonlee-autopilot-public"
  svc_range_name         = "ip-range-svc-kiwonlee-autopilot-public"
  subnet_names           = [for subnet_self_link in module.gcp-network.subnets_self_links : split("/", subnet_self_link)[length(split("/", subnet_self_link)) - 1]]
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/beta-autopilot-public-cluster"
  version = "~> 36.0"

  project_id                      = var.project_id
  name                            = "${local.cluster_type}-cluster"
  regional                        = true
  region                          = var.region
  network                         = module.gcp-network.network_name
  subnetwork                      = local.subnet_names[index(module.gcp-network.subnets_names, local.subnet_name)]
  ip_range_pods                   = local.pods_range_name
  ip_range_services               = local.svc_range_name
  release_channel                 = "REGULAR"
  network_tags                    = [local.cluster_type]
  security_posture_mode           = "BASIC"              # Security Posture - Basic
  create_service_account          = false
}
