variable "gcp_service_list" {
  description = "The list of apis necessary for the project"
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "integrations.googleapis.com",
    "connectors.googleapis.com"
  ]
}

variable "project_id" {
  type    = string
  default = "MY_PROJECT_ID"
}

variable "apigee_org_name" {
  type    = string
  default = "MY_PROJECT_ID"
}

variable "integration_region" {
  type    = string
  default = "us-central1"
}

variable "project_number" {
    type = string
    default = "MY_PROJECT_NUMBER"
}

variable "bq_dataset_id"{
    type = string
    default = "apigee_reports_terraform"
}

variable "bq_table_name"{
    type = string
    default = "ApigeeTrafficUsage"
}

variable "connector_region"{
    type = string
    default = "us-central1"
}

variable "intergrations_src_folder"{
  type = string
    default = "integrations/api_count_bq/src/"
}

variable "intergrations_config_vars_folder"{
  type = string
    default = "integrations/api_count_bq/dev/config-variables/"
}