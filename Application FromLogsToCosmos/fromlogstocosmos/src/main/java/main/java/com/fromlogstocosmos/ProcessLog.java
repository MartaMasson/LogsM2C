package  main.java.com.fromlogstocosmos;

import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import com.azure.cosmos.CosmosClient;
import com.azure.cosmos.CosmosClientBuilder;
import com.azure.cosmos.CosmosContainer;
import com.azure.cosmos.models.CosmosItemRequestOptions;
import com.azure.cosmos.models.PartitionKey;
import com.azure.identity.ManagedIdentityCredential;
import com.azure.identity.ManagedIdentityCredentialBuilder;
import com.azure.messaging.servicebus.ServiceBusReceivedMessage;
import com.azure.security.keyvault.secrets.SecretClient;
import com.azure.security.keyvault.secrets.SecretClientBuilder;

public class ProcessLog {
    private static final Pattern LOG_PATTERN = Pattern.compile(
        // The IP address of the client
        "(\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3})\\s+" +
        // The identity of the client (usually -)
        "(\\S+)\\s+" +
        // The username of the client (usually -)
        "(\\S+)\\s+" +
        // The date and time of the request in brackets
        "\\[(.+?)\\]\\s+" +
        // The request line in quotes
        "\"(.+?)\"\\s+" +
        // The status code of the response
        "(\\d{3})\\s+" +
        // The size of the response in bytes
        "(\\d+)\\s+" +
        // The referer URL in quotes
        "\"(.+?)\"\\s+" +
        // The user agent string in quotes
        "\"(.+?)\""
    );

    private CosmosContainer cosmosContainer;
    private String sCosmosEndpoint;
    private String sCosmosDB;
    private String sCosmosContainerName;
    private String sAzureKeyVaultURL;
    private ManagedIdentityCredential credential;

    private ManagedIdentityCredential getCredential() {
        System.out.printf(" ProcessLog.getCredential: " + this.credential.getClientId().toString() + "\n");
        return this.credential;
    }
    private void setCredential(ManagedIdentityCredential credential) {
        System.out.printf(" ProcessLog.setCredential: " + credential.getClientId().toString() + "\n");
        this.credential = credential;
    }
    
    public ProcessLog() {
        this.setCredential(new ManagedIdentityCredentialBuilder().build());

        System.out.printf(" ProcessLog.constructor - Retriveing information from key-vault. \n");

        try {
            Map<String, String> env = System.getenv();

            this.setAzureKeyVaultURL(env.get("AZURE_KEYVAULT_URL"));

            SecretClient secretClient = new SecretClientBuilder()
                .vaultUrl(this.getAzureKeyVaultURL())
                .credential(this.getCredential())
                .buildClient();

            this.setCosmosEndpoint(secretClient.getSecret("AzureCosmosDBEndpoint").getValue());
            this.setCosmosDB(secretClient.getSecret("AzureCosmosDBName").getValue());
            this.setCosmosContainerName(secretClient.getSecret("AzureCosmosDBContainerName").getValue());
            
        } catch (Exception e) {
            System.out.printf("ProcessLog.Constructor - Error getting environment variables %s", e.getMessage());
            throw new RuntimeException(e);
        }

        // Connecting to Cosmos and accessing container
        CosmosClient cosmosClient = new CosmosClientBuilder()
            .credential(this.getCredential())
            .endpoint(this.getCosmosEndpoint())
            .buildClient();
        this.setCosmosContainer(cosmosClient.getDatabase(this.getCosmosDB()).getContainer(this.getCosmosContainerName()));
    }

    private String getAzureKeyVaultURL() {
		return this.sAzureKeyVaultURL;
	}
    private void setAzureKeyVaultURL(String sAzureKeyVaultURL) {
		this.sAzureKeyVaultURL = sAzureKeyVaultURL;
	}

    private CosmosContainer getCosmosContainer() {
		return this.cosmosContainer;
	}
    private void setCosmosContainer(CosmosContainer cosmosContainer) {
		this.cosmosContainer = cosmosContainer;
	}

    private String getCosmosEndpoint() {
		return this.sCosmosEndpoint;
	}
    private void setCosmosEndpoint(String sCosmosEndpoint) {
        this.sCosmosEndpoint = sCosmosEndpoint;
	}

    private String getCosmosDB() {
        return this.sCosmosDB;
	}
    private void setCosmosDB(String sCosmosDB) {
		this.sCosmosDB = sCosmosDB;
	}

    private String getCosmosContainerName() {
		return this.sCosmosContainerName;
	}
    private void setCosmosContainerName(String sCosmosContainerName) {
		this.sCosmosContainerName = sCosmosContainerName;
	}

