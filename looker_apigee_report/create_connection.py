from looker_sdk import methods40, models40
import looker_sdk

# Initialize the Looker SDK (make sure to set environment variables for API credentials)
sdk = looker_sdk.init40()

# BigQuery connection details (Replace placeholders with your actual values)
connection_data = models40.WriteDBConnection(
    name="apigee_bigquery_connection",
    dialect="bigquery",
    project_id="PROJECT_ID",  # Your BigQuery project ID
    host="bigquery.cloud.google.com",
    additional_params={
        "service_account_json": "YOUR_SERVICE_ACCOUNT_JSON"  # Your BigQuery service account JSON key as a string
    }
)

# Create the connection
try:
    new_connection = sdk.create_connection(connection_data)
    print(f"New BigQuery connection created with ID: {new_connection.id}")

# Test the connection (optional)
    test_result = sdk.test_connection(new_connection.name)
    if test_result[0].status == 'success':
        print("Connection test successful!")
    else:
        print("Connection test failed:", test_result[0].message)

except Exception as e:
    print(f"Error creating connection: {e}")