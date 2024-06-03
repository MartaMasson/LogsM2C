package  main.java.com.fromlogstocosmos;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import com.azure.identity.ManagedIdentityCredential;
import com.azure.identity.ManagedIdentityCredentialBuilder;
import com.azure.messaging.servicebus.ServiceBusClientBuilder;
import com.azure.messaging.servicebus.ServiceBusMessage;
import com.azure.messaging.servicebus.ServiceBusReceivedMessage;
import com.azure.messaging.servicebus.ServiceBusReceiverAsyncClient;
import com.azure.messaging.servicebus.ServiceBusSenderClient;
import com.azure.security.keyvault.secrets.SecretClient;
import com.azure.security.keyvault.secrets.SecretClientBuilder;
import com.azure.storage.blob.BlobClient;
import com.azure.storage.blob.BlobContainerClient;
import com.azure.storage.blob.BlobServiceClient;
import com.azure.storage.blob.BlobServiceClientBuilder;
import com.azure.storage.blob.models.BlobStorageException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import reactor.core.Disposable;

public class ReadQueueFilesOld {
    private BlobContainerClient blobContainerClient;
    private String sStorageAccountEndPoint;
    private String sStorageAccountContainer;
    private String sServiceBusEndPointReceiver;
    private String sServiceBusQueueNameReceiver;
    private String sServiceBusConnStringSender;
    private String sServiceBusQueueNameSender;
    private ManagedIdentityCredential credential;
    private String sAzureKeyVaultURL;

    public ReadQueueFilesOld() {
        this.setCredential(new ManagedIdentityCredentialBuilder().build());

        Map<String, String> env = System.getenv();

        try {
            this.setAzureKeyVaultURL(env.get("AZURE_KEYVAULT_URL"));

            SecretClient secretClient = new SecretClientBuilder()
                .vaultUrl(this.getAzureKeyVaultURL())
                .credential(this.getCredential())
                .buildClient();
            
            this.setStorageAccountEndPoint(env.get("AZURE_STORAGE_ACCOUNT_ENDPOINT"));
            this.setStorageAccountContainer(env.get("AZURE_STORAGE_ACCOUNT_CONTAINER"));
            this.setServiceBusEndPointReceiver(env.get("AZURE_SERVICEBUS_RECEIVER_ENDPOINT"));
            this.setServiceBusQueueNameReceiver(env.get("AZURE_SERVICEBUS_RECEIVER_QUEUE"));
            this.setServiceBusConnStringSender(secretClient.getSecret(env.get("AZURE_SERVICEBUS_SENDER_CONN_STRING")).getValue());
            this.setServiceBusQueueNameSender(env.get("AZURE_SERVICEBUS_SENDER_QUEUE"));

        } catch (Exception e) {
            System.out.printf("Error getting environment variables %s", e.getMessage());
            throw new RuntimeException(e);
        }

        //Connecting with blob
        BlobServiceClient blobServiceClient = new BlobServiceClientBuilder()
            .credential(this.getCredential())
            .endpoint(this.getStorageAccountEndPoint())
            .buildClient();
            
        this.setBlobContainerClient(blobServiceClient.getBlobContainerClient(this.getStorageAccountContainer()));
    }
    private ManagedIdentityCredential getCredential() {
		return this.credential;
	}
    private void setCredential(ManagedIdentityCredential credential) {
		this.credential = credential;
	}

    private String getAzureKeyVaultURL() {
		return this.sAzureKeyVaultURL;
	}
    private void setAzureKeyVaultURL(String sAzureKeyVaultURL) {
		this.sAzureKeyVaultURL = sAzureKeyVaultURL;
	}

    private BlobContainerClient getBlobContainerClient() {
		return this.blobContainerClient;
	}
    private void setBlobContainerClient(BlobContainerClient blobContainerClient) {
		this.blobContainerClient = blobContainerClient;
	}

    private String getStorageAccountEndPoint() {
		return this.sStorageAccountEndPoint;
	}
    private void setStorageAccountEndPoint(String sStorageAccountEndPoint) {
		this.sStorageAccountEndPoint = sStorageAccountEndPoint;
	}

    private String getStorageAccountContainer() {
		return this.sStorageAccountContainer;
	}
    private void setStorageAccountContainer(String sStorageAccountContainer) {
		this.sStorageAccountContainer = sStorageAccountContainer;
	}

