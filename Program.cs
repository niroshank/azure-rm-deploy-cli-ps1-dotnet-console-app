using System;
using System.Diagnostics;
using System.IO;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Security;

namespace ConsoleApp1
{
    class Program
    {
        private readonly string CLOUD_PASSWORD = "[subscription-email-password]";
        private readonly string CLOUD_USERNAME = "[subscription-email]";
        private readonly string RESOURCE_GROUP_NAME = "[resource-group]";
        private readonly string REGION = "[your-region]";
        private readonly string SQL_SERVER = "[your-sql-server]";
        private readonly string DB_NAME = "[db-name]";
        private readonly string DB_USERNAME = "[db-username]";
        private readonly string DB_PASSWORD = "[db-password]";
        static void Main(string[] args)
        {
            
                Program program = new Program();
            program.OpenWithArguments();

        }
        void OpenWithArguments()
        {
            //unique clientkey
            string clientKey = "[client-name]";

            // iotHub settings for resource provisioning
            string iotHubPackage = "S1";
            int iotHubUnits = 1;

            //signalR settings for resource provisioning
            string signalRPackage = "Standard_S1";
            int signalRUnits = 1;

            //storage account settings for resource provisioning
            string storageAccountPackage = "Standard_GRS";
            string storageAccountKind = "StorageV2";
            string storageAccountAccessTier = "Hot";

            //cosmos db settings for resource provisioning
            string cosmosDbThroughputs = "400";
            string cosmosDbAccountName = "iot-cosmos-db-dev";

            string scriptfile = @"C:\Users\niroshanku\source\repos\ConsoleApp1\ConsoleApp1\CreateIotHub.ps1";
            var strCmdText = @"" + scriptfile + " '"
                    + SQL_SERVER + "'" + " '"
                    + DB_USERNAME + "'" + " '"
                    + DB_PASSWORD + "'" + " '"
                    + DB_NAME + "'" + " '"
                    + CLOUD_USERNAME + "'" + " '"
                    + CLOUD_PASSWORD + "'" + " '"
                    + RESOURCE_GROUP_NAME + "'" + " '"
                    + REGION + "'" + " '"
                    + clientKey + "'" + " '"
                    + 39 + "'" + " '"
                    + iotHubPackage + "'" + " '"
                    + iotHubUnits + "'" + " '"
                    + signalRPackage + "'" + " '"
                    + signalRUnits + "'" + " '"
                    + storageAccountPackage + "'" + " '"
                    + storageAccountKind + "'" + " '"
                    + storageAccountAccessTier + "'" + " '"
                    + cosmosDbThroughputs + "'" + " '"
                    + cosmosDbAccountName + "'";
            //Process.Start("Powershell.exe", strCmdText);
            //var process = new Process();
            //process.StartInfo.WindowStyle = ProcessWindowStyle.Minimized;
            //process.StartInfo.FileName = "powershell.exe";
            //process.StartInfo.Arguments = strCmdText;
            //process.Start();
            //process.WaitForExit();
            Process.Start("Powershell.exe", strCmdText);
            //ProcessStartInfo startInfo = new ProcessStartInfo();
            //startInfo.FileName = "powershell.exe";
            //startInfo.Arguments = strCmdText;
            //startInfo.RedirectStandardOutput = true;
            //startInfo.RedirectStandardError = true;
            //startInfo.UseShellExecute = false;
            //startInfo.CreateNoWindow = true;

            //Process processTemp = new Process();
            //processTemp.StartInfo = startInfo;
            //processTemp.EnableRaisingEvents = true;
            //try
            //{
            //    processTemp.Start();
            //}
            //catch (Exception e)
            //{
            //    throw;
            //}
        }

        void CreateCosmosDb()
        {
            //string databaseId = "TodoDatabase";
            //string containerId = "TodoContainer";
            //string partitionKey = "/partitionKey";
            
            //using (CosmosClient cosmosClient = new CosmosClient("endpoint", "primaryKey"))
            //{
            //    CosmosDatabase database = await cosmosClient.Databases.CreateDatabaseIfNotExistsAsync(databaseId);
            //    CosmosContainer container = await database.Containers.CreateContainerIfNotExistsAsync(containerId, partitionKey);
            //}
        }
    }
}
