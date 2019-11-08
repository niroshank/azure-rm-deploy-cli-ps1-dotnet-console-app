<#
 .SYNOPSIS
    Deploys a template to Azure

 .DESCRIPTION
    Deploys an Azure Resource Manager template

 .PARAMETER SQL_SERVER
    1.The sql servername where the ouput will be stored.

 .PARAMETER DB_USERNAME
    2.The sql database username.

 .PARAMETER DB_PASSWORD
    3.The sql database password.

 .PARAMETER DB_NAME
    4.The sql database name

 .PARAMETER CLOUD_USERNAME
    5.The azure cloud Credentials username

 .PARAMETER CLOUD_PASSWORD
    6.The azure cloud Credentials password

 .PARAMETER RESOURCE_GROUP_NAME
    7.The resource group where the template will be deployed. Can be the name of an existing or a new resource group.

 .PARAMETER REGION
    8.The region of resource group

 .PARAMETER clientKey
	9.The client name and client ID

 .PARAMETER clientId
	10.The client Id

 .PARAMETER iotHubPackage
	11.The iothub Name of the sku

 .PARAMETER iotHubUnits
	12.Number of units

 .PARAMETER signalRPackage
	13.The SignalR service SKU. Default value:	Standard_S1

 .PARAMETER signalRUnits
	14.The SignalR service unit count, from 1 to 10. Default to 1.

 .PARAMETER storageAccountPackage
	15.The acceptable values for this parameter are: Standard_LRS.Standard_GRS. Standard_RAGRS. Premium_LRS.

 .PARAMETER storageAccountKind
	16.The acceptable values for this parameter are:Storage. StorageV2. BlobStorage. 

 .PARAMETER storageAccountAccessTier
	17.The acceptable values for this parameter are: Hot and Cool.

 .PARAMETER cosmosDbThroughputs
	18.Azure Cosmos container with shared throughput

 .PARAMETER cosmosDbAccountName
	19.Azure Cosmos container with shared throughput
#>

Param(
 $SQL_SERVER,
 $DB_USERNAME,
 $DB_PASSWORD,
 $DB_NAME,
 $CLOUD_USERNAME,
 $CLOUD_PASSWORD,
 $RESOURCE_GROUP_NAME,
 $REGION,
 $clientKey,
 $clientId,
 $iotHubPackage,
 $iotHubUnits,
 $signalRPackage,
 $signalRUnits,
 $storageAccountPackage,
 $storageAccountKind,
 $storageAccountAccessTier,
 $cosmosDbThroughputs,
 $cosmosDbAccountName
)

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
#Start Azure resource automation
#Sign in
$SecuredPassword = ConvertTo-SecureString $CLOUD_PASSWORD -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($CLOUD_USERNAME, $SecuredPassword)
Connect-AzureRmAccount -Credential $Credential -Subscription [your-subscription-Id] -Tenant [your-tenant-Id]

#Start the provisioning
#Create IotHub
$iotHubName = "iothub-" + $clientId
$keyName = "iothubowner"
New-AzureRmIotHub -ResourceGroupName $RESOURCE_GROUP_NAME -Name $iotHubName -Units $iotHubUnits -Location $REGION -SkuName $iotHubPackage

#Get iotHub ConnectionString
$iotHubConnectionString = (Get-AzureRmIotHubConnectionString -ResourceGroupName $RESOURCE_GROUP_NAME -Name $iotHubName -KeyName $keyName).PrimaryConnectionString;

#Get iotHub Event hub compatiable endpoint
$iotHubEventHubEndpoint = "eventhubendpoint"

#Create signalR
$signalRKeyArray = "telemetry-data-","notification-data-"
$signalRNameArray = [System.Collections.ArrayList]@()
$signalRPrimaryKey = [System.Collections.ArrayList]@()
For ($i=0; $i -lt $signalRKeyArray.Length; $i++) {
	$signalRNameArray.Add($signalRKeyArray[$i] + $clientId + "-signalr")
	New-AzureRmSignalR -ResourceGroupName $RESOURCE_GROUP_NAME -Name $signalRNameArray[$i] -Location $REGION -Sku $signalRPackage -UnitCount $signalRUnits
	$connectionString = (Get-AzureRmSignalRKey -ResourceGroupName $RESOURCE_GROUP_NAME -Name $signalRNameArray[$i]).PrimaryConnectionString
	$signalRPrimaryKey.Add($connectionString)
}

