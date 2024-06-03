package  main.java.com.fromfilestologs;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.Map;

import com.azure.identity.ManagedIdentityCredential;
import com.azure.identity.ManagedIdentityCredentialBuilder;
import com.azure.messaging.servicebus.ServiceBusMessage;
import com.azure.messaging.servicebus.ServiceBusReceivedMessage;
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

public class ProcessFile {

    private String sAzureKeyVaultURL;
    private BlobContainerClient blobContainerClient;
    private String sStorageAccountEndPoint;
    private String sStorageAccountContainer;
    private ManagedIdentityCredential credential;

    private ManagedIdentityCredential getCredential() {
        System.out.printf(" ProcessFile.getCredential: " + this.credential.getClientId().toString() + "\n");
        return this.credential;
    }
    private void setCredential(ManagedIdentityCredential credential) {
        System.out.printf(" ProcessFile.setCredential: " + credential.getClientId().toString() + "\n");
        this.credential = credential;
    }

    public ProcessFile() {
        System.out.printf(" ProcessFile.constructor - Retriveing information from key-vault. \n");

        this.setCredential(new ManagedIdentityCredentialBuilder().build());

        try {
            Map<String, String> env = System.getenv();

            this.setAzureKeyVaultURL(env.get("AZURE_KEYVAULT_URL"));

            SecretClient secretClient = new SecretClientBuilder()
                .vaultUrl(this.getAzureKeyVaultURL())
                .credential(this.getCredential())
                .buildClient();

            this.setStorageAccountEndPoint(secretClient.getSecret("AzureStorageAccountEndpoint").getValue());
            this.setStorageAccountContainer(secretClient.getSecret("AzureStorageAccountContainerName").getValue());
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

    public boolean getLogsFromFiles(ServiceBusReceivedMessage message)   {
        System.out.printf("   ProcessFile.getLogsFiles - Sequence #: %s. Contents: %s%n", message.getSequenceNumber(), message.getBody());
        try {

            ObjectMapper objectMapper = new ObjectMapper();
            JsonNode jsonNode = objectMapper.readTree(message.getBody().toString());

            System.out.println("   ProcessFile.getLogsFiles - source: " + jsonNode.get("source").asText());
            System.out.println("   ProcessFile.getLogsFiles - specversion: " + jsonNode.get("specversion").asText());
            System.out.println("   ProcessFile.getLogsFiles - type: " + jsonNode.get("type").asText());
            System.out.println("   ProcessFile.getLogsFiles - subject: " + jsonNode.get("subject").asText());
            System.out.println("   ProcessFile.getLogsFiles - time: " + jsonNode.get("time").asText());

            System.out.println("   ProcessFile.getLogsFiles - api: " + jsonNode.get("data").get("api").asText());
            System.out.println("   ProcessFile.getLogsFiles - clientRequestId: " + jsonNode.get("data").get("clientRequestId").asText());
            System.out.println("   ProcessFile.getLogsFiles - requestId: " + jsonNode.get("data").get("requestId").asText());
            System.out.println("   ProcessFile.getLogsFiles - eTag: " + jsonNode.get("data").get("eTag").asText());
            System.out.println("   ProcessFile.getLogsFiles - contentType: " + jsonNode.get("data").get("contentType").asText());
            System.out.println("   ProcessFile.getLogsFiles - contentLength: " + jsonNode.get("data").get("contentLength").asText());
            System.out.println("   ProcessFile.getLogsFiles - blobType: " + jsonNode.get("data").get("blobType").asText());
            System.out.println("   ProcessFile.getLogsFiles - url: " + jsonNode.get("data").get("url").asText());
            System.out.println("   ProcessFile.getLogsFiles - sequencer: " + jsonNode.get("data").get("sequencer").asText());

            int lastIndex = jsonNode.get("data").get("url").asText().lastIndexOf('/');
            String sBlobName = jsonNode.get("data").get("url").asText().substring(lastIndex + 1);
            System.out.println("   ProcessFile.getLogsFiles - blobName: " + sBlobName);

            BlobClient blobclient = this.getBlobContainerClient().getBlobClient(sBlobName);
            InputStream inputStream = blobclient.openInputStream();

            try {
                this.sendLogs(sBlobName, inputStream);
                System.out.println("   ProcessFile.getLogsFiles - File processed: " + sBlobName);

            } catch (BlobStorageException e) {
                System.out.println("   ProcessFile.getLogsFiles - blobName: " + sBlobName + " não encontrado");
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

            //Connecting to que queue to send message
            LogsSenderToServiceBus logsSenderToServiceBus = new LogsSenderToServiceBus();
            ServiceBusSenderClient senderClient = logsSenderToServiceBus.serviceBusSenderClient(logsSenderToServiceBus.serviceBusClientSenderBuilder());

            // A string to store the current line
            String sLine;
            int i = 0;
            // Loop until the end of the file
            while ((sLine = reader.readLine()) != null) {
                    System.out.println("    FilesReceiverFromServiceBus.sendLogs - Line :" + sBlobName + "-" + sLine + "\n");
                    senderClient.sendMessage(new ServiceBusMessage(sLine).setMessageId(sBlobName + "-" + String.format("%06d", ++i)));
                    System.out.println("    FilesReceiverFromServiceBus.sendLogs - Mensagem enviada. Line :" + sBlobName + "-" + sLine + "\n");
            }
            System.out.println("    FilesReceiverFromServiceBus.sendLogs - Closing reader. File: " + sBlobName + "\n");
            reader.close();
            System.out.println("    FilesReceiverFromServiceBus.sendLogs - Connecting to the queue...\n");
            senderClient.close();
        } catch (Exception e) {
            // Log an error message
            System.out.println("    FilesReceiverFromServiceBus.sendLogs - An error occurred: " + e.getMessage() + " " + e.getStackTrace().toString() + "\n");
            throw e;
        }
    }
}