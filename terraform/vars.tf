variable "domain_config_file" {
  description = "Path to the domain configuration file"
  default     = "../domain.yml"
}

variable "servers_subnet_cidr" {
  description = "CIDR to use for the Servers subnet"
  default     = "10.0.10.0/24"
}

variable "workstations_subnet_cidr" {
  description = "CIDR to use for the Workstations subnet"
  default     = "10.0.11.0/24"
}

variable "region" {
  description = "Azure region in which resources should be created. See https://azure.microsoft.com/en-us/global-infrastructure/locations/"
  default     = "West Europe"
}

variable "resource_group" {
  # Warning: see https://github.com/christophetd/adaz/blob/master/doc/faq.md#how-to-change-the-name-of-the-resource-group-in-which-resources-are-created
  description = "Resource group in which resources should be created. Will automatically be created and should not exist prior to running Terraform"
  default     = "ad-hunting-lab"
}

variable "server_vm_size" {
  description = "Size of the Windows Server VMs. See https://docs.microsoft.com/en-us/azure/cloud-services/cloud-services-sizes-specs"
  default     = "Standard_D1_v2"
}

variable "workstations_vm_size" {
  description = "Size of the workstations VMs. See https://docs.microsoft.com/en-us/azure/cloud-services/cloud-services-sizes-specs"
  default     = "Standard_D1_v2"
}

variable "server_image_version" {
  description = "The Windows Server image version to use for the Windows Server VMs. See https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage"
  type = object({
    sku     = string
    version = string
  })
  default = {
    sku     = "2022-Datacenter"
    version = "latest"
  }
}

variable "workstations_image_version" {
  description = "The Windows Client image version to use for the workstation VMs. See https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage"
  type = object({
    offer   = string
    sku     = string
    version = string
  })
  default = {
    offer   = "Windows-10"
    sku     = "win10-21h2-pron"
    version = "latest"
  }
}