    boolean processLog(ServiceBusReceivedMessage message)   {
        System.out.printf("   ProcessLog.processLog - Sequence #: %s. Contents: %s%n", message.getSequenceNumber(), message.getBody() + "\n");
        int lastIndex = message.getMessageId().lastIndexOf('-');
        String sFilename = message.getMessageId().substring(0, lastIndex);
        System.out.println("   ProcessLog.processLog - sFilename: " + sFilename + "\n");

        try {
                Matcher matcher = LOG_PATTERN.matcher(message.getBody().toString());

                // If the line matches, extract the information
                if (matcher.matches()) {
                    // client IP
                    String sClientIP = matcher.group(1);

                    // client Identity
                    String sClientId = matcher.group(2);

                    // client name
                    String sClientName = matcher.group(3);

                    // The date and time of the log entry
                    String sLogDateTime = matcher.group(4);
					sLogDateTime = sLogDateTime.substring(0, 20); // Removing GMT part

					// The request
                    String sRequeString = matcher.group(5);

                    // The response status code
                    String sResponseStatusCode = matcher.group(6);

                    // The response size
                    String sResponseSize = matcher.group(7);

                    // The URL
                    String sUrl = matcher.group(8);

                    // The user Agent
                    String sUserAgent = matcher.group(9);

                    // Print the extracted information to the console
                    System.out.println("   ProcessLog.processLog - Line macther is ok: \n");
                    System.out.println("   ProcessLog.processLog - Client IP: " + sClientIP + "\n");
                    System.out.println("   ProcessLog.processLog - Client Id: " + sClientId + "\n");
                    System.out.println("   ProcessLog.processLog - Client Name: " + sClientName + "\n");
                    System.out.println("   ProcessLog.processLog - Date & Time: " + sLogDateTime + "\n");
                    System.out.println("   ProcessLog.processLog - Request: " + sRequeString + "\n");
                    System.out.println("   ProcessLog.processLog - Response Status: " + sResponseStatusCode + "\n");
                    System.out.println("   ProcessLog.processLog - Response size: " + sResponseSize + "\n");
                    System.out.println("   ProcessLog.processLog - URL: " + sUrl + "\n");
                    System.out.println("   ProcessLog.processLog - User Agent: " + sUserAgent + "\n");

					LogItem logItem = new LogItem();
                    logItem.setId();
                    logItem.setLogFile(sFilename);
                    logItem.setClientIP(sClientIP);
					logItem.setClientId(sClientId);
					logItem.setClientName(sClientName);
					logItem.setLogDate(MyUtilities.extractDate(sLogDateTime)); // Extratir apenas a data - String
                    logItem.setPartitionKey(MyUtilities.convertDateToStr(MyUtilities.convertStrToDate(sLogDateTime)));
					logItem.setLogTime(MyUtilities.extractTime(sLogDateTime)); // Extrair apenas a hora - String
					logItem.setRequeString(sRequeString);
					logItem.setResponseStatusCode(sResponseStatusCode);
					logItem.setResponseSize(sResponseSize);
					logItem.setUrl(sUrl);
					logItem.setUserAgent(sUserAgent);
					this.writelog(logItem);
                    return true;
                } else {
                    // If the line does not match, print a warning
                    System.out.println("   ProcessLog.processLog - Invalid log format:" + "\n");
                    return false;
                }
        } catch (Exception e) {
			// Log an error message
			System.out.println("   ProcessLog.processLog - An error occurred: " + e.getMessage() + " " + e.getStackTrace().toString() + "\n");
            return false;
        }
    }
    
    private void writelog(LogItem logItem)  throws InterruptedException{
	    // Write the log item to Cosmos DB
		try {
            System.out.println("    ProcessLog.writelog - Writing log in cosmos: " + logItem.getPartitionKey() + "\n");
			System.out.println("  ProcessLog.writelog - Log item written to Cosmos DB: {}\n");
            System.out.println("    ProcessLog.writelog - id: " + logItem.getId() + "\n");
            System.out.println("    ProcessLog.writelog - Log file name: " + logItem.getLogFile() + "\n");
            System.out.println("    ProcessLog.writelog - Client IP: " + logItem.getClientIP() + "\n");
            System.out.println("    ProcessLog.writelog - Client Id: " + logItem.getClientId() + "\n");
            System.out.println("    ProcessLog.writelog - Client Name: " + logItem.getClientName() + "\n");
            System.out.println("    ProcessLog.writelog - Date: " + logItem.getLogDate().toString() + "\n");
            System.out.println("    ProcessLog.writelog - Time: " + logItem.getLogTime() + "\n");
            System.out.println("    ProcessLog.writelog - Request: " + logItem.getRequeString() + "\n");
            System.out.println("    ProcessLog.writelog - Response Status: " + logItem.getResponseStatusCode() + "\n");
            System.out.println("    ProcessLog.writelog - Response size: " + logItem.getResponseSize() + "\n");
            System.out.println("    ProcessLog.writelog - URL: " + logItem.getUrl() + "\n");
            System.out.println("    ProcessLog.writelog - User Agent: " + logItem.getUserAgent() + "\n");

            this.getCosmosContainer().createItem(logItem, new PartitionKey(logItem.getPartitionKey()), new CosmosItemRequestOptions());

            //CosmosItemResponse item = this.getCosmosContainer().createItem(logItem, new PartitionKey(logItem.getPartitionKey()), new CosmosItemRequestOptions());
            //Get request charge and other properties like latency, and diagnostics strings, etc.
            //System.out.println(String.format("Created item with request charge of %.2f within" +
            //        " duration %s",
            //    item.getRequestCharge(), item.getDuration()));

		} catch (Exception e) {
			// Log an error message
			System.out.println("Failed to write log item to Cosmos DB: {} " + e.getMessage() + " " + e.getStackTrace().toString() + "\n");
            throw e;
		}
	}
}