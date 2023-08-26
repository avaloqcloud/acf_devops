// Copyright (c) 2023 Avaloq and/or its affiliates.
// Licensed under the Apache 2.0 license shown at https://www.apache.org/licenses/LICENSE-2.0.

// readme.md created with https://terraform-docs.io/: terraform-docs markdown --sort=false ./ > ./readme.md

terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

provider "oci" {
  alias  = "home"
  region = var.region
}

provider "oci" {
  alias  = "target"
  region = var.loc
}

data "oci_core_services" "all" {
    filter {
        name   = "name"
        values = ["All .* Services In Oracle Services Network"]
        regex  = true
    }
}

data "oci_core_services" "storage" {
    filter {
        name   = "name"
        values = ["OCI .* Object Storage"]
        regex  = true
    }
}

locals {
  class = anytrue ([
    !contains(["FINMA", "BAFIN", "MARS"], var.cls),
    var.cis, 
    var.pci,
    var.c5
  ])
  stage = {
    "DEV"  = 0
    "SIT"  = 1
    "UAT"  = 2
    "PROD" = 3
  }
  osn = {
    "ALL"     = lookup(data.oci_core_services.all.services[0], "id")
    "STORAGE" = lookup(data.oci_core_services.storage.services[0], "id")
    "DISABLE" = "disabled"
  }
}