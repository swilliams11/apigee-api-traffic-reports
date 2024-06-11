# apigee-api-traffic-reports - WIP
This repo is still a work in progress (see the TODOs below).

## Business Case for this Repository
Customers need a consistent way to traffic Apigee X API counts across all of their Apigee organzations and environments.  Today this is accomplished with a variety of tools, which I've listed below or customers roll their own solution.  

## Summary
This repository contains everything you need to run an Apigee X API management traffic report consistently across all organizations.

## Features
Terrform performs the following tasks:
* Enables the necessary APIs in your project
* Creates two new service accounts with the following permissions
  * Service account with permissions to list environments and deployments
  * Service account to call the optimizedStats
  * Service account for the BQ connector.
* Assigns the Service Account Token Creator role to the Application Integration Service Agent (`service-PROJECT_NUMBER@gcp-sa-integrations.iam.gserviceaccount.com`).
[Service Account](https://cloud.google.com/application-integration/docs/configure-authentication-profiles#service-account)
* Creates the Authentication Profiles so that the REST API tasks can execute successfully.
* Creates BigQuery Dataset and Table.
* Creates the Connectors
* Creates the integrations


## What's included?
* Application Integration that collects all API traffic across all Apigee organizations and environments
* Application Integration that writes the data to BigQuery
* Looker Report to display the BigQuery dataset
* Terraform script to deploy all resources

## Installation
For best results, you should run this in Cloud Shell, especially Windows users.

### Prerequisites
1. Install gcloud.
2. Install the [integration cli](https://github.com/GoogleCloudPlatform/application-integration-management-toolkit)

### Init
```shell
export PROJECT_ID=YOUR_PROJECT
gcloud auth login
gcloud auth application-default login
gcloud config set project $PROJECT_ID
```


### Terraform Apply
Execute the following commands from the apigee-api-traffic-reports folder. 

1. Update the `terraform.tfvars` file with the following values.
* `project_id`
* `project_number`

2. Execute the following commands. As of today, you must export `project` and `region` for the `integrationcli`.
```shell
export project=PROJECT_ID
export region=REGION
terraform init
terraform apply
```


## Google Cloud
This is NOT an officially supported Google Cloud product.  Best effort is provided. 

## TODOs
1. ~~Add deployment of Integrations~~
2. Allow user to add multiple organizations in the `terraform.tfvars`; only one org is supported today.
3. Provide clear way for initializing the BQ table and running the integration every day. Need documentation on this. 
4. Update the BQ table to separate the month and year as STRING columns.
3. Add deployment of Looker reports via looker API
  * Look, 
  * query and 
  * datasource

## Troubleshooting and Testing/Development Commands
### Integration CLI

```
project=$(gcloud config get-value project | head -n 1)
region=us-central1
```

### Terraform Taint commands.
```shell
terraform taint null_resource.find_replace_config
terraform taint null_resource.find_replace_integration
terraform taint null_resource.upload_integration
```

### Terraform Destroy commands
```shell
terraform destroy -target=null_resource.upload_integration -target=null_resource.find_replace_integration -target=null_resource.find_replace_config -target=null_resource.upload_integration_bq
```

#### Connectors
Get the integration values. 
```
integrationcli connectors get -n cl-getapicount-to-bq -p $project -r $region --overrides=true --default-token --view FULL
```

Create the connector
```shell
integrationcli connectors create -n cl-getapicount-to-bq-tf -f bigquery_app_int_connector.json -p $project -r $region --sa SA_HERE --wait
```

this is the command you need to use. 
```shell
integrationcli connectors create -n cl-getapicount-to-bq-tf -f bigquery_app_int_connector.json --wait --sa SANAME --default-token
```

Delete the connector
```shell
integrationcli connectors delete -n cl-getapicount-to-bq-tf
```

Update the Node configuration.
```shell
integrationcli connectors nodecount update -n cl-getapicount-to-bq-tf --max=1 --min=1 --default-token --wait
```

#### Integrations

```shell
integrationcli integrations create -f integrations/src/cl-getApiCount-tf.json -n cl-getApiCount-tf -p $project -r $region --default-token

integrationcli integrations create -f integrations/src/cl-getApiCount-to-bq-tf.json -n cl-getApiCount-to-bq-tf -p $project -r $region --default-token
```

