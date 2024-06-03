package  main.java.com.fromlogstocosmos;


import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import com.azure.cosmos.CosmosClient;
import com.azure.cosmos.CosmosClientBuilder;
import com.azure.cosmos.CosmosContainer;
import com.azure.cosmos.models.CosmosItemRequestOptions;
//import com.azure.cosmos.models.CosmosItemResponse;
import com.azure.cosmos.models.PartitionKey;
import com.azure.identity.ManagedIdentityCredential;
import com.azure.identity.ManagedIdentityCredentialBuilder;
import com.azure.messaging.servicebus.ServiceBusClientBuilder;
import com.azure.messaging.servicebus.ServiceBusReceivedMessage;
import com.azure.messaging.servicebus.ServiceBusReceiverAsyncClient;
import com.azure.security.keyvault.secrets.SecretClient;
import com.azure.security.keyvault.secrets.SecretClientBuilder;

import reactor.core.Disposable;

public class ReadQueueLogsOld {

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

    private String sAzureKeyVaultURL;
    private CosmosContainer cosmosContainer;
    private String sCosmosEndpoint;
    private String sCosmosDB;
    private String sCosmosContainerName;
    private String sServiceBusConnectionStringReceiver;
    private String sServiceBusQueueNameReceiver;
    private ManagedIdentityCredential credential;

    public ReadQueueLogsOld() {
        this.setCredential(new ManagedIdentityCredentialBuilder().build());

        Map<String, String> env = System.getenv();

        try {
            this.setAzureKeyVaultURL(env.get("AZURE_KEYVAULT_URL"));

            SecretClient secretClient = new SecretClientBuilder()
                .vaultUrl(this.getAzureKeyVaultURL())
                .credential(this.getCredential())
                .buildClient();

            this.setCosmosEndpoint(secretClient.getSecret(env.get("SECRET_AZURE_COSMOS_DB_ENDPOINT")).getValue());
            this.setCosmosDB(env.get("AZURE_COSMOS_DB_NAME"));
            this.setCosmosContainerName(env.get("AZURE_COSMOS_DB_CONTAINER_NAME"));
            this.setServiceBusConnectionStringReceiver(secretClient.getSecret(env.get("SECRET_AZURE_SB_CONN_STR_RECEIVER")).getValue());
            this.setServiceBusQueueNameReceiver(env.get("AZURE_SB_QUEUE_RECEIVER"));
            
        } catch (Exception e) {
            System.out.printf("Error getting environment variables %s", e.getMessage());
            throw new RuntimeException(e);
        }

        // Connecting to Cosmos and accessing container
        CosmosClient cosmosClient = new CosmosClientBuilder()
            .credential(this.getCredential())
            .endpoint(this.getCosmosEndpoint())
            .buildClient();
        this.setCosmosContainer(cosmosClient.getDatabase(this.getCosmosDB()).getContainer(this.getCosmosContainerName()));
    }

    private ManagedIdentityCredential getCredential() {
		return this.credential;
	}
    private void setCredential(ManagedIdentityCredential credential) {
		this.credential = credential;
	}

    private CosmosContainer getCosmosContainer() {
		return this.cosmosContainer;
	}
    private void setCosmosContainer(CosmosContainer cosmosContainer) {
		this.cosmosContainer = cosmosContainer;
	}