    private String getServiceBusEndPointReceiver() {
		return this.sServiceBusEndPointReceiver;
	}
    private void setServiceBusEndPointReceiver(String sServiceBusEndPointReceiver) {
		this.sServiceBusEndPointReceiver = sServiceBusEndPointReceiver;
	}

    private String getServiceBusQueueNameReceiver() {
		return this.sServiceBusQueueNameReceiver;
	}
    private void setServiceBusQueueNameReceiver(String sServiceBusQueueNameReceiver) {
		this.sServiceBusQueueNameReceiver = sServiceBusQueueNameReceiver;
	}

    private String getServiceBusConnStringSender() {
		return this.sServiceBusConnStringSender;
	}
    private void setServiceBusConnStringSender(String sServiceBusConnStringSender) {
		this.sServiceBusConnStringSender = sServiceBusConnStringSender;
	}

    private String getServiceBusQueueNameSender() {
		return this.sServiceBusQueueNameSender;
	}
    private void setServiceBusQueueNameSender(String sServiceBusQueueNameSender) {
		this.sServiceBusQueueNameSender = sServiceBusQueueNameSender;
	}

    public void run2()  {
        boolean bContinueLoop = true;
        while (bContinueLoop) {

            ServiceBusReceiverAsyncClient receiver = new ServiceBusClientBuilder()
                .credential(this.getServiceBusEndPointReceiver(), this.getCredential())
                .receiver()
                .queueName(this.getServiceBusQueueNameReceiver())
                .buildAsyncClient();


            System.out.println("Starting reading queue...");
            try {
                CountDownLatch countdownLatch = new CountDownLatch(1);
                Disposable subscription = receiver.receiveMessages()
                    .flatMap(message -> {
                        System.out.println("Received Message Id: " + message.getMessageId());
                        System.out.println("Received Message: " + message.getBody().toString());
                        return receiver.complete(message);
                    }).subscribe(
                        (ignore) -> System.out.println("Message processed.")
                    );

                // Subscribe is not a blocking call so we wait here so the program does not end.
                System.out.println("countdownLatch.await...");
                countdownLatch.await(10, TimeUnit.SECONDS);

                // Disposing of the subscription will cancel the receive() operation.
                subscription.dispose();
            } catch (InterruptedException e) {
                System.out.println("InterruptedException exception occurred. ");
                // Close the receiver.
            }
            catch (Exception e) {
                System.out.println("Exception occurred. ");
                // Close the receiver.
            }
            receiver.close();
        }
    }

    public void run3()  {
        boolean bContinueLoop = true;
        while (bContinueLoop) {
            System.out.println("Run - Connecting to the service bus...");
            ServiceBusReceiverAsyncClient receiver = new ServiceBusClientBuilder()
                .credential(this.getServiceBusEndPointReceiver(), this.getCredential())
                .receiver()
                .queueName(this.getServiceBusQueueNameReceiver())
                .buildAsyncClient();

            System.out.println("Run - Starting reading queue...");
            try {
                CountDownLatch countdownLatch = new CountDownLatch(1);
                Disposable subscription = receiver.receiveMessages()
                    .flatMap(message -> {
                        System.out.println("Run - Received Message Id: " + message.getMessageId());
                        System.out.println("Run - Received Message: " + message.getBody().toString());
                        boolean messageProcessed = processMessage(message);
                        if (messageProcessed) {
                            System.out.println("Run - Message processed with sucess. Received Message Id: " + message.getMessageId());
                            return receiver.complete(message);
                        } else {
                            System.out.println("Run - Message processed with error. Abandoing message.Message Id: " + message.getMessageId());
                            return receiver.abandon(message);
                        }
                    }).subscribe(
                        (ignore) -> System.out.println("Run - Message processed.")
                    );

                // Subscribe is not a blocking call so we wait here so the program does not end.
                System.out.println("Run - countdownLatch.await...");
                countdownLatch.await(20, TimeUnit.SECONDS);

                // Disposing of the subscription will cancel the receive() operation.
                subscription.dispose();
            }
            catch (InterruptedException e) {
                bContinueLoop = false;
                System.out.println("Run - InterruptedException exception occurred. ");
            }
            catch (Exception e) {
                bContinueLoop = false;
                System.out.println("Run - Exception occurred. ");
            }
            // Close the receiver.
            System.out.println("Run - Closing connection with service bus...");
            receiver.close();
        }
    }