#Create storage account
$clientKeyPlain = $clientKey -Replace "-"
$storageAccountName = "storageaccount" + $clientId
$blobContainerName = "blob-container-" + $clientId
New-AzureRmStorageAccount -ResourceGroupName $RESOURCE_GROUP_NAME -AccountName $storageAccountName -Location $REGION -SkuName $storageAccountPackage -Kind $storageAccountKind -AccessTier $storageAccountAccessTier
$accountObject = Get-AzureRmStorageAccount -ResourceGroupName $RESOURCE_GROUP_NAME -AccountName $storageAccountName
New-AzureRmStorageContainer -StorageAccount $accountObject -ContainerName $blobContainerName -PublicAccess Blob

#Get storage account ConnectionString
$saKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $RESOURCE_GROUP_NAME -AccountName $storageAccountName)[0].Value
$storageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=' + $storageAccountName + ';AccountKey=' + $saKey + ';EndpointSuffix=core.windows.net'

# Create an Azure Cosmos database
$accountName = "iot-cosmos-db-dev"
$databaseName = "cosmos-db-" + $clientId
$resourceName = $cosmosDbAccountName + "/sql/" + $databaseName

$DataBaseProperties = @{
    "resource"=@{"id"=$databaseName}
} 
New-AzureRmResource -Force:$true -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/databases" `
    -ApiVersion "2015-04-08" -ResourceGroupName $RESOURCE_GROUP_NAME `
    -Name $resourceName -PropertyObject $DataBaseProperties 

#Create cosmos db collections/ containers
$containerNameArray = "telemetry-data-container","notification-data-container"
For ($i=0; $i -lt $containerNameArray.Length; $i++) {
    $container = $containerNameArray[$i]
	$resourceName = $cosmosDbAccountName + "/sql/" + $databaseName + "/" + $container
	$ContainerProperties = @{
    "resource"=@{
        "id"=$container; 
        "partitionKey"=@{
            "paths"=@("/myPartitionKey"); 
            "kind"="Hash"
        }
    }; 
    "options"=@{ "Throughput"= $cosmosDbThroughputs }
	}
	New-AzureRmResource -Force:$true -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/databases/containers" `
    -ApiVersion "2015-04-08" -ResourceGroupName $RESOURCE_GROUP_NAME `
    -Name $resourceName -PropertyObject $ContainerProperties
} 

#End Azure process
#******************************************************************************
#Storing data into sql databases

#Create Connection
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server = $SQL_SERVER; Database = $DB_NAME; User ID = $DB_USERNAME; Password = $DB_PASSWORD;"

#Sql script
$createdDate = Get-Date -Format g
$SqlQuery = "INSERT INTO 
				[iot].[T_Client_ResourceConfiguration] 
				([Config],
				[ClientId],
				[ResourceConfigurationId],
				[IsActive],
				[CreatedBy],
				[CreatedDateTime],
				[UpdatedBy],
				[UpdatedDateTime])
			VALUES 
				('$iotHubName',$clientId,1,1,'system','$createdDate','system','$createdDate'),
				('$iotHubConnectionString',$clientId,2,1,'system','$createdDate','system','$createdDate'),
				('$iotHubEventHubEndpoint',$clientId,5,1,'system','$createdDate','system','$createdDate'),
				('$storageAccountConnectionString',$clientId,6,1,'system','$createdDate','system','$createdDate'),
				('$blobContainerName',$clientId,7,1,'system','$createdDate','system','$createdDate'),
				('$databaseName',$clientId,8,1,'system','$createdDate','system','$createdDate'),
				('$signalRNameArray[0]',$clientId,13,1,'system','$createdDate','system','$createdDate'),
				('$signalRPrimaryKey[0]',$clientId,14,1,'system','$createdDate','system','$createdDate'),
				('$signalRNameArray[1]',$clientId,15,1,'system','$createdDate','system','$createdDate'),
				('$signalRPrimaryKey[1]',$clientId,16,1,'system','$createdDate','system','$createdDate');"

#Write data
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = $SqlQuery
$SqlCmd.Connection = $SqlConnection
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
$SqlConnection.Close();

#******************************************************************************
#End the process
#Exit
#******************************************************************************