    private String getAzureKeyVaultURL() {
		return this.sAzureKeyVaultURL;
	}
    private void setAzureKeyVaultURL(String sAzureKeyVaultURL) {
		this.sAzureKeyVaultURL = sAzureKeyVaultURL;
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

    private String getServiceBusConnectionStringReceiver() {
		return this.sServiceBusConnectionStringReceiver;
	}
    private void setServiceBusConnectionStringReceiver(String sServiceBusConnectionStringReceiver) {
		this.sServiceBusConnectionStringReceiver = sServiceBusConnectionStringReceiver;
	}

    private String getServiceBusQueueNameReceiver() {
		return this.sServiceBusQueueNameReceiver;
	}
    private void setServiceBusQueueNameReceiver(String sServiceBusQueueNameReceiver) {
		this.sServiceBusQueueNameReceiver = sServiceBusQueueNameReceiver;
	}

    public void run()  {
        boolean bContinueLoop = true;
        while (bContinueLoop) {
            ServiceBusReceiverAsyncClient receiver = new ServiceBusClientBuilder()
                .credential(this.getCredential())
                .connectionString(this.getServiceBusConnectionStringReceiver())
                .receiver()
                .disableAutoComplete()
                .queueName(this.getServiceBusQueueNameReceiver())
                .buildAsyncClient();

            System.out.println("Starting reading queue...");
            try {
                CountDownLatch countdownLatch = new CountDownLatch(1);
                Disposable subscription = receiver.receiveMessages()
                    .flatMap(message -> {
                        System.out.println("Received Message Id: " + message.getMessageId());
                        System.out.println("Received Message: " + message.getBody().toString());
                        boolean messageProcessed = processMessage(message);
                        if (messageProcessed) {
                            System.out.println("Message processed with sucess.");
                            return receiver.complete(message);
                        } else {
                            System.out.println("Message processed with error. Abandoing message.");
                            return receiver.abandon(message);
                        }
                    }).subscribe(
                        (ignore) -> System.out.println("Message processed.")
                    );

                // Subscribe is not a blocking call so we wait here so the program does not end.
                System.out.println("countdownLatch.await...");
                countdownLatch.await(20, TimeUnit.SECONDS);

                // Disposing of the subscription will cancel the receive() operation.
                subscription.dispose();
            } catch (InterruptedException e) {
                bContinueLoop = false;
                System.out.println("InterruptedException exception occurred. ");
            }
            catch (Exception e) {
                bContinueLoop = false;
                System.out.println("Exception occurred. ");
                // Close the receiver.
            }
            receiver.close();
        }
    }

    private boolean processMessage(ServiceBusReceivedMessage message)   {
        System.out.printf(" Sequence #: " + message.getSequenceNumber() + " " + message.getMessageId() + " " + message.getBody());

        int lastIndex = message.getMessageId().lastIndexOf('-');
        String sFilename = message.getMessageId().substring(0, lastIndex);
        System.out.println("  sFilename: " + sFilename);

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
                    System.out.println("  Line macther is ok:");
                    System.out.println("   Client IP: " + sClientIP);
                    System.out.println("   Client Id: " + sClientId);
                    System.out.println("   Client Name: " + sClientName);
                    System.out.println("   Date & Time: " + sLogDateTime);
                    System.out.println("   Request: " + sRequeString);
                    System.out.println("   Response Status: " + sResponseStatusCode);
                    System.out.println("   Response size: " + sResponseSize);
                    System.out.println("   URL: " + sUrl);
                    System.out.println("   User Agent: " + sUserAgent);

					LogItem logItem = new LogItem();
                    logItem.setId();
                    logItem.setLogFile(sFilename);
                    logItem.setClientIP(sClientIP);
					logItem.setClientId(sClientId);
					logItem.setClientName(sClientName);
					logItem.setLogDate(MyUtilities.convertStrToDate(sLogDateTime)); // Converter apenas a data - Tipo Date
                    logItem.setPartitionKey(MyUtilities.convertDateToStr(logItem.getLogDate()));
					logItem.setLogTime(MyUtilities.extractTime(sLogDateTime)); // Extrair a penas a hora
					logItem.setRequeString(sRequeString);
					logItem.setResponseStatusCode(sResponseStatusCode);
					logItem.setResponseSize(sResponseSize);
					logItem.setUrl(sUrl);
					logItem.setUserAgent(sUserAgent);
					this.writelog(logItem);
                    return true;
                } else {
                    // If the line does not match, print a warning
                    System.out.println("   Invalid log format:");
                    return false;
                }
        } catch (Exception e) {
			// Log an error message
			System.out.println("    An error occurred: " + e.getMessage() + " " + e.getStackTrace().toString());
            return false;
        }
    }
    
    private void writelog(LogItem logItem)  throws InterruptedException{
	    // Write the log item to Cosmos DB
		try {
            System.out.println("   Writing log in cosmos: " + logItem.getPartitionKey());
            this.getCosmosContainer().createItem(logItem, new PartitionKey(logItem.getPartitionKey()), new CosmosItemRequestOptions());

            //CosmosItemResponse item = this.getCosmosContainer().createItem(logItem, new PartitionKey(logItem.getPartitionKey()), new CosmosItemRequestOptions());
            //Get request charge and other properties like latency, and diagnostics strings, etc.
            //System.out.println(String.format("Created item with request charge of %.2f within" +
            //        " duration %s",
            //    item.getRequestCharge(), item.getDuration()));

			System.out.println("   Log item written to Cosmos DB: {}");
            System.out.println("    id: " + logItem.getId());
            System.out.println("    Log file name: " + logItem.getLogFile());
            System.out.println("    Client IP: " + logItem.getClientIP());
            System.out.println("    Client Id: " + logItem.getClientId());
            System.out.println("    Client Name: " + logItem.getClientName());
            System.out.println("    Date: " + logItem.getLogDate().toString());
            System.out.println("    Time: " + logItem.getLogTime());
            System.out.println("    Request: " + logItem.getRequeString());
            System.out.println("    Response Status: " + logItem.getResponseStatusCode());
            System.out.println("    Response size: " + logItem.getResponseSize());
            System.out.println("    URL: " + logItem.getUrl());
            System.out.println("    User Agent: " + logItem.getUserAgent());
		} catch (Exception e) {
			// Log an error message
			System.out.println("Failed to write log item to Cosmos DB: {} " + e.getMessage() + " " + e.getStackTrace().toString());
            throw e;
		}
	}
}