    private boolean processMessage(ServiceBusReceivedMessage message)   {
        System.out.printf(" processMessage- Sequence #: %s. Contents: %s%n", message.getSequenceNumber(), message.getBody());
        try {

            ObjectMapper objectMapper = new ObjectMapper();
            JsonNode jsonNode = objectMapper.readTree(message.getBody().toString());

            System.out.println("  processMessage - source: " + jsonNode.get("source").asText());
            System.out.println("  processMessage - specversion: " + jsonNode.get("specversion").asText());
            System.out.println("  processMessage - type: " + jsonNode.get("type").asText());
            System.out.println("  processMessage - subject: " + jsonNode.get("subject").asText());
            System.out.println("  processMessage - time: " + jsonNode.get("time").asText());

            System.out.println("  processMessage - api: " + jsonNode.get("data").get("api").asText());
            System.out.println("  processMessage - clientRequestId: " + jsonNode.get("data").get("clientRequestId").asText());
            System.out.println("  processMessage - requestId: " + jsonNode.get("data").get("requestId").asText());
            System.out.println("  processMessage - eTag: " + jsonNode.get("data").get("eTag").asText());
            System.out.println("  processMessage - contentType: " + jsonNode.get("data").get("contentType").asText());
            System.out.println("  processMessage - contentLength: " + jsonNode.get("data").get("contentLength").asText());
            System.out.println("  processMessage - blobType: " + jsonNode.get("data").get("blobType").asText());
            System.out.println("  processMessage - url: " + jsonNode.get("data").get("url").asText());
            System.out.println("  processMessage - sequencer: " + jsonNode.get("data").get("sequencer").asText());

            int lastIndex = jsonNode.get("data").get("url").asText().lastIndexOf('/');
            String sBlobName = jsonNode.get("data").get("url").asText().substring(lastIndex + 1);
            System.out.println("  processMessage - blobName: " + sBlobName);

            BlobClient blobclient = this.getBlobContainerClient().getBlobClient(sBlobName);
            InputStream inputStream = blobclient.openInputStream();

            try {
                this.sendLogs(sBlobName, inputStream);
                System.out.println("  processMessage - File processed: " + sBlobName);

            } catch (BlobStorageException e) {
                System.out.println("  processMessage - blobName: " + sBlobName + " não encontrado");
            }
            return true;

        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    private void sendLogs(String sBlobName, InputStream inputStream) throws Exception {
            try {
               // Create a BufferedReader to read the file line by line
                BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));

                // A string to store the current line
                String sLine;

                //List of messages to be sent to the queue
                List<ServiceBusMessage> aMessages = Arrays.asList();
                List<ServiceBusMessage> lMessages = new ArrayList<>(aMessages);
                int i = 0;
                
                // Loop until the end of the file
                while ((sLine = reader.readLine()) != null) {
                        System.out.println(">>>sendLogs - Line :" + sBlobName + "-" + sLine);
                        lMessages.add(new ServiceBusMessage(sLine).setMessageId(sBlobName + "-" + String.format("%06d", ++i)));
                        System.out.println(">>>sendLogs - Mensagem enviada. Line :" + sBlobName + "-" + sLine);
                }
                System.out.println(">>>sendLogs - Closing reader. File: " + sBlobName);
                reader.close();
                System.out.println(">>>sendLogs - Connecting to the queue...");

                ServiceBusSenderClient sender = new ServiceBusClientBuilder()
                    .connectionString(this.getServiceBusConnStringSender())
                    .credential(this.getCredential())
                    .sender()
                    .queueName(this.getServiceBusQueueNameSender())
                    .buildClient();

                System.out.println(">>>sendLogs - Sending messages from file: "+ sBlobName);
                sender.sendMessages(lMessages);
                // When you are done using the sender, dispose of it.
                System.out.println(">>>sendLogs - Closing queue connection.");
                sender.close();
        } catch (Exception e) {
			// Log an error message
			System.out.println("    sendLogs - An error occurred: " + e.getMessage() + " " + e.getStackTrace().toString());
            throw e;
        }
    }
}