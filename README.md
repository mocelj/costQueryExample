# costQueryExample
Simple Code Example how to invoke the cost management API for compute and extract core hours and associated costs.

This is a simple example how to invoke the cost management API through PowerShell.  Further information can be found here: https://learn.microsoft.com/en-us/rest/api/cost-management/query/usage?tabs=HTTP


Notes:

- Please ensure caller has the appropriate RBAC permission to access the cost management API.

- Please ensure if all dimensons are exposed in your subscription. You can verfiy this by runnin first the first query which will expose all available dimensions. Adjust the query body and the table formatting block accordingly. 
