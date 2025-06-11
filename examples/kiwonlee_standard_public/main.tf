/**
 * Copyright 2018-2024 Google LLC
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
  cluster_type           = "kiwonlee-stadnard-public"
  network_name           = "kiwonlee-stadnard-public-network"
  subnet_name            = "kiwonlee-stadnard-public-subnet"
  master_auth_subnetwork = "kiwonlee-stadnard-public-master-subnet"
  pods_range_name        = "ip-range-pods-kiwonlee-stadnard-public"
  svc_range_name         = "ip-range-svc-kiwonlee-stadnard-public"
  subnet_names           = [for subnet_self_link in module.gcp-network.subnets_self_links : split("/", subnet_self_link)[length(split("/", subnet_self_link)) - 1]]
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "~> 36.0"

  project_id                = var.project_id
  name                      = "${local.cluster_type}-cluster"
  regional                  = true
  region                    = var.region
  network                   = module.gcp-network.network_name
  subnetwork                = local.subnet_names[index(module.gcp-network.subnets_names, local.subnet_name)]
  ip_range_pods             = local.pods_range_name
  ip_range_services         = local.svc_range_name
  create_service_account    = false
  # service_account           = var.compute_engine_service_account
  default_max_pods_per_node = 20
  #remove_default_node_pool = true
  gateway_api_channel	      = CHANNEL_STANDARD    # GatewayAPI
  dns_cache                 = true                # NodeLocal DNSCache 
  datapath_provider         = ADVANCED_DATAPATH   # Dataplane V2
  enable_gcfs               = true                # image streming

  node_pools = [
    {
      name                = "nodepool-01"
      machine_type        = "e2-medium"
      spot                = false
      min_count           = 0
      max_count           = 3
      initial_node_count  = 1
      auto_repair         = true
      auto_upgrade        = true
    }
  ]
}
