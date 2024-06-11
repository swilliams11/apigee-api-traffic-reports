terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.32.0"
    }
  }
}

# # google_client_config and kubernetes provider must be explicitly specified like the following.
# data "google_client_config" "default" {
#   access_token = ""
# }



provider "google" {
  project = var.project_id
#   region  = var.compute_region
#   zone = var.compute_zone
}

# enable the required GCP services
# disabled for testing
# resource "google_project_service" "gcp_services" {
#   for_each = toset(var.gcp_service_list)
#   project = var.project_id
#   service = each.key
#    disable_dependent_services = true
# }

# ** SA for the Connector **
# Create a new Service Account for analytics role
resource "google_service_account" "app_int_bq_connector" {
  account_id   = "app-int-bq-connector"   # Choose a unique ID
  display_name = "App Int BQ Connector" 
  description  = "Service account for the App Int BQ Connector." # Optional
}

# assign role to the service account
resource "google_project_iam_member" "assign_role_to_bq_connector" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.app_int_bq_connector.email}"
}

# ** SA to get optimized Stats **
# Create new role
resource "google_project_iam_custom_role" "app_int_apigee_get_stats_role" {
  role_id     = "appIntApigeeGetStatsRole"
  title       = "app-int-apigee-get-stats-role"
  description = "Custom role to allow App Intergration to query Apigee analytics"
  permissions = ["apigee.environments.getStats"]
}

# Create a new Service Account for analytics role
resource "google_service_account" "app_int_apigee_get_stats" {
  account_id   = "app-int-apigee-get-stats"   # Choose a unique ID
  display_name = "App Int Apigee Get Stats" 
  description  = "Service account for Apigee get stats role." # Optional
}

# # Assign a role to the service account
# resource "google_service_account_iam_binding" "assign_get_stats_sa_to_role" {
#   service_account_id = google_service_account.app_int_apigee_get_stats.name
#   role    = google_project_iam_custom_role.app_int_apigee_get_stats_role.name
#   members  = []
# }

# assign role to the service account
resource "google_project_iam_member" "assign_get_stats_sa_to_role" {
  project = var.project_id
  role    = google_project_iam_custom_role.app_int_apigee_get_stats_role.name
  member  = "serviceAccount:${google_service_account.app_int_apigee_get_stats.email}"
}

# ** SA to list deployments and apigee environments
# Reporter Role: create custom role, Service Account and add role to the SA
resource "google_project_iam_custom_role" "apigee_env_list_role" {
  role_id     = "appIntListEnvsRole"
  title       = "app-int-apigee-list-envs-role"
  description = "Custom role to allow App Intergration to query Apigee deployments and environments"
  permissions = ["apigee.deployments.list", "apigee.environments.list"]
}

# Create a new Service Account for 
resource "google_service_account" "app_int_apigee_list_envs_sa" {
  account_id   = "app-int-apigee-list-envs"   # Choose a unique ID
  display_name = "App Int Apigee Environment List" 
  description  = "Service account for Apigee list environments role." # Optional
}

# Assign a role to the service account
# resource "google_service_account_iam_binding" "assign_envs_list_sa_to_role" {
#   service_account_id = google_service_account.app_int_apigee_list_envs_sa.name
#   role    = google_project_iam_custom_role.apigee_env_list_role.name
#   members  = []
# }

# assign role to the service account
resource "google_project_iam_member" "assign_envs_list_sa_to_role" {
  project = var.project_id
  role    = google_project_iam_custom_role.apigee_env_list_role.name
  member  = "serviceAccount:${google_service_account.app_int_apigee_list_envs_sa.email}"
}

# Update Application Integration default service agent to include the Service Account Token Creator role
resource "google_project_iam_member" "assign_service_creator_to_appint_agent" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-integrations.iam.gserviceaccount.com"
}


# Create Authentication Profiles
resource "google_integrations_client" "client" {
  location = "us-central1"
}

resource "google_integrations_auth_config" "app_int_apigee_env_list_auth_profile" {
    location = "us-central1"
    display_name = "app-int-apigee-env-list-profile"
    description = "Auth profile for Apigee Environment List - Terraform"
    visibility = "CLIENT_VISIBLE"
    decrypted_credential {
        credential_type = "SERVICE_ACCOUNT"
        service_account_credentials {
            service_account = google_service_account.app_int_apigee_list_envs_sa.email
            scope = "https://www.googleapis.com/auth/cloud-platform"
        }
    }
    
    depends_on = [google_integrations_client.client,
                google_project_iam_member.assign_envs_list_sa_to_role]
}

resource "google_integrations_auth_config" "app_int_apigee_stats_auth_profile" {
    location = "us-central1"
    display_name = "app-int-apigee-stats-profile"
    description = "Auth profile for Apigee Stats Analytics - Terraform"
    visibility = "CLIENT_VISIBLE"
    decrypted_credential{
        credential_type = "SERVICE_ACCOUNT"
        service_account_credentials {
            service_account = google_service_account.app_int_apigee_get_stats.email
            scope = "https://www.googleapis.com/auth/cloud-platform"
        }
    }
    depends_on = [google_integrations_client.client,
                google_project_iam_member.assign_envs_list_sa_to_role]
}

# BigQuery dataset
resource "google_bigquery_dataset" "apigee_reports_dataset" {
  dataset_id                  = var.bq_dataset_id   # The ID for the dataset
  friendly_name               = "Apigee API Traffic Reports"
  description                 = "A dataset for Apigee API traffic reports." # Optional
  location                    = "US"            # The location for the dataset

  labels = {
    "env" = "default"  # Optional labels for better organization
  }

  # (Optional) Additional configurations for access control, encryption, etc.
  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }
}


