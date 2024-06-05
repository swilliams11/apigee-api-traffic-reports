ALTER TABLE apigee_reports.ApigeeTrafficUsage
ADD COLUMN rundate DATETIME DEFAULT CURRENT_DATETIME();

# Alternative method
ALTER TABLE apigee_reports.ApigeeTrafficUsage ADD COLUMN rundate DATETIME;

ALTER TABLE apigee_reports.ApigeeTrafficUsage ALTER COLUMN rundate SET DEFAULT CURRENT_DATETIME(); 
 
UPDATE apigee_reports.ApigeeTrafficUsage SET rundate = CURRENT_DATETIME() WHERE TRUE;