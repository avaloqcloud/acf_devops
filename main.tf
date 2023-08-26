// Copyright (c) 2023 Avaloq and/or its affiliates.
// Licensed under the Apache 2.0 license shown at https://www.apache.org/licenses/LICENSE-2.0.

// readme.md created with https://terraform-docs.io/: terraform-docs markdown --sort=false ./ > ./readme.md

// --- configuration --- //
module "configuration" {
  source         = "github.com/avaloqcloud/acf_ctl_config"
  providers = {oci = oci.home}
  account = {
    compartment_id = var.compartment_ocid
    controls = flatten(compact([
      var.cls,
      var.cis == true ? "cis" : "", 
      var.pci == true ? "pci" : "",  
      var.c5  == true ? "c5" : ""
    ]))
    home           = var.region
    label    = format(
      "%s%s%s", 
      lower(substr(var.org, 0, 3)), 
      lower(substr(var.prj, 0, 2)),
      lower(substr(var.stg, 0, 3)),
    )
    location   = var.loc
    name       = lower("${var.org}_${var.prj}_${var.stg}")
    owner      = var.own
    parent_id  = var.prt
    services   = local.osn[var.osn]
    stage      = local.stage[var.stg]
    source     = var.src
    scope      = flatten(compact([
      var.acp    == true ? "acp" : "", 
      var.client == true ? "client" : "",  
      var.capi   == true ? "capi" : ""
    ]))
    tenancy_id = var.tenancy_ocid
    user_id    = var.current_user_ocid
  }
}
output "configuration" {
  value = {for resource, parameter in module.configuration : resource => parameter}
}
// --- configuration --- //

/*/ --- operation controls --- //
module "resident" {
  source     = "./assets/resident"
  depends_on = [module.configuration]
  providers  = {oci = oci.home}
  schema = {
    # Enable compartment delete on destroy. If true, compartment will be deleted when `terraform destroy` is executed; If false, compartment will not be deleted on `terraform destroy` execution
    enable_delete = var.stage != "PRODUCTION" ? true : false
    # Reference to the deployment root. The service is setup in an encapsulating child compartment 
    parent_id     = var.tenancy_ocid
    user_id       = var.current_user_ocid
  }
  config = {
    tenancy = module.configuration.tenancy
    service = module.configuration.service
  }
}
output "resident" {
  value = {for resource, parameter in module.resident : resource => parameter}
}
// --- operation controls --- //

// --- wallet configuration --- //
module "encryption" {
  source     = "./assets/encryption"
  depends_on = [module.configuration, module.resident]
  providers  = {oci = oci.service}
  for_each   = {for wallet in local.wallets : wallet.name => wallet}
  schema = {
    create = var.create_wallet
    type   = var.wallet == "SOFTWARE" ? "DEFAULT" : "VIRTUAL_PRIVATE"
  }
  config = {
    tenancy    = module.configuration.tenancy
    service    = module.configuration.service
    encryption = module.configuration.encryption[each.key]
  }
  assets = {
    resident   = module.resident
  }
}
output "encryption" {
  value = {for resource, parameter in module.encryption : resource => parameter}
  sensitive = true
}
// --- wallet configuration --- //

// --- network configuration --- //
module "network" {
  source     = "./assets/network"
  depends_on = [module.configuration, module.encryption, module.resident]
  providers = {oci = oci.service}
  for_each  = {for segment in local.segments : segment.name => segment}
  schema = {
    internet = var.internet == "PUBLIC" ? "ENABLE" : "DISABLE"
    nat      = var.nat == true ? "ENABLE" : "DISABLE"
    ipv6     = var.ipv6
    osn      = var.osn
  }
  config = {
    tenancy = module.configuration.tenancy
    service = module.configuration.service
    network = module.configuration.network[each.key]
  }
  assets = {
    encryption = module.encryption["main"]
    resident   = module.resident
  }
}
output "network" {
  value = {for resource, parameter in module.network : resource => parameter}
}
// --- network configuration --- //

// --- database creation --- //
module "database" {
  source     = "./assets/database"
  depends_on = [module.configuration, module.resident, module.network, module.encryption]
  providers  = {oci = oci.service}
  schema = {
    class    = var.class
    create   = var.create_adb
    password = var.create_wallet == false ? "RANDOM" : "VAULT"
  }
  config = {
    tenancy  = module.configuration.tenancy
    service  = module.configuration.service
    database = module.configuration.database
  }
  assets = {
    encryption = module.encryption["main"]
    network    = module.network["core"]
    resident   = module.resident
  }
}
output "database" {
  value = {for resource, parameter in module.database : resource => parameter}
  sensitive = true
}
// --- database creation --- /*/