# BigQuery table
resource "google_bigquery_table" "apigee_traffic_reports_table" {
  #dataset_id = google_bigquery_dataset.apigee_reports_dataset.id
  dataset_id = var.bq_dataset_id
  table_id   = var.bq_table_name

  schema = jsonencode([
    {
      "name": "organization",
      "type": "STRING",
      "mode": "REQUIRED"
    },
    {
      "name": "environment",
      "type": "STRING",
      "mode": "REQUIRED"
    },
    {
      "name": "proxy",
      "type": "STRING",
      "mode": "REQUIRED"
    },
    {
      "name": "count",
      "type": "INTEGER",
      "mode": "REQUIRED"
    },
    {
      "name": "date",
      "type": "STRING",
      "mode": "REQUIRED"
    },
    {
      "name": "rundate",
      "type": "DATE",
      "mode": "REQUIRED"
    },    
  ])

}


# update the table schema to include the default value because the terraform module doesn't support this.
resource "null_resource" "update_table_schema" {
  depends_on = [google_bigquery_table.apigee_traffic_reports_table]

  provisioner "local-exec" {
    command = "bq query --use_legacy_sql=false 'ALTER TABLE ${var.bq_dataset_id}.${var.bq_table_name} ALTER COLUMN rundate SET DEFAULT CURRENT_DATE();'"
  }
}


# Create the Connector
resource "google_integration_connectors_connection" "bq_connection" {
  name     = "cl-getapicount-to-bq-tf"
  location = var.connector_region
  connector_version = "projects/${var.project_id}/locations/global/providers/gcp/connectors/bigquery/versions/1"
  description = "Terrform - BQ connector"
  service_account=google_service_account.app_int_bq_connector.email
  config_variable {
      key = "project_id"
      string_value = var.project_id
  }
  config_variable {
      key = "dataset_id"
      string_value = var.bq_dataset_id
  }
  node_config {
    min_node_count = 1
    max_node_count = 1
  }

}


# Replace the PROJECT and REGION in the config.json file. This is for the integration that needs BQ
resource "null_resource" "find_replace_config" {
   
  provisioner "local-exec" {
    when = create
    command = "python3 find_replace.py ${var.intergrations_config_vars_folder}cl-getApiCount-to-bq-tf-config.json __PROJECT__:${var.project_id} __REGION__:${var.integration_region}"
  }

  provisioner "local-exec" {
    when = destroy
    command = "rm -f integrations/api_count_bq/dev/config-variables/cl-getApiCount-to-bq-tf-config.json && cp integrations/api_count_bq/backup/cl-getApiCount-to-bq-tf-config.json integrations/api_count_bq/dev/config-variables/cl-getApiCount-to-bq-tf-config.json"
  }
}


# Replace the PROJECT and REGION in the integration.json file. 
resource "null_resource" "find_replace_integration" {
    depends_on = [null_resource.find_replace_config]
  provisioner "local-exec" {
    when = create
    command = "python3 find_replace.py ${var.intergrations_src_folder}cl-getApiCount-to-bq-tf.json __PROJECT__:${var.project_id} __REGION__:${var.integration_region}"
  }

  provisioner "local-exec" {
    when = destroy
    command = "rm -f integrations/api_count_bq/src/cl-getApiCount-to-bq-tf.json && cp integrations/api_count_bq/backup/cl-getApiCount-to-bq-tf.json integrations/api_count_bq/src/cl-getApiCount-to-bq-tf.json"
  }
}


resource "null_resource" "upload_integration" {
  # Add any dependencies that the script needs here
  depends_on = [null_resource.find_replace_config,
                null_resource.find_replace_integration
                ]

  # this does not deploy both intergrations; it only deploys one of them.
#   provisioner "local-exec" {
#     when = create
#     interpreter = ["bash", "-c"] 
#     command = "integrationcli integrations apply -f integrations/ -e dev -p ${var.project_id} -r ${var.connector_region} --default-token"
#   }
    provisioner "local-exec" {
        when = create
        interpreter = ["bash", "-c"]
        command = "integrationcli integrations create -f integrations/api_count/src/cl-getApiCount-tf.json -n cl-getApiCount-tf -p ${var.project_id} -r ${var.connector_region} --default-token"
  }

  provisioner "local-exec" {
    when    = destroy
    interpreter = ["bash", "-c"] 
    command = "integrationcli integrations delete -n cl-getApiCount-tf --default-token"
  }
}


resource "null_resource" "upload_integration_bq" {
  # Add any dependencies that the script needs here
  depends_on = [null_resource.find_replace_config,
                null_resource.find_replace_integration,
                google_integration_connectors_connection.bq_connection,
                null_resource.upload_integration
                ]

  # this does not deploy both intergrations; it only deploys one of them.
  provisioner "local-exec" {
    when = create
    interpreter = ["bash", "-c"] 
    command = "integrationcli integrations create -f integrations/api_count/src/cl-getApiCount-to-bq-tf.json -n cl-getApiCount-to-bq-tf -p ${var.project_id} -r ${var.connector_region} --default-token"
  }

  provisioner "local-exec" {
    when    = destroy
    interpreter = ["bash", "-c"] 
    command = "integrationcli integrations delete -n cl-getApiCount-to-bq-tf --default-token"
  }
}







