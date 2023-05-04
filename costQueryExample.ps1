

# Specifiy the account, get the context and get the authorization token
#-------------------------------------------------------------------------------

Connect-AzAccount

$tenant = <ENTER YOUR TENANT ID>
$subscription = <ENTER YOUR SUBSCRIPTION ID>


Set-AzContext -Tenant $tenant -Subscription $subscription 


$dexResourceUrl="https://management.azure.com/"
$context = Get-AzContext
$token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, $dexResourceUrl).AccessToken

$authHeader = @{
    'Content-Type'  = 'application/json'
    'Authorization' = 'Bearer ' + $token
}


$apiVersion = "2022-10-01"

# First Demo: 

# Display which dimensions could be used for grouping and filtering
# Note: Not relevant for current ask, but helps to understand what is possible
# doc : https://learn.microsoft.com/en-us/rest/api/cost-management/dimensions
#--------------------------------------------------------------------------------


$UriDimensions = "https://management.azure.com/subscriptions/$subscription/providers/Microsoft.CostManagement/dimensions?api-version=$apiVersion"

$availableDimensions = Invoke-RestMethod -Method Get -Uri $UriDimensions  -Headers $authHeader


# Second Demo: 

# Query the cost management API with Filters (see example below) and groupings on selected dimensions
# Note: 
# doc : https://learn.microsoft.com/en-us/rest/api/cost-management/query/usage?tabs=HTTP
#--------------------------------------------------------------------------------


#Specify the Query Details (incl. Filter and grouping attributes)

$body = '{
    "type": "Usage",
    "timeframe": "custom",
    "timeperiod": {
                   from: "2023-03-01T00:00:00+00:00",
                   to: "2023-03-31T23:59:59+00:00"
                },
    "dataSet": {
        "granularity": "Daily",
        "aggregation": {
               "totalCost" :  {
                        "name" : "PreTaxCost",
                        "function" : "Sum"
                },
                "totalUsage": {
                                "function": "Sum",
                                "name": "UsageQuantity"
                              }
        },
        "sorting": [
            {
                "direction": "ascending",
                "name": "UsageDate"
            }
        ],
        "grouping": [
            {
                "type": "Dimension",
                "name": "ResourceId"
            },
            {
                "type": "Dimension",
                "name": "ResourceLocation"
            },
            {
                "type": "Dimension",
                "name": "ResourceType"
            },
            {
                "type": "Dimension",
                "name": "ServiceName"
            },
            {
                "type": "Dimension",
                "name": "ServiceFamily"
            },
            {
                "type": "Dimension",
                "name": "Meter"
            },
            {
                "type": "Dimension",
                "name": "MeterSubCategory"
            },
            {
                "type": "Dimension",
                "name": "UnitOfMeasure"
            },
            {
                "type": "TagKey",
                "name": "costcenter"
            }
        ],
        "filter": 
        {
            "dimensions" : {
                "name" : "ResourceType",
                "operator" : "In",
                "values" : [
                    "microsoft.compute/virtualmachines",
                    "microsoft.compute/virtualmachinescalesets"
                ]
            }
        }
    }
}'



# Call the Rest API

#Setting the Scope on Subscrition Level through .../subscriptions/your-subscription-id/....

$UriUsageQuery = "https://management.azure.com/subscriptions/$subscription/providers/Microsoft.CostManagement/query?api-version=$apiVersion"
$outputRestCall = Invoke-RestMethod -Method Post -Uri $UriUsageQuery  -Headers $authHeader -Body $body

# Format the Output in a more readable format and extract additional information from the resourceId string

$tableOutput = $outputRestCall.properties.rows | ForEach-Object {
    $preTaxCost, $totalUsage,$date, $resourceId, $resourceLocation, $resourceType, $serviceName, $serviceFamily, $meter, $meterSubCategory, $unitOfMeasure, $tagname, $tagvalue, $currency = $_
    $subscription, $resourceGroup, $providerPre, $providerType, $resource = ($resourceId -split '/')[2,4,6,7,8]
    if ($serviceFamily = 'Compute') {
        $cores = $meter -replace '\D+([0-9]*).*','$1'
        $coreHours = [int] $cores * [double] $totalUsage
    } else {
        $cores = ''
        $coreHours = ''
    }
    
     [PSCustomObject]@{
        Date = $date
        subscription = $subscription
        resourceGroup = $resourceGroup
        resourceLocation = $resourceLocation
        resource = $resource
        resourceType = $resourceType
        serviceName = $serviceName
        #serviceFamily = $serviceFamily
        meter = $meter
        cores = $cores
        meterSubCategory = $meterSubCategory
        totalUsage = $totalUsage
        UnitOfMeasure = $unitOfMeasure
        coreHours = $coreHours
        PreTaxCost = $preTaxCost
        Currency = $currency
        tagname = $tagname
        tagCostcenter = $tagvalue
        #ResourceId = $resourceId
    }
}

# Output the resutls into the command line

$tableOutput | Format-Table
 
# Export the output into a csv file

$tableOutput |Export-Csv costQueryExample.csv -NoTypeInformation


