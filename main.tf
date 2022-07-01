#get the data fro the global vars WS
data "terraform_remote_state" "global" {
  backend = "remote"
  config = {
    organization = "CiscoCX_LSSE_Learn"
    workspaces = {
      name = var.globalwsname
    }
  }
}

variable "globalwsname" {
  type        = string
  description = "TFCB workspace name that has all of the global variables"
}
variable "api_key" {
  type        = string
  description = "API key for Intersight user"
}

variable "secretkey" {
  type        = string
  description = "Secret key for Intersight user"
}

terraform {
  required_providers {
    intersight = {
      source = "CiscoDevNet/intersight"
      version = ">=1.0.18"
    }
  }
}

provider "intersight" {
  apikey    = var.api_key
  secretkey = var.secretkey
  endpoint = "https://intersight.com"
}

module "infra_config_policy" {
  source           = "terraform-cisco-modules/iks/intersight//modules/infra_config_policy"
  version          = "1.0.2"
  name             = local.infra_config_policy
  device_name      = local.device_name
  vc_portgroup     = [local.portgroup]
  vc_datastore     = local.datastore
  vc_cluster       = local.vspherecluster
  vc_resource_pool = local.resource_pool
  vc_password      = local.password
  org_name         = local.organization
}

module "ip_pool_policy" {
  source           = "terraform-cisco-modules/iks/intersight//modules/ip_pool"
  version          = "1.0.2"
  name             = local.ip_pool_policy
  starting_address = local.starting_address
  pool_size        = local.pool_size
  netmask          = local.netmask
  gateway          = local.gateway
  primary_dns      = local.primary_dns
  
  org_name = local.organization
}

module "network" {
  source      = "terraform-cisco-modules/iks/intersight//modules/k8s_network"
  version     = "1.0.2"
  #policy_name = "rtp-iks-cluster"
  policy_name = local.clustername
  dns_servers = [local.primary_dns]
  ntp_servers = ["198.19.255.137"]
  timezone    = local.timezone
  domain_name = local.domain_name
  org_name    = local.organization
}

#module "k8s_version" {
#  source           = "terraform-cisco-modules/iks/intersight//modules/version"
#  version          = "1.0.2"
#  k8s_version      = local.k8s_version
#  k8s_version_name = local.k8s_version_name

#  org_name = local.organization
#}

module "k8s_version_1-19-15-iks3" {
  source           = "terraform-cisco-modules/iks/intersight//modules/version"
  version = "2.2.0"
  policyName     = local.k8s_version_name
  # policyName     = "1.21.10-iks.0"
  iksVersionName = "1.21.10-iks.0"
  org_name = local.organization
#  tags     = var.tags
}

data "intersight_organization_organization" "organization" {
  name = local.organization
}
resource "intersight_kubernetes_virtual_machine_instance_type" "masterinstance" {
  name      = local.masterinstance
  cpu       = local.cpu
  disk_size = local.disk_size
  memory    = local.memory
  organization {
    object_type = "organization.Organization"
    moid        = data.intersight_organization_organization.organization.results.0.moid
  }
}



locals {
  masterinstance = yamldecode(data.terraform_remote_state.global.outputs.masterinstance)
  cpu = yamldecode(data.terraform_remote_state.global.outputs.cpu)
  disk_size = yamldecode(data.terraform_remote_state.global.outputs.disk_size)
  memory = yamldecode(data.terraform_remote_state.global.outputs.memory)
  organization= yamldecode(data.terraform_remote_state.global.outputs.organization)
  k8s_version = yamldecode(data.terraform_remote_state.global.outputs.k8s_version)
  k8s_version_name = yamldecode(data.terraform_remote_state.global.outputs.k8s_version_name)
  clustername = yamldecode(data.terraform_remote_state.global.outputs.clustername)
  primary_dns = yamldecode(data.terraform_remote_state.global.outputs.primary_dns)
  timezone = yamldecode(data.terraform_remote_state.global.outputs.timezone)
  domain_name = yamldecode(data.terraform_remote_state.global.outputs.domain_name)
  ip_pool_policy = yamldecode(data.terraform_remote_state.global.outputs.ip_pool_policy)
  starting_address = yamldecode(data.terraform_remote_state.global.outputs.starting_address)
  pool_size = yamldecode(data.terraform_remote_state.global.outputs.pool_size)
  netmask = yamldecode(data.terraform_remote_state.global.outputs.netmask)
  gateway = yamldecode(data.terraform_remote_state.global.outputs.gateway)
  infra_config_policy = yamldecode(data.terraform_remote_state.global.outputs.infra_config_policy)
  device_name = yamldecode(data.terraform_remote_state.global.outputs.device_name)
  portgroup = yamldecode(data.terraform_remote_state.global.outputs.portgroup)
  password = yamldecode(data.terraform_remote_state.global.outputs.password)
#  portgroup = "VM Network"
  datastore = yamldecode(data.terraform_remote_state.global.outputs.datastore)
  vspherecluster = yamldecode(data.terraform_remote_state.global.outputs.vspherecluster)
  resource_pool = yamldecode(data.terraform_remote_state.global.outputs.resource_pool)

}
