CREATE TABLE `$PROJECT_ID.apigee_reports.ApigeeTrafficUsage`
(
 organization STRING NOT NULL,
 environment STRING NOT NULL,
 proxy STRING NOT NULL,
 count INT64 NOT NULL,
 date STRING NOT NULL,
 timestamp TIMESTAMP NOT NULL
);
